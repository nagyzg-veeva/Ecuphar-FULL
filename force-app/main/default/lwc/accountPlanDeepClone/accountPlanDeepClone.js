import { api, LightningElement, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import { getObjectInfo, getObjectInfos } from "lightning/uiObjectInfoApi";
import { getPageController } from "c/veevaPageControllerFactory";
import AccountPlanCloneController from "c/accountPlanCloneController";
import VeevaToastEvent from "c/veevaToastEvent";
import VeevaUtils from "c/veevaUtils";
import { loadStyle } from 'lightning/platformResourceLoader';
import toast_msg_styles from '@salesforce/resourceUrl/toast_msg_styles';

export default class AccountPlanDeepClone extends  NavigationMixin(LightningElement) {

    @api recordId;

    @track pageCtrl;
    @track page = { requests: [], pageErrors: null, action: 'Clone' };
    @track childObjectNames;
    @track hierarchyLevels;

    @track hierarchyObjLabelsWithCounts=[];
    @track relatedObjLabelsWithCounts=[];
    @track itemControllers = [];
    @track hierarchyObjectIdsMap;
    @track relatedObjectIdsMap;
    @track recordTypeName;
    @track waiting = true;
    @track accountPlanFields;

    //Veeva Messages
    @track header;
    @track selectObjectsLabel;
    @track accountPlanHierarchyLabel;
    @track otherLabel;
    @track recordTypeLabel;
    @track cloneBtnLabel;
    @track cancelBtnLabel;

    @track objectName = 'Account_Plan_vod__c';
    @track externalStylesLoaded = false;

    constructor() {
        super();
        this.initComponent();
    }

    async initComponent() {
        this.pageCtrl = getPageController('Account_Plan_vod__c--CLONE');
        this.pageCtrl.page = this.page;
    }

    renderedCallback(){
        if(!this.externalStylesLoaded) {
            loadStyle(this, toast_msg_styles).then(()=>{
                console.log('styles loaded');
            })
            .catch(err => {
                console.warn('Error loading external styles');
            });
            this.externalStylesLoaded = true;
        }
    }

    @wire(getObjectInfo, { objectApiName: "$objectName" })
    async wiredObjectInfo({ error, data }) {
        if (data) {
            this.pageCtrl.objectInfo = JSON.parse(JSON.stringify(data));
            this.accountPlanFields = this.pageCtrl.getQueryFields();
        }
        if (error) {
            this.setError('setup');
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$accountPlanFields' })
    wiredRecordInfo({ error, data }) {
        if (data) {
            try{
                this.pageCtrl.record = JSON.parse(JSON.stringify(data));
                if (data.recordTypeInfo && data.recordTypeInfo.name){
                    this.recordTypeName = data.recordTypeInfo.name;
                }
                this.setAccountPlanNameForClone();
                this.setChildObjectNames(this.pageCtrl.objectInfo.childRelationships);
                this.setUpScreenComponents();
            } catch(e) {
                this.setError('setup', e);
            }
        }
        if (error) {
            console.error(error);
            this.setError('setup');
        }
    }

    @wire(getObjectInfos, { objectApiNames: '$childObjectNames' })
    async wiredChildObjectInfo({ error, data }) {
        if (data) {
            try{
                let objectInfoMap = new Map();
                let objectInfos = data.results;
                for (let objectInfo of objectInfos){
                    objectInfoMap.set(objectInfo.result.apiName, objectInfo.result);
                }
                objectInfoMap.set(this.objectName,this.pageCtrl.objectInfo);
                this.pageCtrl.childObjectMetadata = objectInfoMap;
                let missingPermissions = this.pageCtrl.validateChildObjectRelationships(this.hierarchyLevels);
                missingPermissions = missingPermissions.filter(o => {
                    const objName = o.split('.')[0];
                    return !this.relatedObjectRelationships.delete(objName);
                });
                if (missingPermissions.length > 0){
                    this.setError('permissions', missingPermissions);
                }else{
                    this.pageCtrl.hierarchyInfo = this.hierarchyLevels;
                    await Promise.all([this.getChildRecordCounts(), await this.getVeevaMessages()]);
                    this.waiting = false;
                }
            } catch(e) {
                this.setError('setup', e);
            }
        }
        if (error) {
            console.error(error);
            this.setError('setup');
        }
    }    

    async getChildRecordCounts(){        
        const [hierarchyObjectsInfoReults, relatedObjectsInfoResults] = await Promise.all([
            this.pageCtrl.getHierarchyRecordCounts(this.recordId),
            this.pageCtrl.getRelatedRecordCounts(this.relatedObjectRelationships, this.recordId)
        ]);
        this.hierarchyObjectIdsMap = hierarchyObjectsInfoReults.objIdMap;
        this.hierarchyObjLabelsWithCounts = hierarchyObjectsInfoReults.objCountMap;
        this.relatedObjectIdsMap = relatedObjectsInfoResults.relatedObjIdMap;
        this.relatedObjLabelsWithCounts = relatedObjectsInfoResults.objCountMap;
    }

    async setChildObjectNames(accountPlanChildRelationships){
        this.pageCtrl.getAccountPlanHierarchy().then(hierarchy =>
            this.getChildObjectNamesFromRelationships(hierarchy, accountPlanChildRelationships)
        ).catch(e => {
            this.setError('setup', e);
        });
    }

    getChildObjectNamesFromRelationships(accountPlanHierarchyStr, accountPlanChildRelationships){
        let children = [];
        this.hierarchyLevels = accountPlanHierarchyStr.split(',');
        let hierarchyObjectNames = this.hierarchyLevels.map(objPair => objPair.split('.')[0]);
        children.push(...hierarchyObjectNames);
        this.relatedObjectRelationships = this.pageCtrl.getRelatedObjectsForAccountPlan(accountPlanChildRelationships, hierarchyObjectNames);
        children.push(...Array.from(this.relatedObjectRelationships.keys()));
        children.push('Account');
        this.childObjectNames = children;
    }

    async cloneAccountPlan(){
        this.clearPageErrors();
        this.waiting = true;
        const cloneSelections = this.getCheckboxSelections();

        Object.keys(this.hierarchyObjectIdsMap).forEach(k => {
            if (cloneSelections && !cloneSelections.includes(k)){
                delete this.hierarchyObjectIdsMap[k];
            }
        });
        Object.keys(this.relatedObjectIdsMap).forEach(k => {
            if (cloneSelections && !cloneSelections.includes(k)){
                delete this.relatedObjectIdsMap[k];
            }
        });
        let [error, data] = await VeevaUtils.to(this.pageCtrl.cloneAccountPlan(this.hierarchyObjectIdsMap, this.relatedObjectIdsMap));

        if (error){
            this.pageCtrl.processError(error);
            this.setPageError();
        } else {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: data.newAccountPlanId,
                    objectApiName: "Account_Plan_vod__c",
                    actionName: "view"
                }
            });
        }
    }

    getCheckboxSelections(){
        let selectedObjects = [];
        this.hierarchyObjLabelsWithCounts.forEach(o => {
            let currElement = this.template.querySelector("input[data-hrobj-id='" + o.object + "']");
            if (currElement.checked){
                selectedObjects.push(o.object);
            }
        });
        this.relatedObjLabelsWithCounts.forEach(o => {
            let currElement = this.template.querySelector("input[data-hrobj-id='" + o.object + "']");
            if (currElement.checked){
                selectedObjects.push(o.object);
            }
        });
        return selectedObjects;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent("cancel"));
    }

    async getVeevaMessages(){
        const [headerMsg, recordTypeMsg, selectObjMsg, accountPlanHierarchyMsg, otherMsg, cloneMsg, cancelMsg] = await Promise.all([
            this.pageCtrl.getMessageWithDefault('ENTER_DETAILS', 'ACCOUNT_PLAN', 'Enter Account Plan Details'), 
            this.pageCtrl.getMessageWithDefault('RECORD_TYPE_LABEL', 'Common', 'Record Type'),
            this.pageCtrl.getMessageWithDefault('SELECT_RELATED', 'ACCOUNT_PLAN', 'Select Related Objects to Clone'),
            this.pageCtrl.getMessageWithDefault('ACCOUNT_PLAN_HIERARCHY', 'ACCOUNT_PLAN', 'Account Plan Hierarchy'),
            this.pageCtrl.getMessageWithDefault('OTHER', 'ACCOUNT_PLAN', 'Other'),
            this.pageCtrl.getMessageWithDefault('CLONE', 'Common', 'Clone'),
            this.pageCtrl.getMessageWithDefault('CANCEL', 'Common', 'Cancel')
        ]);
        this.header = headerMsg;
        this.recordTypeLabel = recordTypeMsg;
        this.selectObjectsLabel =  selectObjMsg;
        this.accountPlanHierarchyLabel =  accountPlanHierarchyMsg;
        this.otherLabel =  otherMsg;
        this.cloneBtnLabel = cloneMsg;
        this.cancelBtnLabel = cancelMsg;
    }

    setAccountPlanNameForClone(){
        this.pageCtrl.record.setFieldValue('Name', 'CLONE - ' + this.pageCtrl.record.name);
    }

    setUpScreenComponents(){
        const itemMap = this.pageCtrl.getDeepCloneScreenItems();
        itemMap.forEach((v, k) => {
            this.itemControllers = [...this.itemControllers, { key: k, value: v }];
        });
    }

    checkBoxToggle(event){        
        let objectLabel = event.target.dataset.hrobjId;
        let currIndex = this.hierarchyObjLabelsWithCounts.findIndex(o => o.object === objectLabel);
        while ((++currIndex) < this.hierarchyObjLabelsWithCounts.length){
            let currElement = this.template.querySelector("input[data-hrobj-id='" + this.hierarchyObjLabelsWithCounts[currIndex].object + "']");
            if (event.target.checked){
                currElement.disabled = false;
                currElement.checked = true;
            }else{
                currElement.checked = false;
                currElement.disabled = true;    
            }                
        }
    }
 
    async setError(stage, data){
        const errMsgInfo = AccountPlanCloneController.ERROR_MESSAGES[stage];
        let errMsg = await this.pageCtrl.getMessageWithDefault(errMsgInfo.get("msg"), errMsgInfo.get("category"), errMsgInfo.get("text"));
        let missingObjects = [];
        let missingFields = [];
        if (stage === 'permissions' && data){
            data.forEach(objectField => {
                const[obj, field] = objectField.split('.');
                if (field){
                    missingFields.push(objectField);
                } else if (obj) {
                    missingObjects.push(obj);
                }
            });
            errMsg = errMsg.replace('{0}', missingObjects);
            errMsg = errMsg.replace('{1}', missingFields);
        } else if (data && data.body){
            errMsg = data.body.message;
        }
        const error = { message: errMsg};
        this.dispatchEvent(VeevaToastEvent.error(error, "sticky"));
        this.handleCancel();
    }

    async setPageError(){
        this.page.errors = [...this.pageCtrl.recordErrors || [], ...this.pageCtrl.pageErrors || []];
        AccountPlanCloneController.CLONE_SCREEN_FIELDS.forEach((field) => {
            if (this.pageCtrl.fieldErrors && this.pageCtrl.fieldErrors[field]){
                this.pageCtrl.fieldErrors[field].forEach(fieldErr => this.page.errors.push(fieldErr.message));
            }
        });
        if (this.page.errors.length > 0){
            this.page.reviewError = await this.pageCtrl.getMessageWithDefault(
                "CLONE_FAILURE", "ACCOUNT_PLAN", "Encountered the following error when performing the clone.");
        } else {
            this.setError('clone');
        }
        this.waiting = false;
    }

    clearPageErrors() {
        this.page.recordErrors = null;
        this.page.reviewError = null;
        this.pageCtrl.clearPageErrors();
    }
}