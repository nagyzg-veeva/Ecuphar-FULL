import VeevaObjectInfo from "c/veevaObjectInfo";
import VeevaRecord from "c/veevaRecord";
import VeevaConstant from "c/veevaConstant";
import VeevaLayoutService from 'c/veevaLayoutService';
import ControllerFactory from "c/controllerFactory";
import VeevaUtils from "c/veevaUtils";
import VeevaPageReference from 'c/veevaPageReference';
import { getRecordNotifyChange } from "lightning/uiRecordApi";

export default class VeevaPageController {
    constructor(dataSvc, userInterface, messageSvc) {
        this.dataSvc = dataSvc;
        this.uiApi = userInterface;
        this.messageSvc = messageSvc;
    }

    // Use 'page' to notify the View of changes.
    get page() {
        return this._page;
    }
    set page(value) {
        this._page = value;
        this.dataSvc.requests = value.requests;
        this.uiApi.requests = value.requests;
    }
    // Model
    get record() {
        return this._record;
    }
    set record(value) {
        this._record = this.toVeevaRecord(value);
    }
    // metadata
    get objectInfo() {
        return this._objectInfo;
    }
    set objectInfo(value) {
        this._objectInfo = this.toVeevaObjectInfo(value);
    }

    get id() {
        return this._record ? this._record.id : '';
    }

    get recordId() { //for pubsub module fireEvent
        return this.id;
    }

    get objectApiName() {
        return this._objectInfo ? this._objectInfo.apiName : null;
    }

    get objectLabel() {
        return this.objectInfo.label;
    }

    get action() {
        return this.page ? this.page.action : undefined;
    }

    get isClone() {
        return this._isClone;
    }

    get isNew() {
        return this.page && this.page.action === "New";
    }

    getPageIcon() {
        return VeevaUtils.getIcon(this.objectInfo.apiName);
    }

    async getEditPageTitle() {
        return this.getMessageWithDefault('Edit', 'Common', 'Edit')
            .then((edit) => {
                if (this.record?.name) {
                    return `${edit} ${this.record.name}`;
                }
                if (this.objectInfo?.label) {
                    return `${edit} ${this.objectInfo.label}`;
                }
                return edit;
            });
    }

    getPageTitle() {
        return this.objectInfo.label;
    }

    getPageSubtitle() {
        return this.record.name;
    }

    toVeevaObjectInfo(value) {
        return value instanceof VeevaObjectInfo ? value : new VeevaObjectInfo(value);
    }

    toVeevaRecord(value) {
        return value instanceof VeevaRecord ? value : new VeevaRecord(value);
    }

    getQueryFields() {
        return this._objectInfo.getQueryFields();
    }

    async initPageLayout() {
        let layout = await this.uiApi.getPageLayout(this.objectInfo.apiName, this.page.action, this.record.recordTypeId, this.id);
        this.page.layout = await this.processLayout(layout);
        await this.setButtons();
    }

    async initRecordCreate(pageRef) {
        let emptyRecord = new VeevaRecord({});
        if(emptyRecord.isMasterRecordType(pageRef.state.recordTypeId)){
            let availableRecordType = this.getFirstAvailableRecordType();
            pageRef.state.recordTypeId = availableRecordType.recordTypeId;
            this._objectInfo.defaultRecordTypeId = availableRecordType.recordTypeId;
        }
        let defaults = await VeevaPageReference.getCreateDefaults(pageRef, this.uiApi);        
        const defVals = pageRef.state.defaultFieldValues && JSON.parse(pageRef.state.defaultFieldValues);
        this._isClone = defVals && defVals.isClone;

        this.record = defaults.record;
        this.record.assignRandomId();
        this.addDefaultFieldValues(pageRef.state);
        this.page.layout = await this.processLayout(defaults.layout);
        await this.setButtons();
    }

    getFirstAvailableRecordType(){
        let recordTypeArr = Object.values(this._objectInfo.recordTypeInfos).filter(val => val.available);
        recordTypeArr.sort((a, b) => a.name.localeCompare(b.name)); 
        recordTypeArr.sort((a,b) => a.master - b.master); // Push the master Record Type to the end
        return recordTypeArr[0]
     }
 
    async processLayout(layout) {
        return layout;
    }

    async setButtons() {
        this.page.modalButtons = await this.getModalButtons();
        this.page.modalButtons = this.setButtonVariant(this.page.modalButtons);
    }

    setButtonVariant(buttons) {
        function isSubmitPartOfModalButtons() {
            return buttons.findIndex((btn) => btn.name === 'submit') > -1;
        }

        buttons.forEach(btn => {
            if (btn.name === 'save' && isSubmitPartOfModalButtons()) {
                btn.variant = 'brand-outline';
            } else if (btn.name === 'save' || btn.name === 'submit') {
                btn.variant = 'brand';
            }
        });

        return buttons;
    }

