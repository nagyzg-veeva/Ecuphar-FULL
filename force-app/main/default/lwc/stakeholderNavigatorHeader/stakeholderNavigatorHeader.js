import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import ACCOUNT_OBJECT from '@salesforce/schema/Account'
import ACCOUNT_PLAN_OBJECT from '@salesforce/schema/Account_Plan_vod__c'
import NAME_FIELD from '@salesforce/schema/Account_Plan_vod__c.Name';
import FORMATTED_NAME_FIELD from '@salesforce/schema/Account.Formatted_Name_vod__c';

export default class StakeholderNavigatorHeader extends NavigationMixin(LightningElement) {

    @track
    breadcrumbName;

    @track
    acctPlanId;

    @track
    acctId;

    @track
    isAccountPlan = false;

    @track
    numberAccounts;

    @track
    accountPlural;

    @track
    accountPlanPlural;

    @track
    stakeholderNavigator;

    @track
    toggleAffiliations;

    @api 
    get rootId() {
        return this._rootId;
    }
    set rootId(value) {
        this._rootId = value;
        this.acctPlanId = value;
        this.acctId = value;
    }

    @api 
    get snMessage() {
        return this.stakeholderNavigator;
    }
    set snMessage(value) {
        this.stakeholderNavigator = value;
    }

    @api 
    get toggleAffMessage() {
        return this.toggleAffiliations;
    }
    set toggleAffMessage(value) {
        this.toggleAffiliations = value;
    }

    @api 
    get numAcctLoaded() {
        return this.numberAccounts;
    }
    set numAcctLoaded(value) {
        this.numberAccounts = value;
    }

    @wire(getRecord, { recordId: "$acctPlanId", fields: [NAME_FIELD] })
    async getAccountPlanName({ error, data }) {
        if (data) {;
            this.breadcrumbName = data.fields.Name.value;
            this.isAccountPlan = true;
        }
    }

    @wire(getRecord, { recordId: "$acctId", fields: [FORMATTED_NAME_FIELD] })
    async getAccountName({ error, data }) {
        if (data) {
            this.breadcrumbName = data.fields.Formatted_Name_vod__c.value;
            this.isAccountPlan = false;
        }
    }

    @wire(getObjectInfos, { objectApiNames: [ACCOUNT_OBJECT, ACCOUNT_PLAN_OBJECT]})
    async getObjectNames({ error, data }) {
        if (data && data.results.length > 0) {
            for (let r of data.results) {
                if (r.result.apiName === "Account") {
                    this.accountPlural = r.result.labelPlural;
                }
                if (r.result.apiName === "Account_Plan_vod__c") {
                    this.accountPlanPlural = r.result.labelPlural;
                }
            }
        }
    }

    navigateToObject() {
        if (this.isAccountPlan) {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: this.acctPlanId,
                    objectApiName: "Account_Plan_vod__c",
                    actionName: "view"
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: this.acctId,
                    objectApiName: "Account",
                    actionName: "view"
                }
            });
        }
    }   

    toggleAffiliationsAction() {
        this.dispatchEvent(new CustomEvent("toggle-affiliations"));
    }
}