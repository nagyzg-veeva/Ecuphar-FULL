import AccountPlanHierarchyRecord from 'c/accountPlanHierarchyRecord';

export default class AccountPlanHierarchy {

    constructor(hierarchyLevels, objectInfoMap) {
        this._hierarchyObjectMap = new Map();
        let parentNameInSettings = 'Account_Plan_vod__c';
        for (let objPair of hierarchyLevels){
            const [child, parentRelationship] = objPair.split('.');
            if (objectInfoMap.has(child)){
                const childFields = objectInfoMap.get(child).fields;
                const parentField = Object.keys(childFields).find(e => childFields[e].relationshipName && (childFields[e].relationshipName === parentRelationship));
                if (parentField){
                    let parentObjectName;
                    for (const reference of childFields[parentField].referenceToInfos){
                        if (reference.apiName === parentNameInSettings){
                            parentObjectName = reference.apiName;
                        }
                    }
                    let childRelationships = objectInfoMap.get(parentObjectName).childRelationships;
                    let childRelationship = childRelationships.find(cr => cr.childObjectApiName === child && cr.fieldName === parentField);
                    const hierarchyRecord = new AccountPlanHierarchyRecord(child, parentField, childRelationship.relationshipName);
                    this._hierarchyObjectMap.set(parentObjectName, hierarchyRecord);
                }
                parentNameInSettings = child;
            }
        }
    }

    getChildObjectName(parentObjectName){
        let childObjectName;
        if (this._hierarchyObjectMap && this._hierarchyObjectMap.has(parentObjectName)){
            childObjectName = this._hierarchyObjectMap.get(parentObjectName).childObjectName;
        }
        return childObjectName;
    }

    getChildRelationshipName(parentObjectName){
        let childRelationshipName;
        if (this._hierarchyObjectMap && this._hierarchyObjectMap.has(parentObjectName)){
            childRelationshipName = this._hierarchyObjectMap.get(parentObjectName).childRelationship;
        }
        return childRelationshipName;
    }

    getParentRelationshipName(childObjectName){
        let parentRelationshipName;
        if (this._hierarchyObjectMap && this._hierarchyObjectMap.has(childObjectName)){
            parentRelationshipName = this._hierarchyObjectMap.get(childObjectName).parentRelationship;
        }
        return parentRelationshipName;
    }

    getAllParents(){
        return Array.from(this._hierarchyObjectMap.keys());
    }

    hasObjectAsParentInHierarchy(objectName){
        let isParent = false;
        if (this._hierarchyObjectMap && this._hierarchyObjectMap.has(objectName)){
            isParent = true;
        }
        return isParent;
    }
}