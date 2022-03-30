import VeevaPageController from "c/veevaPageController";
import VeevaRecord from "c/veevaRecord";
import VeevaObjectInfo from "c/veevaObjectInfo";
import AccountPlanHierarchy from "c/accountPlanHierarchy";
import getAccountPlanObjectHierarchy from "@salesforce/apex/VeevaAccountPlanController.getAccountPlanObjectHierarchy";
import getHierarchyRecordIds from "@salesforce/apex/VeevaAccountPlanController.getHierarchyRecordIds";
import getRelatedRecordIds from "@salesforce/apex/VeevaAccountPlanController.getRelatedRecordIds";
import insertClonedAccountPlan from "@salesforce/apex/VeevaAccountPlanController.insertClonedAccountPlan";

export default class AccountPlanCloneController extends VeevaPageController {

    static DEFAULT_CLONE_VALUES = new Map([["Status_vod__c", "Pending_vod"], ["Progress_vod__c", "0"], ["Mobile_ID_vod__c", null], ["External_ID_vod__c", null]]);
    static OBJECT_DEFAULT_CLONE_VALUES = {
        "Account_Plan_vod__c" : new Map([["Status__c", "Pending"], ["Progress_vod__c", "0"], ["Plan_Tactic_Progress_vod__c", null], ["Percent_Complete_vod__c", null], ["Total_Plan_Tactics_vod__c", null], ["Active_vod__c", false], ["Mobile_ID_vod__c", null], ["External_ID_vod__c", null]]),
        "Plan_Tactic_vod__c" : new Map([["Status_vod__c", "Pending_vod"], ["Progress_vod__c", "0"], ["Account_Tactic_Progress_vod__c", null], ["Completed_Account_Tactics_vod__c", null], ["Total_Account_Tactics_vod__c", null], ["Mobile_ID_vod__c", null], ["External_ID_vod__c", null]]),
        "Account_Tactic_vod__c" : new Map ([["Status_vod__c", "Pending_vod"], ["Progress_vod__c", "0"], ["Call_Objective_Progress_vod__c", null], ["Complete_vod__c", "false"], ["Completed_Call_Objectives_vod__c", null], ["Total_Call_Objectives_vod__c", null], ["Mobile_ID_vod__c", null], ["External_ID_vod__c", null]]),
        "Action_Item_vod__c" : new Map ([["Status_vod__c", "Pending_vod"], ["Mobile_ID_vod__c", null], ["External_ID_vod__c", null], ["Call2_vod__c", null], ["Completed_By_vod__c", null], ["Completed_Date_vod__c", null], ["Assignee_vod__c", null]]),
        "Call_Objective_vod__c" : new Map ([["Call2_vod__c", null], ["Completed_Flag_vod__c", "false"], ["Date_vod__c", null], ["Suggestion_vod__c", null], ["Suggestion_Reason_vod__c", null], ["Parent_Objective_vod__c", null], ["Non_Executable_vod__c", null], ["Mobile_ID_vod__c", null], ["External_ID_vod__c", null]]) };
    static CUSTOM_CLONE_FIELDS = ['Name', 'RecordTypeId', 'CurrencyIsoCode'];
    static CLONE_SKIP_RELATIONSHIPS = ["Call2_vod__c", "Medical_Insight_vod__c", "Account_Plan_vod__c"];
    static CLONE_SCREEN_FIELDS = ["Name", "Account_vod__c", "Description_vod__c"];
    static ERROR_MESSAGES = {
        "setup" : new Map([["msg", "CLONE_ERROR_WHILE_LOADING"], ["category", "ACCOUNT_PLAN"], ["text", "Encountered an error when retrieving data for the clone process. Please contact your system administrator."]]),
        "permissions": new Map([["msg", "INSUFFICIENT_ACCESS_CLONE_ACCOUNT_PLAN"], ["category", "ACCOUNT_PLAN"], ["text", "Clone Account Plan cannot open because you do not have access to the following:\n\nObjects: {0}\n\nObject Fields: {1}"]]),
        "clone": new Map([["msg", "CLONE_FAILURE"], ["category", "ACCOUNT_PLAN"], ["text", "Encountered the following error when performing the clone."]])
    }


