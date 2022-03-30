import { createRecord, deleteRecord, getRecord } from 'lightning/uiRecordApi';
import { api, LightningElement, wire } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJ from '@salesforce/schema/Account';
import IMPLICIT_FILTER_OBJ from '@salesforce/schema/Implicit_Filter_vod__c';
import LOCATION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Location_vod__c';
import APPLIES_TO_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Applies_To_vod__c';
import INCLUSION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Inclusion_vod__c';
import CONDITION_OBJ from '@salesforce/schema/Implicit_Filter_Condition_vod__c';
import OBJECT_NAME_FIELD from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Object_Name_vod__c';
import FIELD_NAME_FIELD from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Field_Name_vod__c';
import CRITERIA_FIELD from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Criteria_vod__c';
import IMPLICIT_FILTER_REL from '@salesforce/schema/Implicit_Filter_Condition_vod__c.Implicit_Filter_vod__c';
import getLocationsWithAppliesToValues from '@salesforce/apex/VeevaGlobalAccountSearchController.getLocationsWithAppliesToValues';
import getImplicitFilterConditions from '@salesforce/apex/VeevaGlobalAccountSearchController.getImplicitFilterConditions';
import { getPageController } from 'c/veevaPageControllerFactory';
import VeevaToastEvent from "c/veevaToastEvent";

const IMPLICIT_FILTER_FIELDS = [LOCATION_FIELD, APPLIES_TO_FIELD, INCLUSION_FIELD];

export default class GasImplicitFilterDetail extends LightningElement {
    @api action = 'new';
    @api filterId;
    existingFilterConditions = [];

    locationOptions = [];
    appliesToOptions = [];
    recordTypeOptions = [];
    implicitFilterMasterRecordTypeId;

    selectedLocation = null;
    selectedAppliesTo = null;
    selectedInclusion = true;
    selectedRecordTypes = [];

    gasImplicitFiltersLabel = 'Implicit Filters';
    saveButtonLabel = 'Save';
    cancelButtonLabel = 'Cancel';
    recordTypeLabel = 'Record Type';
    detailsSectionLabel = 'Details';
    filtersSectionLabel = 'Filters';
    locationFieldLabel = 'Location';
    appliesToFieldLabel = 'Applies To';
    inclusionFieldLabel = 'Inclusion';

    @wire(getObjectInfos, { objectApiNames: [ACCOUNT_OBJ, IMPLICIT_FILTER_OBJ] })
    wireObjectInfos({ error, data: objectInfos }) {
        if (error) {
            console.error(error);
        } else if (objectInfos) {
            const accountObjectInfo = objectInfos.results[0].result;
            const implicitFilterObjectInfo = objectInfos.results[1].result;
            this.recordTypeOptions = Object.values(accountObjectInfo.recordTypeInfos)
                .filter(recordType => !recordType.master)
                .map(recordType => ({
                    label: recordType.name,
                    value: recordType.recordTypeId
                }))
                .sort((first, second) => first.label.localeCompare(second.label));
            this.gasImplicitFiltersLabel = implicitFilterObjectInfo.labelPlural;
            this.locationFieldLabel = implicitFilterObjectInfo.fields[LOCATION_FIELD.fieldApiName].label;
            this.appliesToFieldLabel = implicitFilterObjectInfo.fields[APPLIES_TO_FIELD.fieldApiName].label;
            this.inclusionFieldLabel = implicitFilterObjectInfo.fields[INCLUSION_FIELD.fieldApiName].label;
        }
    }

    @wire(getLocationsWithAppliesToValues)
    wireLocationsWithAppliesToValues({ error, data }) {
        if (error) {
            console.error(error);
        } else if (data) {
            this.locationOptions = data;
        }
    }

    @wire(getRecord, { recordId: '$filterId', fields: IMPLICIT_FILTER_FIELDS })
    async wireExistingImplicitFilterInfo({ error, data }) {
        if (error) {
            console.error(error);
        } else if (data) {
            this.selectedLocation = data.fields[LOCATION_FIELD.fieldApiName].value;
            this.selectedAppliesTo = data.fields[APPLIES_TO_FIELD.fieldApiName].value;
            this.selectedInclusion = data.fields[INCLUSION_FIELD.fieldApiName].value;
            this.appliesToOptions = this.currentLocation.appliesTo;
            await this.populateExistingFilterConditions();
        }
    }

    async populateExistingFilterConditions() {
        this.existingFilterConditions = await getImplicitFilterConditions({ implicitFilterId: this.filterId });
        const implicitFiltersForAccountRecordType = this.existingFilterConditions
            .filter(condition => condition[OBJECT_NAME_FIELD.fieldApiName] === 'Account')
            .filter(condition => condition[FIELD_NAME_FIELD.fieldApiName] === 'RecordTypeId')
            .map(condition => condition[CRITERIA_FIELD.fieldApiName])
        this.selectedRecordTypes = implicitFiltersForAccountRecordType;
    }

    get isEditMode() {
        return this.action === 'edit';
    }

    get cannotModifyAppliesTo() {
        return this.action === 'edit' || this.appliesToOptions.length === 0;
    }

    get currentLocation() {
        return this.selectedLocation ? this.locationOptions.find(location => location.value === this.selectedLocation) : null;
    }