    async getCompactLayoutMetadata() {
        const MAX_COMPACT_LAYOUT_FIELDS = 7;
        let recordTypeId = this.record.recordTypeId;
        let layout = await this.uiApi.getCompactLayout(this.objectApiName, 'View', recordTypeId);
        let compactLayoutMetadata = [];
        if (layout && layout.data) {
            for (let section of layout.data.sections) {
                for (let row of section.layoutRows) {
                    for (let item of row.layoutItems) {
                        for (let component of item.layoutComponents) {
                            if (compactLayoutMetadata.length < MAX_COMPACT_LAYOUT_FIELDS) {
                                compactLayoutMetadata.push(component);
                            }
                        }
                    }
                }
            }
        }
        return compactLayoutMetadata;
    }

    getItemController(meta, record) {
        const dataRecord = record || this.record;
        let ctrl = this.initItemController(meta, dataRecord);
        return this.initTemplate(ctrl);
    }

    initItemController(meta, record) {
        return ControllerFactory.itemController(meta, this, record);
    }

    initTemplate(ctrl) {
        return ctrl.initTemplate();
    }

    getSectionController(meta) {
        return ControllerFactory.sectionController(meta, this).initTemplate();
    }

    async save(value) {
        value = value || {};
        let data = value.data || this.getChanges();
        if (value.submit) {
            this.setSubmit(data);
        }
        try {
            let response = await this.dataSvc.save(data);
            //Notify LDS cache of record update
            await this.processForLDSCache(data);
            return this.getPageRefAfterSave(response.data);
        }
        catch (error) {
            this.processError(error.data);
            return Promise.reject({ recordErrors: this._recordErrors, fieldErrors: this.fieldErrors });
        }
    }

    delete() {
        return this.save({ data: { Deleted: "true", Id: this.id, type: this.objectInfo.objectApiName } });
    }

    validate() {
        return true;
    }

    getPageRefAfterSave(data) {
        return data;
    }

    getChanges() {
        return this.record.getChanges(this.objectInfo);
    }

