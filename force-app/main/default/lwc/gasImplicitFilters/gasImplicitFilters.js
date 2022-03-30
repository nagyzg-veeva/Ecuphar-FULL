import { LightningElement, wire } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getImplicitFilters from '@salesforce/apex/VeevaGlobalAccountSearchController.getImplicitFilters';
import getLocationsWithAppliesToValues from '@salesforce/apex/VeevaGlobalAccountSearchController.getLocationsWithAppliesToValues';
import IMPLICIT_FILTER_OBJ from '@salesforce/schema/Implicit_Filter_vod__c';
import LOCATION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Location_vod__c';
import APPLIES_TO_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Applies_To_vod__c';
import INCLUSION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Inclusion_vod__c';
import { getPageController } from 'c/veevaPageControllerFactory';
import VeevaToastEvent from 'c/veevaToastEvent';

const LOCATION_FIELD_LOWER = LOCATION_FIELD.fieldApiName.toLowerCase();
const APPLIES_TO_FIELD_LOWER = APPLIES_TO_FIELD.fieldApiName.toLowerCase();
const INCLUSION_FIELD_LOWER = INCLUSION_FIELD.fieldApiName.toLowerCase();

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

export default class GasImplicitFilters extends LightningElement {

    // Implicit Filter Details properties
    showImplicitFilterDetail = false;
    implicitFilterDetailAction;
    implicitFilterId;

    // Implicit Filters properties
    tableMetadataReady = false;
    loadingImplicitFilters = true;
    implicitFilterKey = 'id'
    implicitFilters = [];
    implicitFiltersColumns = [
        { label: 'Location', fieldName: LOCATION_FIELD_LOWER },
        { label: 'Applies To', fieldName: APPLIES_TO_FIELD_LOWER },
        { label: 'Inclusion', fieldName: INCLUSION_FIELD_LOWER, type: 'boolean' },
        { type: 'action', typeAttributes: { rowActions: actions } }
    ];
    locationsWithAppliesToValues = [];
    appliesToValues = [];

    // Labels from Veeva Messages
    gasImplicitFiltersLabel = "Implicit Filters";
    newButtonLabel = 'New';
    errorLabel = 'Looks like something went wrong. Please log a ticket with Veeva Support.';


    @wire(getObjectInfo, { objectApiName: IMPLICIT_FILTER_OBJ.objectApiName })
    wireObjectInfo({ error, data: objectInfo }) {
        if (error) {
            this.setError(error);
        } else if (objectInfo) {
            this.gasImplicitFiltersLabel = objectInfo.labelPlural;
            const lowerCaseFieldNameMap = this.getLowerCaseFieldMap(objectInfo);

            this.implicitFiltersColumns
                .filter(column => column.fieldName && lowerCaseFieldNameMap.has(column.fieldName))
                .forEach(column => {
                    column.label = lowerCaseFieldNameMap.get(column.fieldName).label;
                });
            this.tableMetadataReady = true;
        }
    }

    getLowerCaseFieldMap(objectInfo) {
        const lowerCaseFieldMap = new Map();
        Object.entries(objectInfo.fields).forEach(([fieldName, field]) => {
            lowerCaseFieldMap.set(fieldName.toLowerCase(), field);
        })
        return lowerCaseFieldMap;

    }

    async connectedCallback() {
        try {
            const veevaMessageSvc = getPageController('messageSvc');
            // Separate the Promises calls because we need the System Error in case there is an error while
            // loading implicit filters and locations with applies to values.
            [this.newButtonLabel, this.errorLabel] = await Promise.all([
                veevaMessageSvc.getMessageWithDefault('NEW', 'Common', this.newButtonLabel),
                veevaMessageSvc.getMessageWithDefault('ERROR_VEEVA_SUPPORT_TICKET', 'Common', this.errorLabel)
            ]);
            const [locationsWithAppliesToValues, implicitFilters] = await Promise.all([
                getLocationsWithAppliesToValues(),
                getImplicitFilters()
            ]);
            this.locationsWithAppliesToValues = locationsWithAppliesToValues;
            this.appliesToValues = this.getAppliesToValues(locationsWithAppliesToValues);
            const formattedImplicitFilters = this.formatImplicitFilters(implicitFilters);
            this.implicitFilters = formattedImplicitFilters;
            this.loadingImplicitFilters = false;
        } catch (error) {
            this.setError(this.errorLabel);
        }
    }

