import { LightningElement, wire, api, track } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPageController } from "c/veevaPageControllerFactory";
import { NavigationMixin } from "lightning/navigation";
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import VeevaUtils from 'c/veevaUtils';
import VeevaPageReference from "c/veevaPageReference";
import { getRecord } from "lightning/uiRecordApi";
import VeevaPerfLogService from 'c/veevaPerfLogService';
import VeevaConstant from 'c/veevaConstant';
import veevaButtonAction from '@salesforce/messageChannel/Veeva_Button_Action__c';
import VeevaToastEvent from "c/veevaToastEvent";

export default class VeevaEditPage extends NavigationMixin(LightningElement) {
    renderEvent = {};
    buttonActionSubscription;

    @wire(MessageContext)
    messageContext;

    @track isSaving;
    redirectInProgress = false;

    constructor() {
        super();
        this.renderEvent.start = +new Date();
        this.template.addEventListener(
            "close",
            this.handleClose.bind(this)
        );
    }

    connectedCallback() {
        this.redirectInProgress = false;
        this.buttonActionSubscription = subscribe(
            this.messageContext,
            veevaButtonAction,
            message => this._handleButtonMessage(message)
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
        //workaround for Caching issue when Overriding the "Edit" Action in Lightning Experience,
        //and attempting to edit a submitted record more than once
        if (this.pageCtrl && this.pageCtrl.record) {
            this.redirectOrShow();
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
    @api recordId;
    @track fields;

    @track show;

    @track page = { requests: [], recordErrors: null, action: 'Edit' }; // page UI state

    @wire(getObjectInfo, { objectApiName: "$objectApiName" })
    async wiredObjectInfo({ error, data }) {
        if (data) {
            this.pageCtrl.objectInfo = JSON.parse(JSON.stringify(data));
            this.fields = this.pageCtrl.getQueryFields();
        }
        if (error) {
            this.setError(error);
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: '$fields' })
    async wiredObjectDetails({ error, data }) {
        if (data){
            this.pageCtrl.record = JSON.parse(JSON.stringify(data));
            this.page.title = await this.pageCtrl.getEditPageTitle();
            await this.pageCtrl.initPageLayout();
            this.redirectOrShow();
        }
        if (error) {
            this.setError(error);
        }
    }

    async redirectOrShow() {
        const redirectPageRef = await this.pageCtrl.getRedirectPageRef();
        if (redirectPageRef && !this.redirectInProgress) {
            if (!this.pageCtrl.canEdit) {
                let toast = await VeevaToastEvent.notAllowedToEdit();
                this.dispatchEvent(toast)
            }
            this.redirect(redirectPageRef, true)
        } else {
            this.show = true;
        }
    }

    redirect(pageRef, replaceBrowserHistory = false)  {
        if (this.redirectInProgress) {
            return;
        }
        this.redirectInProgress = true;
        this[NavigationMixin.Navigate](pageRef, replaceBrowserHistory);
    }

    async handleSaveRecord(parameters) {
        this.clearPageError();
        this.isSaving = true;
        if (!this.checkValidity()) {
            // UI errors such as 'required'
            await this.setPageError(true);
            return;
        }
        const valid = await this.pageCtrl.validate({ submit: parameters.submit });
        if (!valid) {
            // model errors
            await this.setPageError(false);
            return;
        }
        const [error, data] = await VeevaUtils.to(this.pageCtrl.save({ submit: parameters.submit }));
        if (error) {
            // save errors from database
            await this.setPageError(false);
            return;
        }

        // Medical Inquiry --mpi could result in a delete while edit
        if (data.Deleted) {
            // let toast = await VeevaToastEvent.recordDeleted();
            // this.dispatchEvent(toast);
            const ref = {
                type: "standard__objectPage",
                attributes: {
                    objectApiName: this.objectApiName,
                    actionName: "list"
                }
            };
            this.redirect(ref);
        }
        else {
            // let toast = await VeevaToastEvent.recordSaved();
            // this.dispatchEvent(toast);
            // refresh (refreshApex does not work)
            this.handleClose(parameters, data.Id);
        }
    }

    handleClose(parameters, id) {
        this.isSaving = false;
        const navigateId = VeevaUtils.validSfdcId(id) ? id : this.recordId;
        const saveAndNew = parameters && parameters.saveAndNew;
        const redirectTo = this.pageCtrl.getPageRefForClose(
            navigateId, saveAndNew, this.pageReference.state);
        this.redirect(redirectTo);
    }

    checkValidity() {
        let elem = this.template.querySelector("c-veeva-modal-page");
        return elem ? elem.checkValidity() : true;
    }

    async setPageError(isUiError) {
        this.isSaving = false;
        this.page.recordErrors = [...this.pageCtrl.recordErrors || []];
        if (isUiError || (this.page.recordErrors && this.page.recordErrors.length > 0)) {
            // Use Veeva msg till we can access translated messages from Salesforce
            this.page.reviewError = await this.pageCtrl.getMessageWithDefault(
                "ERROR_REVIEW_MSG", "Common", "Review all error messages below to correct your data.");
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
            perfLog.logPagePerformance(VeevaConstant.EDIT_LWC, this._objectApiName, this.renderEvent);
            this.renderEvent = {};
        }
    }
}