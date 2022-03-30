export default class VeevaObjectInfo {

    constructor(objectInfo) {
        this.fields = objectInfo.fields;
        this.apiName = objectInfo.apiName;
        this.label = objectInfo.label;
        this.updateable = objectInfo.updateable;
        this.deletable = objectInfo.deletable;
        this.createable = objectInfo.createable;
        this.queryable = objectInfo.queryable;
        this.defaultRecordTypeId = objectInfo.defaultRecordTypeId;
        this.recordTypeInfos = objectInfo.recordTypeInfos;
        this.childRelationships = objectInfo.childRelationships;
        this.recordTypeInfos = objectInfo.recordTypeInfos;
        this.childRelationships = objectInfo.childRelationships || [];
        this.childRelationshipMap = this.processObjectInfoChildRelationships(this.childRelationships);
    }

    get objectApiName() {
        return this.apiName;
    }

    processObjectInfoChildRelationships(childRelationships) {
        return childRelationships.reduce(function(map, obj) {
                map[obj.relationshipName] = obj;
                return map;
            }, {});
    }

    getQueryFields(filters) {
        let queryFields = [];
        for (let [key, value] of Object.entries(this.fields)) {
            if (!filters || filters.includes(key)) {
                queryFields.push(this.apiName + "." + key);
                if (value.relationshipName && value.referenceToInfos) {
                    let nameField = this.getNameFieldOfRelationship(value.referenceToInfos);
                    if (nameField !== "") {
                        queryFields.push(this.apiName + "." + value.relationshipName + "." + nameField);
                    }
                }
            }
        }
        return queryFields;
    }

    getNameFieldOfRelationship(referenceToInfos) {
        let nameField = "";
        if (referenceToInfos.length && referenceToInfos[0].nameFields && referenceToInfos[0].nameFields.length) {
            let nameFields = referenceToInfos[0].nameFields;
            if (nameFields.indexOf("Name") === -1) {
                nameField = nameFields[0];
            } else {
                nameField = "Name";
            }
        }
        return nameField;
    }

    getFieldInfo(name) {
        return this.fields[name];
    }

    getChildObjectInfo(name) {
        return this.childRelationshipMap[name];
    }

    updateableField(name) {
        return this.fields[name] && this.fields[name].updateable;
    }

    getMasterRecordType() {
        return Object.values(this.recordTypeInfos).find(rt => rt.master);
    }
}