    getAppliesToValues(locationsWithAppliesToValues) {
        let appliesToValues = [];
        locationsWithAppliesToValues.forEach(locationWithAppliesTo => {
            appliesToValues = [...appliesToValues, ...locationWithAppliesTo.appliesTo];
        });
        return appliesToValues;
    }

    formatImplicitFilters(implicitFilters) {
        const columnFieldNames = this.implicitFiltersColumns.map(column => column.fieldName);
        const expectedFields = new Set(columnFieldNames);
        expectedFields.add('id');
        const formattedImplicitFilters = implicitFilters.map(dataRecord => {
            const formattedRecord = {};
            Object.keys(dataRecord)
                .filter(dataRecordField => expectedFields.has(dataRecordField.toLowerCase()))
                .forEach(dataRecordField => {
                    formattedRecord[dataRecordField.toLowerCase()] = this.formatField(dataRecord, dataRecordField, this.locationsWithAppliesToValues, this.appliesToValues);
                });
            return formattedRecord;
        });
        formattedImplicitFilters.sort(this.implicitFilterSort());
        return formattedImplicitFilters;
    }

    formatField(record, field, locations, appliesToValues) {
        const recordFieldValue = record[field];
        if (recordFieldValue && field.toLowerCase() === LOCATION_FIELD_LOWER) {
            return locations.find(location => location.value === recordFieldValue).label;
        } else if (recordFieldValue && field.toLowerCase() === APPLIES_TO_FIELD_LOWER) {
            const appliesToValue = appliesToValues.find(appliesTo => appliesTo.value === recordFieldValue);
            return appliesToValue ? appliesToValue.label : '';
        }
        return recordFieldValue;
    }

    implicitFilterSort() {
        // We will perform a case-insensitive sort, where inclusion is a boolean value
        const location = x => x[LOCATION_FIELD_LOWER]?.toLowerCase();
        const appliesTo = x => x[APPLIES_TO_FIELD_LOWER]?.toLowerCase() ?? '';
        const inclusion = x => x[INCLUSION_FIELD_LOWER];

        return (first, second) => {
            const firstLocation = location(first);
            const firstAppliesTo = appliesTo(first);
            const firstInclusion = inclusion(first);

            const secondLocation = location(second);
            const secondAppliesTo = appliesTo(second);

            // Sorts Implicit Filters first by Location, then by Applies To, and finally by Inclusion where true comes first
            return firstLocation.localeCompare(secondLocation) || firstAppliesTo.localeCompare(secondAppliesTo) || (firstInclusion ? -1 : 1);
        };
    }

    handleImplicitFilterRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'edit': {
                this.handleEditEvent(row)
                break;
            }
            case 'delete': {
                this.handleDeleteEvent(row);
                break;
            }
            default:
                break;
        }
    }

    handleEditEvent(row) {
        this.showImplicitFilterDetail = true;
        this.implicitFilterDetailAction = 'edit';
        this.implicitFilterId = row.id;
    }

    async handleDeleteEvent(row) {
        try {
            await deleteRecord(row.id);
        } catch (e) {
            this.setError(e);
        }
        await this.refreshImplicitFilters();
    }

    createNewImplicitFilter() {
        this.showImplicitFilterDetail = true;
        this.implicitFilterDetailAction = 'new';
        this.implicitFilterId = null;
    }

    closeImplicitFiltersDetail() {
        this.showImplicitFilterDetail = false;
    }

    doneModifyingImplicitFilter() {
        this.showImplicitFilterDetail = false;
        // We currently do not receive any information from the Implicit Filter Detail modal when it is done
        // This is why we will force a refresh when the user is done modifying.
        this.refreshImplicitFilters();
    }

    async refreshImplicitFilters() {
        this.loadingImplicitFilters = true;
        const implicitFilters = await getImplicitFilters();
        const formattedImplicitFilters = this.formatImplicitFilters(implicitFilters);
        this.implicitFilters = formattedImplicitFilters;
        this.loadingImplicitFilters = false;
    }

    setError(e) {
        const errMsg = (e.body && e.body.message) ? e.body.message : e;
        const error = { message: errMsg };
        this.dispatchEvent(VeevaToastEvent.error(error, "sticky"));
    }
}