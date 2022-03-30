public inherited sharing class VeevaQueryResultMap {
    private Map<SObject, Map<Schema.SObjectField, Object>> sourceReferenceFieldToValuesByRecord;

    public VeevaQueryResultMap() {
        this.sourceReferenceFieldToValuesByRecord = new Map<SObject, Map<Schema.SObjectField, Object>>();
    }

    public Object get(Schema.SObjectField sourceReferenceField, SObject recordKey) {
        Map<Schema.SObjectField, Object> sourceReferenceFieldToValues = sourceReferenceFieldToValuesByRecord.get(recordKey);
        Object value;
        if (sourceReferenceFieldToValues == null) {
            value = null;
        } else {
            value = sourceReferenceFieldToValues.get(sourceReferenceField);
        }
        return value;
    }

    public void put(Schema.SObjectField sourceReferenceField, Object value, SObject recordKey) {
        Map<Schema.SObjectField, Object> sourceReferenceFieldToValues = sourceReferenceFieldToValuesByRecord.get(recordKey);
        if (sourceReferenceFieldToValues == null) {
            sourceReferenceFieldToValues = new Map<Schema.SObjectField, Object>();
            sourceReferenceFieldToValuesByRecord.put(recordKey, sourceReferenceFieldToValues);
        }
        sourceReferenceFieldToValues.put(sourceReferenceField, value);
    }

    public Set<SObject> getAllRecords() {
        return sourceReferenceFieldToValuesByRecord.keySet();
    }
}