    constructor(dataSvc, userInterface, messageSvc) {
        super(dataSvc, userInterface, messageSvc);
        
        this.messageSvc.loadVeevaMessageCategories(['ACCOUNT_PLAN']);
    }

    get childObjectMetadata(){
        return this._childObjectMetadata;
    }

    set childObjectMetadata(value) {
        this._childObjectMetadata = value;
    }

    get hierarchyInfo() {
        return this._hierarchyinfo;
    }

    set hierarchyInfo(accountPlanhierarchySetting){
        this._hierarchyinfo = new AccountPlanHierarchy(accountPlanhierarchySetting, this._childObjectMetadata);
    }

    async getAccountPlanHierarchy(){
        return getAccountPlanObjectHierarchy();
    }

    async getHierarchyRecords(hierarchyObjectsIdMap){
        const allRecords = [];
        let parent = 'Account_Plan_vod__c';
        const allRecordPromises = [];
        while(this.hierarchyInfo.hasObjectAsParentInHierarchy(parent)){
            const ids = [];
            const childObjectName = this.hierarchyInfo.getChildObjectName(parent);
            const veevaObjectInfo =  new VeevaObjectInfo(this.childObjectMetadata.get(childObjectName));
            if (hierarchyObjectsIdMap[childObjectName]){
                ids.push( ...hierarchyObjectsIdMap[childObjectName]);
            }
            //Split array to avoid hitting API url length limits
            const idsMaster = this.splitArray(ids, 200);
            if (idsMaster.length > 0) {
              for (const idList of idsMaster) {
                let records = this.uiApi.getBatchRecords(idList, veevaObjectInfo.getQueryFields());
                allRecordPromises.push(records);
              }
            }
            parent = childObjectName;
        }
        await Promise.all(allRecordPromises).then(allRecordPromises.forEach((recordPromise) => recordPromise.then( data => allRecords.push(...data))));
        const hierarchyRecords = this.assignRecordsToObjectTypes(allRecords);
        return hierarchyRecords;
    }

    async getRelatedObjectRecords(relatedObjectsIdMap){
        const allRecordPromises = [];
        const allRecords = [];
        let relatedObjectRecords = new Map();
        for (const objName of Object.keys(relatedObjectsIdMap)){
            const ids = [];
            const veevaObjectInfo =  new VeevaObjectInfo(this.childObjectMetadata.get(objName));
            if (relatedObjectsIdMap[objName]){
                ids.push( ...relatedObjectsIdMap[objName]);
            }
            //Split array to avoid hitting API url length limits
            const idsMaster = this.splitArray(ids, 200);
            if (idsMaster.length > 0) {
                for (const idList of idsMaster) {
                let records = this.uiApi.getBatchRecords(idList, veevaObjectInfo.getQueryFields());
                allRecordPromises.push(records);
                }
            }
        }
        await Promise.all(allRecordPromises).then(allRecordPromises.forEach((recordPromise) => recordPromise.then( data => allRecords.push(...data))));
        relatedObjectRecords = this.assignRecordsToObjectTypes(allRecords);
        return relatedObjectRecords;
    }

    assignRecordsToObjectTypes(records){
        const objectRecordMap = new Map();
        for (let record of records){
            if (!objectRecordMap.has(record.apiName)){
                objectRecordMap.set(record.apiName, [record]);
            } else {
                objectRecordMap.get(record.apiName).push(record);
            }
        }
        return objectRecordMap;
    }

    getRelatedObjectsForAccountPlan(childRelationships, hierarchyObjectNames){
        const relatedObjectRelationships = new Map();
        for (let childRelationship of childRelationships){
            if (!AccountPlanCloneController.CLONE_SKIP_RELATIONSHIPS.includes(childRelationship.childObjectApiName)
                && !hierarchyObjectNames.includes(childRelationship.childObjectApiName)
                && (childRelationship.childObjectApiName).endsWith('__c')){
                relatedObjectRelationships.set(childRelationship.childObjectApiName, childRelationship);
            }
        }
        return relatedObjectRelationships;
    }

