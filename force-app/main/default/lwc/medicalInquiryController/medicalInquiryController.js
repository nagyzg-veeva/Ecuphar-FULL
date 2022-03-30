import VeevaPageController from 'c/veevaPageController';
import MedicalInquiryRecord from "c/medicalInquiryRecord";
import MedInqConstant from "c/medInqConstant";
import ZvodDeliveryMethodController from "c/zvodDeliveryMethodController";
import MpiSectionController from "c/mpiSectionController";
import VeevaConstant from 'c/veevaConstant';
import getSentEmailRecordTypeId from '@salesforce/apex/MedInqController.getSentEmailRecordTypeId';
import VeevaLayoutService from 'c/veevaLayoutService';
import AssignToUserController from "c/assignToUserController";
import getUserRecordAccess from "@salesforce/apex/UserRecordAccessVod.getUserRecordAccess";

VeevaConstant.OBJECT_ICONS.Medical_Inquiry_vod__c = 'custom:custom22';

export default class MedicalInquiryController extends VeevaPageController {

    constructor(dataSvc, userInterface, messageSvc) {
        super(dataSvc, userInterface, messageSvc);
        
        this.messageSvc.loadVeevaMessageCategories(['MEDICAL_INQUIRY']);
    }

    initItemController(meta, record) {
        if (meta.field) {
            switch (meta.field) {
                case MedInqConstant.ZVOD_DELIVERY_METHOD:
                    return new ZvodDeliveryMethodController(meta, this, record);
                case "Assign_To_User_vod__c":
                    return new AssignToUserController(meta, this, this.objectInfo.getFieldInfo(meta.field), record);
                default:
                    break;
            }
        }
        return super.initItemController(meta, record);
    }

    initTemplate(ctrl) {
        switch (ctrl.fieldApiName) {
            // render as text, not checkbox
            case MedInqConstant.DISCLAIMER:
            case MedInqConstant.ZVOD_DISCLAIMER:
                ctrl.veevaText = true;
                return ctrl;

            case MedInqConstant.ACCOUNT:
                if (!this.record.isNew) {
                    ctrl.editable = false;
                }
                return super.initTemplate(ctrl);

            case VeevaConstant.FLD_SIGNATURE_DATE_VOD:
                ctrl.editable = false;
                this._sigDateOnLayout = true;
                return super.initTemplate(ctrl);

            case MedInqConstant.GROUP_IDENTIFIER:
                ctrl.editable = false;
                return super.initTemplate(ctrl);

            case MedInqConstant.PRODUCT:
                ctrl.editable = Boolean(ctrl.editable && !(this._isMpi && ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD)));
                return super.initTemplate(ctrl);

            case MedInqConstant.INQUIRY_TEXT:
            case MedInqConstant.DELIVERY_METHOD:
                ctrl.editable = Boolean(ctrl.editable && !ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD));
                return super.initTemplate(ctrl);

