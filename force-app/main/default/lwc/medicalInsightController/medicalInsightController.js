import VeevaPageController from 'c/veevaPageController';
import VeevaConstant from 'c/veevaConstant';
import MedicalInsightRecord from 'c/medicalInsightRecord';
import ACCOUNT_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Account_vod__c'
import DATE_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Date_vod__c';
import STATUS_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Status_vod__c';
import UNLOCK_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Unlock_vod__c';
import getUserRecordAccess from "@salesforce/apex/UserRecordAccessVod.getUserRecordAccess";

export default class MedicalInsightController extends VeevaPageController {
    
    constructor(dataSvc, userInterface, messageSvc) {
        super(dataSvc, userInterface, messageSvc);
        
        this.messageSvc.loadVeevaMessageCategories(['Medical']);
    }

    async initRecordCreate(pageRef) {
        let defaultFieldValues = pageRef.state.defaultFieldValues && JSON.parse(pageRef.state.defaultFieldValues) || {};
        if (!defaultFieldValues.hasOwnProperty(DATE_FIELD.fieldApiName) || !defaultFieldValues[DATE_FIELD.fieldApiName].value) {
            defaultFieldValues[DATE_FIELD.fieldApiName] = { "value": new Date().toISOString() };
        }
        pageRef.state.defaultFieldValues = JSON.stringify(defaultFieldValues);
        await super.initRecordCreate(pageRef);
    }

    async getHeaderButtons() {
        let buttons = super.getHeaderButtons();
        if (this.record.isSubmitted) {
            if (this._isUnlockable()) {
                buttons.push({ name: 'Unlock', standard: true });
            }
        } 
        let hasRecordDeleteAccess = false;
        let hasRecordEditAccess = false;
        const userRecordAccess = await getUserRecordAccess({ 'recordId': this.record.id});
        if (userRecordAccess){
            hasRecordDeleteAccess = userRecordAccess.HasDeleteAccess;
            hasRecordEditAccess = userRecordAccess.HasEditAccess;
        }
        buttons = this.filterDeleteButton(buttons, hasRecordDeleteAccess);
        buttons = this.filterEditButton(buttons, hasRecordEditAccess);
        return buttons;
    }

    toVeevaRecord(value) {
        return value instanceof MedicalInsightRecord ? value : new MedicalInsightRecord(value);
    }

    filterDeleteButton(buttons, hasRecordDeleteAccess) {
        if (buttons.length && (this.record.isLocked || !hasRecordDeleteAccess)) {
            buttons = buttons.filter(btn => btn.name !== 'Delete');
        }
        return buttons;
    }

    filterEditButton(buttons, hasRecordEditAccess) {
        if (buttons.length && (this.record.isLocked || !hasRecordEditAccess)) {
            buttons = buttons.filter(btn => btn.name !== 'Edit');
        }
        return buttons;
    }

    isButtonAvailable(btnName) {
        let available = super.isButtonAvailable(btnName);
        if (btnName === VeevaConstant.SAVE_VOD) {
            available = true;
        }
        return available;
    }

    isSubmitButtonAvailable(){
        let canSubmit = super.isSubmitButtonAvailable();
        if (canSubmit) {
            canSubmit = this.objectInfo.updateableField(STATUS_FIELD.fieldApiName);
        }
        return canSubmit;
    }

    getPageRefForSaveAndNew(id, pageState) {
        let pageRef = super.getPageRefForSaveAndNew(id, pageState);
        let defaultFieldValues = {};
        if (pageState.defaultFieldValues) {
            defaultFieldValues = JSON.parse(pageState.defaultFieldValues);
        }
        defaultFieldValues[ACCOUNT_FIELD.fieldApiName] = { value: this.record.value(ACCOUNT_FIELD.fieldApiName).value };
        Object.assign(pageRef.state, {
            defaultFieldValues: JSON.stringify(defaultFieldValues)
        })
        return pageRef;
    }

    async save(value) {
        value = value || {};
        let data = value.data || this.getChanges();

        if (!value.submit && !data[VeevaConstant.FLD_STATUS_VOD]) { 
            data[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SAVED_VOD;
        }

        return super.save({
            submit: value.submit,
            data: data
        });
    }

    unlock() {
        return super.unlock({
            type: this.objectApiName,
            Id: this.id,
            Status_vod__c: VeevaConstant.SAVED_VOD,
            Override_Lock_vod__c: true
        });
    }

    _isUnlockable() {
        return this.objectInfo.updateableField(UNLOCK_FIELD.fieldApiName) && this._statusUpdateable();
    }

    _statusUpdateable() {
        return this.objectInfo.updateableField(STATUS_FIELD.fieldApiName);
    }

    useFlowNavAfterNew(saveAndNew) {
        return !saveAndNew;
    }
}