    async getRelatedRecordCounts(relatedObjectRelationships, accountPlanId){
        const relatedObjectMap = {};
        await relatedObjectRelationships.forEach((v, k) => {
            relatedObjectMap[k] = v.relationshipName;
        });
        const relatedObjectInfo = await getRelatedRecordIds({ relatedObjectInfo: relatedObjectMap, recordId: accountPlanId });
        const relatedObjectCounts = this.getRelatedObjectCountsFromIdMap(relatedObjectRelationships, relatedObjectInfo);
        const results = {relatedObjIdMap : relatedObjectInfo, objCountMap : relatedObjectCounts};
        return results;
    }

    getRelatedObjectCountsFromIdMap(relatedObjectRelationships, relatedObjectInfo){
        const relatedObjectCounts = [];
        relatedObjectRelationships.forEach((v, k) => {
            if (relatedObjectInfo && relatedObjectInfo[k]){
                relatedObjectCounts.push({ value: Object.keys(relatedObjectInfo[k]).length, key: this._childObjectMetadata.get(k).labelPlural, object: this._childObjectMetadata.get(k).apiName });
            }
        });
        return relatedObjectCounts;
    }

    async getHierarchyRecordCounts(accountPlanId){
        const hierarchyObjects = {};
        this.hierarchyInfo.getAllParents().forEach((p) => {
            hierarchyObjects[p] =  this.hierarchyInfo.getChildObjectName(p) + "," + this.hierarchyInfo.getChildRelationshipName(p);
        });
        const hierarchyObjectIdsMap = await getHierarchyRecordIds({hierarchyRelationships: hierarchyObjects, recordId: accountPlanId});
        const hierarchyObjectsWithCount = this.getHierarchyRecordCountsFromIdMap(hierarchyObjectIdsMap);
        const results = {objIdMap : hierarchyObjectIdsMap, objCountMap : hierarchyObjectsWithCount};
        return results;
    }

    getHierarchyRecordCountsFromIdMap(hierarchyObectIdsMap){
        let parent = this.hierarchyInfo.getChildObjectName('Account_Plan_vod__c');
        const hierarchyRecordCounts = [];
        
        while (parent != null){
            if (hierarchyObectIdsMap[parent] && (hierarchyObectIdsMap[parent].length > 0)){
                hierarchyRecordCounts.push({ value: hierarchyObectIdsMap[parent].length, key: this._childObjectMetadata.get(parent).labelPlural,
                    object: this._childObjectMetadata.get(parent).apiName });
            }
            if (this.hierarchyInfo.hasObjectAsParentInHierarchy(parent)){
                parent = this.hierarchyInfo.getChildObjectName(parent);
            } else {
                parent = null;
            }
        }
        return hierarchyRecordCounts;
    }

