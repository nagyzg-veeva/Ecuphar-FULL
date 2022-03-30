import VeevaUtils from 'c/veevaUtils';
import VeevaConstant from 'c/veevaConstant';

export default class VeevaRecord {

    static MASTER_RECORD_TYPE_ID = '012000000000000AAA';

    constructor(value) {
        this.recordTypeInfo = value.recordTypeInfo || {};
        this.fields = value.fields || {};
        this._id = value.id;
        this.apiName = value.apiName;
        this._recordTypeId = value.recordTypeId || this.recordTypeInfo.recordTypeId;
    }

    get id() {
        return this._id;
    }
    set id(value) {
        this._id = value;
        if (this.fields.Id) {
            this.fields.Id.value = value;
        }
    }

    get name() {
        return this.displayValue("Name");
    }
    get icon() {
        return VeevaUtils.getIcon(this.apiName);
    }
    get isNew() {
        return !VeevaUtils.validSfdcId(this.id);
    }

    get recordTypeId() {
        if (!this._recordTypeId) {
            if (this.fields.RecordTypeId && this.fields.RecordTypeId.value) {
                this._recordTypeId = this.fields.RecordTypeId.value;
            }
            else if (this.recordTypeInfo && this.recordTypeInfo.recordTypeId) {
                this._recordTypeId = this.recordTypeInfo.recordTypeId;
            }
        }
        return this._recordTypeId;
    }
    set recordTypeId(value) {
        this._recordTypeId = value;
    }

    get isSubmitted() {
        return this.rawValue(VeevaConstant.FLD_STATUS_VOD) === VeevaConstant.SUBMITTED_VOD;
    }

    get isEditable() {
        return !this.isSubmitted;
    }

    get isDeletable() {
        return !this.isSubmitted;
    }

    value(field) {
        return this.fields[field.apiName || field] || { displayValue: '' };
    }

    displayValue(field) {
        let result = this.value(field);
        return result.displayValue || result.value;
    }

    rawValue(field) {
        return this.value(field).value;
    }

    reference(field) {
        let result = {};
        if (field.relationshipName) {
            let ref = this.fields[field.relationshipName];
            if (ref && ref.value) {
                result.name = ref.displayValue;
                result.id = ref.value.id;
                result.apiName = ref.value.apiName;
            }
        }
        if (!result.id) {
            result.id = this.rawValue(field);
        }
        if (!result.name) {
            result.name = this.displayValue(field);
        }
        if (!result.apiName && field.referenceToInfos && field.referenceToInfos.length === 1) {
            result.apiName = field.referenceToInfos[0].apiName;
        }
        return result;
    }

    setFieldValue(field, value, reference) {
        let key = field.apiName || field;
        let current = this.value(key);
        this.old = this.old || {};
        if (!this.isNew && this.old[key] === undefined) {
            this.old[key] = current.value;
        }
        current.value = value;
        if (this.fields[key] === undefined) {
            this.fields[key] = current;
        }
        this.updateReferenceField(field, reference);
    }

    setDisplayValue(field, value) {
        const key = field.apiName || field;
        const current = this.value(key);
        current.displayValue = value;
    }

    updateReferenceField(field, reference) {
        if (field.relationshipName) {
            if (reference && reference.id) {
                this.fields[field.relationshipName] = {
                    displayValue: reference.name,
                    value: { apiName: reference.apiName, id: reference.id }
                };
            }
            else {
                this.fields[field.relationshipName] = { displayValue: null, value: null };
            }
        }
    }

    getChanges(objectInfo) {
        if (this.Deleted) {
            if (!this.isNew) {
                return { Deleted: true, Id: this.id, type: this.apiName };
            }
            return {};
        }
        if (this.isNew) {
            return this.getCreatableValues(objectInfo);
        }
        return this.getUpdatableValues(objectInfo);

    }

    getCreatableValues(objectInfo) {
        let values = {};
        Object.entries(this.fields).forEach(([key, value]) => {
            let field = objectInfo.getFieldInfo(key);
            if (
                field && field.createable &&
                (field.custom || VeevaConstant.STANDARD_FIELDS_TO_UPDATE.includes(key)) &&
                value.value !== null
            ) {
                values[key] = value.value;
            } 
            this.setChildObjectIfExist(field, objectInfo, key, value.value, values);
        });
        if (Object.keys(values).length) {
            values.type = this.apiName;
            // Don't set RecordTypeID if saving Master Record Type, otherwise SF will return ID invalid error
            if (!this.isMasterRecordType(this.recordTypeId)) {
                values.RecordTypeId = this.recordTypeId;
            }
        }
        return values;
    }

    getDataForClone(objectInfo, skipFields) {
        let values = {};
        Object.entries(this.fields).forEach(([key, value]) => {
            let field = objectInfo.getFieldInfo(key);
            if (field && field.createable && !skipFields.includes(key)) {
                if (field.custom || "RecordTypeId" === field.apiName) {
                    values[key] = value;
                    if (field.relationshipName) {
                        values[field.relationshipName] = this.fields[field.relationshipName];
                    }
                }
            }
        });
        return JSON.parse(JSON.stringify(values));
    }

    updateDefaultValuesForClone(objectInfo, fieldValues){
        Array.from(fieldValues.keys()).forEach((k) => {
            let field = objectInfo.getFieldInfo(k);
            if (field && field.createable) {
                this.setFieldValue(field, fieldValues.get(k));
            }
        });
    }

    getUpdatableValues(objectInfo) {
        let values = {};
        this.old = this.old || {};
        Object.entries(this.old).forEach(([key, value]) => {
            let newValue = this.rawValue(key);
            if (newValue !== value) {
                let field = objectInfo.getFieldInfo(key);
                if (
                    field && field.updateable &&
                    (field.custom || VeevaConstant.STANDARD_FIELDS_TO_UPDATE.includes(key))
                ) {
                    values[key] = newValue;
                }
                this.setChildObjectIfExist(field, objectInfo, key, newValue, values);
            }
        });
        if (Object.keys(values).length) {
            values.type = this.apiName;
            values.Id = this.id;
        }
        return values;
    }

    setChildObjectIfExist(field, objectInfo, key, newValue, values) {
        if (!field) {
            let childObject = objectInfo.getChildObjectInfo(key);
            if (childObject) {
                values[key] = newValue;
            }
        }
    }

    assignRandomId() {
        this.id = VeevaUtils.getRandomId();
    }

    get isLocked() {
        if (this.fields.Lock_vod__c) {
            return this.fields.Lock_vod__c.value;
        }
        return false;
    }

    isFieldSet(field) {
        return Boolean(this.fields[field] && this.fields[field].value);
    }

    isMasterRecordType(recordTypeId) {
        return recordTypeId === VeevaRecord.MASTER_RECORD_TYPE_ID;
    }
}