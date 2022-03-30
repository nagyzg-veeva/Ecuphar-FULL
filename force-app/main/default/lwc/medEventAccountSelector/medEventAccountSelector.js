import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPageController } from "c/veevaPageControllerFactory";
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import MedEventAccountSelectorCtrl from 'c/medEventAccountSelectorCtrl';
import VeevaToastEvent from "c/veevaToastEvent";
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import MEDICAL_EVENT_OBJECT from '@salesforce/schema/Medical_Event_vod__c';
import MEDICAL_INSIGHT_ACCOUNT_FIELD from '@salesforce/schema/Medical_Insight_vod__c.Account_vod__c';

export default class MedEventAccountSelector extends LightningElement {
    @api ctrl;
    @api exitEarly;
    @api defaultFieldValues;

    @track columns;
    @track labelCancel;
    @track modalHeader;
    @track resultTitle;
    @track searchRecords;

    async connectedCallback() {
        this._uiApi = getPageController('userInterfaceSvc');
        this._uiApi.requests = [];
        this._messageSvc = getPageController('messageSvc');
        this._defaultFieldValues = JSON.parse(this.defaultFieldValues);
        this.ctrl = new MedEventAccountSelectorCtrl(this._uiApi, this._messageSvc);
        this.loadMessages();
        this.setColumnsAndSearch();
    }

    async loadMessages() {
        const [cancelMsg, selectAccountMsg] = await Promise.all([
            this._messageSvc.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
            this._messageSvc.getMessageWithDefault('SELECT_ACCOUNT', 'Common', 'Select Account')
        ]);

        this.labelCancel = cancelMsg;
        this.modalHeader = selectAccountMsg;
    }

    async setColumnsAndSearch() {
        this.columns = await this.ctrl.getColumns();
        await this.getSearchRecords();
    }

    async getSearchRecords() {
        const colFlds = this.columns.map(col => col.queryFld);
        const records = await this.ctrl.getRecordsWithColumns(colFlds, this._defaultFieldValues[MEDICAL_EVENT_OBJECT.objectApiName].value);
        if (records.length === 0) {
            this.goToNext();
        } else if (records.length === 1) {
            this.setAccountAndNavigate(records[0]);
        } else {
            this.searchRecords = records;
        }
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    wiredLookupInfo({ error, data }) {
        if (data) {
            this.ctrl.objectInfo = data;
            this.resultTitle = data.labelPlural;
        }
        if (error) {
            console.error(`getObjectInfo error: ${error}`);
            this.setError(error);
        }
    }

    setError(error) {
        this.dispatchEvent(VeevaToastEvent.error(error));
    }

    finishFlow() {
        this.exitEarly = true;
        this.goToNext();
    }

    goToNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleRowSelection(event) {
        this.setAccountAndNavigate(event.detail);
    }

    setAccountAndNavigate(record) {
        this._defaultFieldValues[MEDICAL_INSIGHT_ACCOUNT_FIELD.fieldApiName] = { "displayValue": record.Name, "value": record.id };
        this.defaultFieldValues = JSON.stringify(this._defaultFieldValues);
        this.goToNext();
    }

    get showAccountSelector() {
        return this.searchRecords;
    }

    get hideCheckbox() {
        return true;
    }
}