    async cloneAccountPlan(hierarchyObjectIdsMap, relatedObjectIdsMap){
        const hierarchyMap = {};
        const clonedHierarchyRecordsMap = {};
        const clonedRelatedRecordsMap = {};

        const [hierarchyRecordsMap, relatedRecordsMap] = await Promise.all([
            this.getHierarchyRecords(hierarchyObjectIdsMap),
            this.getRelatedObjectRecords(relatedObjectIdsMap)]);
        
        const defaultCloneValues = AccountPlanCloneController.OBJECT_DEFAULT_CLONE_VALUES[this.objectInfo.apiName]
            ? AccountPlanCloneController.OBJECT_DEFAULT_CLONE_VALUES[this.objectInfo.apiName]
            : AccountPlanCloneController.DEFAULT_CLONE_VALUES;
        this.record.updateDefaultValuesForClone(this.objectInfo, defaultCloneValues);

        const acctPlanClone = this.getDataForDeepClone(this.record, this.objectInfo,[]);
        acctPlanClone.Clones_vod__c = this.record._id;        

        clonedHierarchyRecordsMap.Account_Plan_vod__c = [acctPlanClone];
        let objectsWithAccountLookup = this.getObjectsWithAccountLookup(Array.from(hierarchyRecordsMap.keys()));

        for (const parent of this.hierarchyInfo.getAllParents()) {
            hierarchyMap[parent] = this.hierarchyInfo.getChildObjectName(parent);
            const childObject = this.hierarchyInfo.getChildObjectName(parent);
            if (hierarchyRecordsMap.has(childObject)){
                let accountFieldNames;
                if (objectsWithAccountLookup.has(childObject)){
                    accountFieldNames = objectsWithAccountLookup.get(childObject);
                }
                clonedHierarchyRecordsMap[childObject] = this.getClonedRecords(hierarchyRecordsMap.get(childObject), this._childObjectMetadata.get(childObject), true, accountFieldNames);
            }
        }
        for (const [key, value] of relatedRecordsMap.entries()) {
            clonedRelatedRecordsMap[key] = this.getClonedRecords(value, this._childObjectMetadata.get(key), true);
        }
        return this.insertAccountPlan(clonedHierarchyRecordsMap, hierarchyMap, clonedRelatedRecordsMap);
    }

    getClonedRecords(records, objectInfo, copyId, accountLookupFields){
        const clonedRecords = [];
        const veevaObjectInfo =  new VeevaObjectInfo(objectInfo);
        for (let record of records){
            let currentRecord = new VeevaRecord(record);
            let defaultCloneValues = AccountPlanCloneController.OBJECT_DEFAULT_CLONE_VALUES[veevaObjectInfo.apiName] 
                                        ? AccountPlanCloneController.OBJECT_DEFAULT_CLONE_VALUES[veevaObjectInfo.apiName]
                                        : AccountPlanCloneController.DEFAULT_CLONE_VALUES;
            currentRecord.updateDefaultValuesForClone(veevaObjectInfo, defaultCloneValues);
            let clonedRecord = this.getDataForDeepClone(currentRecord, veevaObjectInfo, []);
            if (copyId && currentRecord._id){
                clonedRecord.id = currentRecord._id;
            }
            if (this.record.old && this.record.old.Account_vod__c && accountLookupFields && accountLookupFields.length){
                for (const lookupField of accountLookupFields){
                    if (clonedRecord[lookupField] === this.record.old.Account_vod__c){
                        clonedRecord[lookupField] = this.record.fields.Account_vod__c.value;
                    }
                }
            }
            clonedRecords.push(clonedRecord);
        }
        return clonedRecords;
    }

    async insertAccountPlan(clonedHierarchyObjectsMap, hierarchyObjectMap, clonedRelatedObjectsMap){
        let saveResult;
        saveResult = await insertClonedAccountPlan({hierarchyObjects: clonedHierarchyObjectsMap,
            hierarchyMap: hierarchyObjectMap, relatedObjects: clonedRelatedObjectsMap});
        return saveResult;
    }

    splitArray(objectArr, size){
        const chunkedArr = [];
        let index = 0;
        while (index < objectArr.length) {
            chunkedArr.push(objectArr.slice(index, size + index));
            index += size;
        }
        return chunkedArr;
    }

    getDeepCloneScreenItems(){
        const itemControllers = new Map();
        AccountPlanCloneController.CLONE_SCREEN_FIELDS.forEach(field => {
            const fieldInfo = this.objectInfo.fields[field];
            if (fieldInfo){
                const item = { field: field, editable: fieldInfo.createable,
                                required: field === 'Name' ? 'true' : fieldInfo.required,
                                label: fieldInfo.label,
                                helpText: fieldInfo.inlineHelpText,
                                disabled: false
                            };
                itemControllers.set(field, item);
            }
        });
        return itemControllers;
    }