    async connectedCallback() {
        const veevaMessageSvc = getPageController('messageSvc');
        const [
            saveButtonLabel,
            cancelButtonLabel,
            recordTypeLabel,
            detailsSectionLabel,
            filtersSectionLabel
        ] = await Promise.all([
            veevaMessageSvc.getMessageWithDefault('SAVE', 'Common', this.saveButtonLabel),
            veevaMessageSvc.getMessageWithDefault('CANCEL', 'Common', this.cancelButtonLabel),
            veevaMessageSvc.getMessageWithDefault('RECORD_TYPE_LABEL', 'Common', this.recordTypeLabel),
            veevaMessageSvc.getMessageWithDefault('GAS_IMPLICIT_FILTERS_DETAILS', 'Global Account Search', this.detailsSectionLabel),
            veevaMessageSvc.getMessageWithDefault('GAS_FILTERS', 'Global Account Search', this.filtersSectionLabel)
        ]);
        this.saveButtonLabel = saveButtonLabel;
        this.cancelButtonLabel = cancelButtonLabel;
        this.recordTypeLabel = recordTypeLabel;
        this.detailsSectionLabel = detailsSectionLabel;
        this.filtersSectionLabel = filtersSectionLabel;
    }

    hideImplicitFilterDetail() {
        const doneEvent = new CustomEvent('done');
        this.dispatchEvent(doneEvent);
    }

    async saveImplicitFilter() {
        if (this.changesMade()) {
            const saved = await this.saveChanges();
            if (saved) {
                const doneEvent = new CustomEvent('done');
                this.dispatchEvent(doneEvent);
            }
        }
    }

    async saveChanges() {
        let couldNotCreateFilter = false;
        const implicitFilterRecord = this.createImplicitFilterRecord();

        if (this.filterId && this.action === 'edit') {
            await this.updateImplicitFilterAndConditions(implicitFilterRecord);
        } else {
            couldNotCreateFilter = await this.createImplicitFilterAndConditions(implicitFilterRecord);
        }

        return !couldNotCreateFilter;
    }

    async updateImplicitFilterAndConditions(implicitFilterRecord) {
        implicitFilterRecord.fields.Id = this.filterId;
        // We should not have the api name when updating records
        delete implicitFilterRecord.apiName;
        const recordTypeIdConditionsToCreate = this.selectedRecordTypes.filter(recordType =>
            !this.existingFilterConditions.some(existingCondition => recordType === existingCondition[CRITERIA_FIELD.fieldApiName])
        );
        const recordTypeIdConditionsToDelete = this.existingFilterConditions.filter(existingCondition =>
            !this.selectedRecordTypes.some(recordType => recordType === existingCondition[CRITERIA_FIELD.fieldApiName])
        );
        await this.createRecordTypeIdConditions(recordTypeIdConditionsToCreate, this.filterId);
        await this.deleteRecords(recordTypeIdConditionsToDelete)
    }

    async createImplicitFilterAndConditions(implicitFilterRecord) {
        let couldNotCreateFilter = false;
        try {
            const createdImplicitFilterResult = await createRecord(implicitFilterRecord);
            await this.createRecordTypeIdConditions(this.selectedRecordTypes, createdImplicitFilterResult.id);
        } catch (e) {
            if (e?.body?.statusCode === 400 && e?.body?.output?.errors?.length > 0) {
                const errorMessage = e.body.output.errors[0].message;
                this.dispatchEvent(VeevaToastEvent.error({ message: errorMessage }));
            }
            couldNotCreateFilter = true;
        }
        return couldNotCreateFilter;
    }

    createImplicitFilterRecord() {
        const record = {
            apiName: IMPLICIT_FILTER_OBJ.objectApiName,
            fields: {
                [LOCATION_FIELD.fieldApiName]: this.selectedLocation,
                [INCLUSION_FIELD.fieldApiName]: this.selectedInclusion,
                [APPLIES_TO_FIELD.fieldApiName]: this.selectedAppliesTo
            }
        }
        return record;
    }

    async createRecordTypeIdConditions(recordTypes, filterId) {
        return Promise.all(
            recordTypes.map(selectedRecordType => createRecord({
                apiName: CONDITION_OBJ.objectApiName,
                fields: {
                    [OBJECT_NAME_FIELD.fieldApiName]: 'Account',
                    [FIELD_NAME_FIELD.fieldApiName]: 'RecordTypeId',
                    [CRITERIA_FIELD.fieldApiName]: selectedRecordType,
                    [IMPLICIT_FILTER_REL.fieldApiName]: filterId
                }
            }))
        );
    }

    async deleteRecords(records) {
        return Promise.all(records.map(record => deleteRecord(record.Id)))
    }

    changesMade() {
        let changesMade = this.currentLocation !== null && (!this.currentLocation.requiresAppliesToValue || this.selectedAppliesTo !== null);
        if (this.action === 'edit') {
            return changesMade && this.selectedRecordTypes;
        }
        return changesMade;
    }

    updateSelectedLocation(event) {
        this.selectedLocation = event.detail.value;
        this.appliesToOptions = this.currentLocation.appliesTo;
        this.selectedAppliesTo = null;
    }

    updateSelectedAppliesTo(event) {
        this.selectedAppliesTo = event.detail.value;
    }

    updateSelectedInclusion(event) {
        this.selectedInclusion = event.detail.checked;
    }

    updateRecordTypesSelected(event) {
        this.selectedRecordTypes = event.detail.value;
    }

    handleClose() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}