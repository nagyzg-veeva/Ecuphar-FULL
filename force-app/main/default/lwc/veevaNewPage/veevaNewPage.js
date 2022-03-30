import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import VeevaToastEvent from "c/veevaToastEvent";
import { getPageController } from "c/veevaPageControllerFactory";
import VeevaPageReference from "c/veevaPageReference";
import { NavigationMixin } from 'lightning/navigation';
import VeevaUtils from 'c/veevaUtils';
import VeevaPerfLogService from 'c/veevaPerfLogService';
import VeevaConstant from 'c/veevaConstant';
import veevaButtonAction from '@salesforce/messageChannel/Veeva_Button_Action__c';

// VeevaNewPage is used for overriding the New button. 
// It sets the default field values. 
// In addition, it sets the lookup field value from which the New action starts. 
// Know issue: Salesforce @wire caches New page https://success.salesforce.com/issues_view?id=a1p3A000000JWUgQAO
export default class VeevaNewPage extends NavigationMixin(LightningElement) {
    @api isFlowScreen;
    @track isSaving;
    renderEvent = {};
    buttonActionSubscription;

    @wire(MessageContext)
    messageContext;

    constructor() {
        super();
        this.renderEvent.start = +new Date();
        this.template.addEventListener(
            "close",
            this.handleClose.bind(this)
        );
    }

    connectedCallback() {
        this.buttonActionSubscription = subscribe(
            this.messageContext,
            veevaButtonAction,
            (message) => this._handleButtonMessage(message)
        );
    }

    _handleButtonMessage(message) {
        const buttonMatchesPage = message.recordId === this.pageCtrl.id &&
            message.pageMode === this.pageCtrl.action;
        if (buttonMatchesPage) {
            if (message.action === 'saverecord') {
                this.handleSaveRecord(message.parameters);
            }
        }
    }

    disconnectedCallback() {
        if (this.buttonActionSubscription) {
            unsubscribe(this.buttonActionSubscription);
            this.buttonActionSubscription = null;
        }
    }

    @api get pageReference() {
        return this._pageReference;
    }
    set pageReference(value) {
        this._pageReference = VeevaPageReference.getPageReference(value);
        if (this.pageCtrl && this.pageCtrl.objectInfo && this.pageCtrl.objectInfo.apiName === this.objectApiName) {
            //workaround for Caching issue when Overriding the "New" Action in Lightning Experience
            //manually reset page metadata and record data
            this.page = { requests: [], action: 'New' };
            const objectInfo = this.pageCtrl.objectInfo;
            
            this.pageCtrl = getPageController(this.objectApiName);
            this.pageCtrl.page = this.page;
            this.pageCtrl.objectInfo = objectInfo;
            this.initRecordCreate();
        }
    }

    @api get objectApiName() {
        return this._objectApiName;
    }
    set objectApiName(value) {
        this.pageCtrl = getPageController(value);
        this.pageCtrl.page = this.page;
        this._objectApiName = value;
    }
    @track page = { requests: [], action: 'New' };

    @wire(getObjectInfo, { objectApiName: "$objectApiName" })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.pageCtrl.objectInfo = JSON.parse(JSON.stringify(data));
            this.initRecordCreate();
        }
        if (error) {
            this.setError(error);
        }
    }

    async initRecordCreate(){
        const objInfo = this.pageCtrl && this.pageCtrl.objectInfo;
        if (this._pageReference && objInfo){
            if (this._pageReference.state && !this._pageReference.state.recordTypeId){
                this._pageReference.state.recordTypeId = objInfo.defaultRecordTypeId;
            }
            const [titleTemplate] = await Promise.all([
                this.pageCtrl.getMessageWithDefault("NEW", "Common", "New"), 
                this.pageCtrl.initRecordCreate(this._pageReference)
            ]);
            const recordTypeLabel = (this.pageCtrl.record.recordTypeInfo && this.pageCtrl.record.recordTypeInfo.name) || '';
            this.page.title = `${titleTemplate} ${objInfo.label}: ${recordTypeLabel}`;
            this._tempId = VeevaUtils.getRandomId();
        }
    }

    async handleSaveRecord(parameters) {
        this.isSaving = true;
        this.clearPageError();
        if (!this.checkValidity()) {
            // UI errors such as 'required'
            await this.setPageError(true);
            return;
        }
        let valid = await this.pageCtrl.validate({ submit: parameters.submit });
        if (!valid) {
            // model errors
            await this.setPageError(false);
            return;
        }
        let [error, data] = await VeevaUtils.to(this.pageCtrl.save({ submit: parameters.submit }));
        if (error) {
            // save errors from database
            await this.setPageError(false);
            return;
        }
        // let toast = await VeevaToastEvent.recordCreated();
        // this.dispatchEvent(toast);
        this.handleClose(parameters, data.Id);
    }

    handleClose(event, id) {
        this.isSaving = false;
        if (event && event.type === 'close') {
            event.stopPropagation();
        }
        const saveAndNew = event && event.saveAndNew;
        const redirectTo = this.pageCtrl.getPageRefForClose(
            id, saveAndNew, this.pageReference.state);
        if (this.isFlowScreen) {
            const eventObj = {
                detail: { pageRef: redirectTo, useFlowNavAfterNew : this.pageCtrl.useFlowNavAfterNew(saveAndNew) }
            };
            this.dispatchEvent(new CustomEvent("close", eventObj));
        } else {
            this[NavigationMixin.Navigate](redirectTo);
        }
    }

    checkValidity() {
        let elem = this.template.querySelector("c-veeva-modal-page");
        return elem ? elem.checkValidity() : true;
    }

    setError(error) {
        this.dispatchEvent(VeevaToastEvent.error(error));
    }

    async setPageError(isUiError) {
        this.isSaving = false;
        this.page.recordErrors = [...this.pageCtrl.recordErrors || []];
        
        if (isUiError || (this.page.recordErrors && this.page.recordErrors.length > 0)) {
            // Use Veeva msg till we can access translated messages from Salesforce
            this.page.reviewError = 
            await this.pageCtrl.getMessageWithDefault("ERROR_REVIEW_MSG", "Common", 
                "Review all error messages below to correct your data.");
        }
    }

    clearPageError() {
        this.page.recordErrors = null;
        this.page.reviewError = null;
        this.pageCtrl.clearErrors();
    }

    renderedCallback(){
        if (this.renderEvent && this.renderEvent.start){
            let perfLog = new VeevaPerfLogService();
            perfLog.logPagePerformance(VeevaConstant.NEW_LWC, this._objectApiName, this.renderEvent);
            this.renderEvent = {};
        }
    }
}