            default:
                return super.initTemplate(ctrl);
        }
    }

    async getModalButtons() {
        const buttonPromises = [this.createCancelButton()];

        if (this.action === 'New' || this.action === 'Edit') {
            if (this.isButtonAvailable(VeevaConstant.SAVE_VOD)) {
                buttonPromises.push(this.createSaveButton());
            }
            if (await this.isSubmitButtonAvailable()) {
                buttonPromises.push(this.createSubmitButton());
            }
        }

        return Promise.all(buttonPromises);
    }

    getSectionController(meta) {
        let signals = meta.signals || [];
        if (signals.includes("mpi")) {
            return new MpiSectionController(meta, this).initTemplate();
        }
        return super.getSectionController(meta, this);
    }

    async save(value) {
        value = value || {};
        let data = value.data || this.getChanges();

        if (!value.submit) {
            if (this._mpiChanges && data && data.data) { // mpi array
                data.data.forEach(each => {
                    if (each && !each.Deleted) {
                        each[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SAVED_VOD;
                    }
                })
            }
            else {
                data[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SAVED_VOD;
            }
        }

        return super.save({
            submit: value.submit,
            data: data
        });
    }

    processLayout(layout) {
        this._isMpi = layout.sections && layout.sections.find(section => VeevaLayoutService.hasSignal(section, 'mpi'));
        if (this.action === 'New') {
            this.processStatusField(layout);
        }
        this.processAddressVodSection(layout.sections);
        return layout;
    }

    processStatusField(layout) {
        if (layout.sections) {
            layout.sections.forEach(section => {
                section.layoutRows.forEach(row => {
                    row.layoutItems.forEach(item => {
                        if (item.field === VeevaConstant.FLD_STATUS_VOD && !item.editableForNew) {
                            this.record.setFieldValue(VeevaConstant.FLD_STATUS_VOD, '');
                        }
                    });
                });
            });
        }
    }

    processAddressVodSection(sections) {
        let deliveryMethod = null;
        let fields = [];
        let requiredFields = [];
        for (let i = sections.length - 1; i >= 0; i--) {
            let section = sections[i];
            if (section.heading === 'Address_vod') {
                // remove the section
                sections.splice(i, 1);
                let items = VeevaLayoutService.getSectionItems(section);
                fields = items.map(x => x.field);
                requiredFields = items.filter(x => x.required).map(x => x.field);
            }
            if (!deliveryMethod) {
                deliveryMethod = VeevaLayoutService.getSectionItems(section).find(x => x.field === MedInqConstant.ZVOD_DELIVERY_METHOD);
                if (deliveryMethod) {
                    deliveryMethod.options = section.signals || [];
                }
            }
        }
        if (deliveryMethod) {
            if (!fields.length) {
                MedInqConstant.NEW_FIELDS.ana.forEach(x => { if (this.objectInfo.getFieldInfo(x) !== null) { fields.push(x); } })
            }
            deliveryMethod.mailFields = fields;
            if (!requiredFields.length) {
                requiredFields = fields.filter(x => MedInqConstant.REQUIRED_NEW_MAIL_FIELDS.includes(x));
            }
            deliveryMethod.requiredMailFields = requiredFields;
        }
        return deliveryMethod;
    }

    toVeevaRecord(value) {
        return value instanceof MedicalInquiryRecord ? value : new MedicalInquiryRecord(value, this.messageSvc);
    }

    setMpiChanges(value) {
        this._mpiChanges = value;
    }

    setMpiInfo(records, mpiFields) {
        this._mpiRecords = records;
        this._mpiFields = mpiFields;
    }

    getChanges() {
        if (this._mpiChanges) {
            return { data: this._mpiChanges, url: 'Medical_Inquiry_vod__c/mpi' };
        }
        return super.getChanges();
    }

    getPageRefAfterSave(data) {
        let mpiPageRef;
        if (this._mpiChanges && data && data.length) {
            mpiPageRef = data.find(x => (x.Id === this.id) && !x.Deleted) || 
                data.find(x => !x.Deleted) || data[0];
        }
        return mpiPageRef || super.getPageRefAfterSave(data);
    }

    processError(data) {
        if (this._mpiRecords && data && data.length === this._mpiRecords.length) {
            data.forEach(each => {
                (each.recordErrors || []).forEach(msg => this.addRecordError(msg));
            });
            // console.log(this.recordErrors);
            return;
        }
        super.processError(data);
    }

    async validate(value) { // value is an object
        if (this._isMpi && (!this._mpiRecords || this._mpiRecords.length === 0)) {
            return false;
        }
        if (this._sigDateOnLayout && value.submit) {
            if (!this.record.rawValue(VeevaConstant.FLD_SIGNATURE_DATE_VOD)) {
                await this.setRecordError(MedInqConstant.MSG_SIGNATURE_REQUIRED, MedInqConstant.CAT_MEDICAL_INQUIRY, "Signature Date is required");
                return false;
            }
        }
        return super.validate(value);
    }

    toButtonCtrl(btn, record) {
        if (btn.name === MedInqConstant.SEND_EMAIL_VOD) {
            return this.getSendEmailButton(btn, record);
        }
        else if (btn.name === MedInqConstant.RECORD_A_CALL_VOD) {
            return this.getRecordACallButton(btn, record);
        }
        else if (btn.name === VeevaConstant.CLONE_VOD) {
            return Promise.resolve({ ...btn });
        }
        return null;
    }

    async getSendEmailButton(btn, record) {
        const recordForButton = record || this.record;

        let recordTypeId = await getSentEmailRecordTypeId();
        if (recordTypeId) {
            let ref = {
                type: 'standard__webPage',
                attributes: {
                    url: `/apex/Send_Approved_Email_vod?oType=approvedEmail&location=Medical_Inquiry_vod&Medical_Inquiry_vod__r.Id=${recordForButton.id}`
                }
            };
            return { ...btn, pageRef: ref };
        }
        return null;
    }

    async getRecordACallButton(btn, record) {
        const recordForButton = record || this.record;

        let accountId = recordForButton.rawValue('Account_vod__c');
        if (!accountId) {
            return null;
        }
        let doNotCall = await this.doNotCall(accountId);
        if (!doNotCall) {
            let ref = {
                type: 'standard__webPage',
                attributes: {
                    url: `/apex/Call_New_vod?queryParams=typ=Medical_Inquiry_vod__c%26id=${recordForButton.id}`
                }
            };
            return { ...btn, pageRef: ref };
        }
        return null;
    }

    async doNotCall(accountId) {
        if (!accountId) {
            return true;
        }
        let account = await this.uiApi.getRecord(accountId, ['Account.Do_Not_Call_vod__c']);
        let values = account.fields.Do_Not_Call_vod__c || {};
        if ('Yes_vod' === values.value) {
            return true;
        }
        return false;
    }

    getDataForClone() {
        let skips = [...MedInqConstant.CLONE_SKIP_FIELDS];
        if (!this._isMpi) {
            skips.push('Product__c');
        }
        let clonedData = super.getDataForClone(skips);    
        clonedData.cloneFromId = this.record.id;
        return clonedData;
    }

    async getHeaderButtons() {
        let buttons = super.getHeaderButtons();
        if (buttons.length && (!this.record.isSubmitted || this._isMpi)) {
            buttons = buttons.filter(x => !MedInqConstant.CUSTOM_BUTTONS.includes(x.name));
        }
        // If a record is submitted
        if (buttons.length && this.record.isSubmitted) {
            // Filter inaccessible custom buttons
            buttons = await Promise.all(buttons.map(btn => this.isButtonAccessible(btn)));
            buttons = buttons.filter(x => x);
        }
        if (this.record.isLocked && this.objectInfo.updateableField("Lock_vod__c")) {
            buttons.push({ name: 'Unlock', standard: true });
        }

        let hasRecordDeleteAccess = false;
        let hasRecordEditAccess = false;
        const userRecordAccess = await getUserRecordAccess({ 'recordId': this.record.id});
        if (userRecordAccess){
            hasRecordDeleteAccess = userRecordAccess.HasDeleteAccess;
            hasRecordEditAccess = userRecordAccess.HasEditAccess;
        }
        buttons = this.filterDeleteButton(buttons, hasRecordDeleteAccess);
        buttons = this.filterCloneButton(buttons);
        buttons = this.filterEditButton(buttons, hasRecordEditAccess);
        return buttons;
    }

    async isButtonAccessible(button) {
        // Check if a button is a custom button
        if (MedInqConstant.CUSTOM_BUTTONS.includes(button.name)) {
            // Return button if accessible
            button = await this.toButtonCtrl(button);
            return (button ? button : null);
        }
        // Non-custom buttons are assumed to be accessible all times
        return button;
    }

    filterDeleteButton(buttons, hasRecordDeleteAccess) {
        // If record is locked or signature date is set
        if (buttons.length && (this.record.isLocked || this.record.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD) || !hasRecordDeleteAccess)) {
            // Remove delete button
            buttons = buttons.filter(btn => btn.name !== 'Delete');
        }
        return buttons;
    }

    filterEditButton(buttons, hasRecordEditAccess) {
        // If record is locked
        if (buttons.length && (this.record.isLocked || !hasRecordEditAccess)) {
            // Remove edit button
            buttons = buttons.filter(btn => btn.name !== 'Edit');
        }
        return buttons;
    }

    filterCloneButton(buttons) {
        // If user does not have create permission for MI
        if (!this.objectInfo.createable) {
            // Remove clone button
            buttons = buttons.filter(btn => !VeevaConstant.CLONE_VOD.includes(btn.name));
        }
        return buttons;
    }

    async isSubmitButtonAvailable() {
        const statusPicklistValues = await this.uiApi.getPicklistValues(this.record.recordTypeId, this.objectApiName,
            VeevaConstant.FLD_STATUS_VOD);
        let isFlsSatisfied = this.objectInfo.getFieldInfo(VeevaConstant.FLD_LOCK_VOD)
            && this.objectInfo.getFieldInfo(VeevaConstant.FLD_STATUS_VOD);

        // If FLS is not satisfied or if Status picklist does not have Submitted option
        if (!isFlsSatisfied || !statusPicklistValues.values.find(el => el.value === VeevaConstant.SUBMITTED_VOD)) {
            // Remove submit button
            return false;
        }
        return super.isSubmitButtonAvailable();
    }

    setSubmit(data) {
        if (this._mpiChanges && data && data.data) { // mpi array
            data.data.forEach(each => {
                if (each && !each.Deleted) {
                    each[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SUBMITTED_VOD;
                }
            })
        }
        else {
            super.setSubmit(data);
        }
    }

    unlock() {
        let saveData;
        if (this._mpiRecords && this._mpiRecords.length > 0) {
            const dataArr = this._mpiRecords.map(record => ({
                type: this.objectApiName,
                Id: record.id,
                Lock_vod__c: false
            }));
            saveData = {
                "data": dataArr,
                "url": 'Medical_Inquiry_vod__c/mpi'
            };
        }
        return super.unlock(saveData);
    }

    _getWatchKey(fieldName, recordId) {
        let watchKey = fieldName;
        if (this._mpiRecords && this._mpiFields.includes(fieldName)) {
            watchKey = `${recordId}_${fieldName}`;
        } 
        return watchKey;
    }

    async processForLDSCache(data){
        if (this._mpiChanges && data && data.data) {
            const recordIds = data.data
                .filter(record=>record && record.Id && !record.Deleted)
                .map(record=>{return {recordId: record.Id};});
            if (recordIds && recordIds.length > 0) {
                this.notifyLDSCache(recordIds);
            }
        } else if (data && data.data) {
            const recordIds = data.data
                .filter(record => record && record.Id && !record.Deleted && record.Lock_vod__c === false)
                .map(record => {return { recordId: record.Id } });
            if (recordIds && recordIds.length > 0) {
                this.notifyLDSCache(recordIds);
            }
        } else {
            super.processForLDSCache(data);
        }
    }

    useFlowNavAfterNew(saveAndNew) {
        return !saveAndNew;
    }
}