    setSubmit(data) {
        if (data && !data.Deleted) {
            if (VeevaUtils.isEmptyObject(data) && !this.record.isNew) {
                data.Id = this.record.id;
                data.type = this.record.apiName;
            }
            data[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SUBMITTED_VOD;
        }
    }

    unlock(data) {
        const saveData = data || {
            type: this.objectApiName,
            Id: this.id,
            Lock_vod__c: false
        }
        return this.save({ 
            data: saveData
        });
    }

    setFieldValue(field, value, reference, record) {
        const dataRecord = record || this.record;
        dataRecord.setFieldValue(field, value, reference);
        this.updateDependencies(field.apiName || field, value, dataRecord);
    }

    updateDependencies(field, value, record) {
        if (this.__watch) {
            let watchKey = field;
            if (record) {
                watchKey = this._getWatchKey(field, record.id);
            }
            const watchers = this.__watch[watchKey];
            if (watchers) {
                watchers.forEach(x => x.context[x.handler](value));
            }
        }
    }

    track(key, context, handler) {
        // define non enumerable property so it won't be cloned
        if (!this.__watch) {
            Object.defineProperty(this, '__watch', { value: {} });
        }
        let recordId;
        if (context.ctrl) {
            recordId = context.ctrl.id;
        }
        const watchKey = this._getWatchKey(key, recordId);      
        if (!this.__watch[watchKey]) {
            this.__watch[watchKey] = [];
        }
        this.__watch[watchKey].push({ context: context, handler: handler });
    }

    _getWatchKey(fieldName, recordId) {
        return `${recordId}_${fieldName}`;
    }

    toDelete() {
        this.deleted = true;
        this.record.Deleted = true;
    }

    undelete() {
        delete this.deleted;
        delete this.record.Deleted;
    }

    //this is async because child implementations may be async (like in MedicalInquiryController)
    isSubmitButtonAvailable(){
        return this.isButtonAvailable(VeevaConstant.SUBMIT_VOD);
    }

    isButtonAvailable(btnName) {
        return VeevaLayoutService.getButton(this.page.layout, btnName);
    }

    get canCreate() {
        return this.objectInfo.createable;
    }

    get canEdit() {
        return this.objectInfo.updateable && this.record.isEditable;
    }

    get canDelete() {
        return this.objectInfo.deletable && this.record.isDeletable;
    }

    getDataForClone(skips) {
        let data = this.record.getDataForClone(this.objectInfo, skips || []);
        data.retURL = `/lightning/r/${data.type}/${this.record.id}/view`;
        data.isClone = true;
        return data;
    }

    // the defaultFieldValues are used on Clone
    addDefaultFieldValues(state) {
        if (state.defaultFieldValues) {
            let values = JSON.parse(state.defaultFieldValues);
            Object.entries(values).forEach(([key, value]) => {
                if (this.record.fields[key] || this.objectInfo.getFieldInfo(key)) {
                    this.record.fields[key] = value;
                    if (key === 'RecordTypeId' && value && value.value) {
                        this.record.recordTypeId = value.value;
                    }
                }
                else {
                    this.record[key] = value;
                }
            });
        }
    }

    getHeaderButtons() {
        let buttons = this.page.layout.buttons || [];
        buttons = buttons.filter(x => !x.edit);
        if (this.record.isSubmitted) {
            buttons = buttons.filter(x => x.name !== 'Edit' && x.name !== 'Delete');
        }
        return buttons;
    }

    async getModalButtons() {
        const buttonPromises = [this.createCancelButton()];

        if (this.action === 'New' || this.action === 'Edit') {
            if (this.canCreate) {
                buttonPromises.push(this.createSaveAndNewButton());
            }
            buttonPromises.push(this.createSaveButton());
            if (await this.isSubmitButtonAvailable()) {
                buttonPromises.push(this.createSubmitButton());
            }
        }

        return Promise.all(buttonPromises);
    }

    createSaveButton() {
        return this._createCommonModalButton('save', 'SAVE', 'Save');
    }
    
    createSaveAndNewButton() {
        return this.createModalButton('saveAndNew', 'SAVENEW', 'CallReport', 'Save and New');
    }

    createSubmitButton() {
        return this._createCommonModalButton('submit', 'SUBMIT', 'Submit');
    }

    createCancelButton() {
        return this._createCommonModalButton('cancel', 'CANCEL', 'Cancel');
    }

    _createCommonModalButton(name, key, def) {
        return this.createModalButton(name, key, 'Common', def);
    }

    async createModalButton(name, key, category, def) {
        return {
            name: name,
            label: await this.getMessageWithDefault(key, category, def),
            notVeevaCustomButton: true
        };
    }

    processError(data) {
        this.clearErrors();
        if (data) {
            if (data.recordErrors) {
                data.recordErrors.forEach(x => this.addRecordError(x));
            }
            if (data.fieldErrors) {
                this.fieldErrors = Object.assign({}, data.fieldErrors);
            }
        }
    }

    async setRecordError(msgName, category, defMsg) {
        let msg = await this.getMessageWithDefault(msgName, category, defMsg);
        this.addRecordError(msg);
    }

    addRecordError(msg) {
        this._recordErrors = this._recordErrors || [];
        if (msg && !this._recordErrors.includes(msg)) {
            this._recordErrors.push(msg);
        }
    }

    get recordErrors() {
        return this._recordErrors;
    }

    clearErrors() {
        this._recordErrors = [];
        this.fieldErrors = {};
    }

    getRedirectPageRef() {
        if (this.page.action === 'Edit' && this.record.isLocked) {
            return {
                type: "standard__recordPage",
                attributes: {
                    recordId: this.id,
                    objectApiName: this.objectApiName,
                    actionName: "view"
                }
            };     
        }
        return null;
    }

    async processForLDSCache(data){
        if (data && data.Id && !data.Deleted){
            this.notifyLDSCache([{recordId: data.Id }]);
        }
    }

    async notifyLDSCache(recordIds) {
        //doing this because we can't spy on getRecordNotifyChange (hacky; don't want to make a habit of this)
        getRecordNotifyChange(recordIds);
    }

    async getMessageWithDefault(key, category, defaultMessage) {
        return this.messageSvc.getMessageWithDefault(key, category, defaultMessage);
    }

    getPageRefForSaveAndNew(id, pageState) {
        let inContextOfRef = pageState.inContextOfRef;
        let pageRef = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'new'
            }, 
        };

        if (inContextOfRef) {
            pageRef.state = {
                inContextOfRef,
            };
        } else {
            pageRef.state = {
                inContextOfRef: window.btoa(JSON.stringify({
                    type: 'standard__recordPage', 
                    attributes: {
                        recordId: id,
                        objectApiName: this.objectApiName,
                        actionName: 'view'
                    },
                })),
            }
        }

        pageRef.state.additionalParams = pageState.additionalParams;

        return pageRef;
    }

    getPageRefForClose(id, saveAndNew, pageState) {
        let pageRef = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'list'
            }
        };

        if (saveAndNew) {
            pageRef = this.getPageRefForSaveAndNew(id, pageState);
        } else if (pageState && pageState.inContextOfRef) {
            pageRef = pageState.inContextOfRef;
        } else if (VeevaUtils.validSfdcId(id)) {
            pageRef = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: id,
                    objectApiName: this.objectApiName,
                    actionName: "view"
                }
            }
        } else if (this.record && this.record.retURL) {
            pageRef = {
                type: 'standard__webPage',
                attributes: {
                    url: this.record.retURL
                }
            }
        }

        return pageRef;
    }

    getPageRefForDelete() {
        const pageRef = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: this.objectApiName,
                actionName: "list",
            },
        };
        return pageRef;
    }

    getPageRefForUnlock() {
        // override in child implementations to navigate to different page after unlocking record
        return null;
    }
    
    useFlowNavAfterNew(saveAndNew) {
        // override in child implementations in order to use flow nav instead of pageRef
        return false;
    }
}