    getDataForDeepClone(record, objectInfo, skipFields) {
        const values = {};
        values.attributes = { type: objectInfo.apiName };
        Object.entries(record.fields).forEach(([key, value]) => {
            const field = objectInfo.getFieldInfo(key);
            if (field && field.createable && !skipFields.includes(key)) {
                if ((field.custom || AccountPlanCloneController.CUSTOM_CLONE_FIELDS.includes(field.apiName))
                    && (value && (value.value !== undefined) &&  (value.value !== null)) ) {
                    values[key] = value.value;
                }
            }
        });
        return JSON.parse(JSON.stringify(values));
    }

    getObjectsWithAccountLookup(hierarchyObjectNames){
        const accountChildRelationships = this.childObjectMetadata.get('Account').childRelationships;
        const objAccountFields = new Map();
        accountChildRelationships.filter(relationship => hierarchyObjectNames.includes(relationship.childObjectApiName)).forEach(relationship => {
            if (objAccountFields.has(relationship.childObjectApiName)){
                objAccountFields.get(relationship.childObjectApiName).push(relationship.fieldName);
            } else {
                objAccountFields.set(relationship.childObjectApiName, [relationship.fieldName])
            }    
        });
        return objAccountFields;
    }

    async hasAccessToAllChildren(children){
        let allChildObjectNames = await this.getAllChildObjectNames();
        return allChildObjectNames.every(child => {
            const excludedChildObject = !child.endsWith('__c') || AccountPlanCloneController.CLONE_SKIP_RELATIONSHIPS.includes(child);
            return excludedChildObject || children.includes(child);
        });            
    }

    processError(data) {
        this.clearPageErrors();
        if (data.body) {
            if (data.body.pageErrors) {
                data.body.pageErrors.forEach(x => this.addPageError(x.message));
            } else if (data.body.message){
                this.addPageError(data.body.message);
            }
            super.processError(data.body);
        } else if (data.message) {
            this.addPageError(data.message)
        }
    }

    addPageError(msg) {
        this._pageErrors = this._pageErrors || [];
        if (msg && !this._pageErrors.includes(msg)) {
            this._pageErrors.push(msg);
        }
    }

    get pageErrors() {
        return this._pageErrors;
    }

    clearPageErrors() {
        this._pageErrors = [];
        super.clearErrors();
    }

    validateChildObjectRelationships(hierarchyLevels){
        const missingPermissions = [];
        const validatedObjects = [];
        //validate account plan fields
        if (!this.checkObjectFieldFLS('Account_Plan_vod__c', 'Clones_vod__c')){
            missingPermissions.push('Account_Plan_vod__c.Clones_vod__c');
        }
        validatedObjects.push('Account_Plan_vod__c');
        //validate hierarchy objects
        for (let objPair of hierarchyLevels){
            const [child, parentRelationship] = objPair.split('.');
            validatedObjects.push(child);
            if (this.childObjectMetadata.has(child)){
                const childFields = this.childObjectMetadata.get(child).fields;
                const parentField = Object.keys(childFields).find(e => childFields[e].relationshipName && (childFields[e].relationshipName === parentRelationship));
                if (!parentField || !childFields[parentField].createable){
                    missingPermissions.push(child + '.' + parentRelationship);
                }
            } else {
                missingPermissions.push(child);
            }
        }
        //validate all related objects are creteable
        this.childObjectMetadata.forEach((v, k) => {
            if (k !== 'Account' && v && !v.createable && v.apiName){
                missingPermissions.push(v.apiName);
            } else if (k !== 'Account' && v && v.createable && v.apiName){
                const fields = v.fields;
                const accountPlanField = Object.keys(fields).find(e => fields[e].referenceToInfos && fields[e].referenceToInfos[0] && fields[e].referenceToInfos[0].apiName === 'Account_Plan_vod__c');
                if (accountPlanField && !fields[accountPlanField].createable && !validatedObjects.includes(k)){
                    missingPermissions.push(v.apiName + '.' + accountPlanField);
                }
            }
        });
        return missingPermissions;
    }

    checkObjectFieldFLS(obj, field){
        let hasCreatePermissions = false;
        const fields = this.childObjectMetadata.get(obj).fields;
        if (fields[field] && fields[field].createable){
            hasCreatePermissions = true;
        }
        return hasCreatePermissions;
    }
}