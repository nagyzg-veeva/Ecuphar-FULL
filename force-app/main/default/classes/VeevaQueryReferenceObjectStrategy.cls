/**
 * VeevaQueryReferenceObjectStrategy - Constructs a query to retrieve Country_Code_vod__c values from source reference fields
 * and places the result in a VeevaQueryResultMap.
 *
 * This class builds one or more SOQL queries that increase based on how many unique SObjects, derived from the SObjetType of the
 * source reference field added, we need to query from. This Strategy should be used on new records that will be inserted into Salesforce
 * since we cannot create a relationship query for records that do not exist yet.
 */
public inherited sharing class VeevaQueryReferenceObjectStrategy extends VeevaQueryReferenceFieldStrategy {

    private final List<Schema.SObjectType> objectReferencesToIgnore;
    private final List<Schema.SObjectField> sourceReferenceFields;
    private final Map<Schema.SObjectType, List<Schema.SObjectField>> referenceObjectsToSObjectFields;
    private Schema.SObjectType sObjectType;

    public VeevaQueryReferenceObjectStrategy(List<Schema.SObjectType> objectReferencesToIgnore) {
        this.objectReferencesToIgnore = objectReferencesToIgnore;
        this.sourceReferenceFields = new List<Schema.SObjectField>();
        this.referenceObjectsToSObjectFields = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
    }

    public override void addSourceReferenceFieldToQuery(Schema.SObjectField sObjectFieldReference) {
        this.sourceReferenceFields.add(sObjectFieldReference);
        addSourceReferenceFieldToObjectTypeMap(sObjectFieldReference);
    }

    public override VeevaQueryResultMap buildQueryResultWith(List<SObject> sObjectsToQueryFrom) {
        VeevaQueryResultMap queryResult = new VeevaQueryResultMap();
        Map<Schema.SObjectField, Map<String, List<SObject>>> valueToRecordKeysByReferenceField = groupRecordsByReferenceIdAndByReferenceField(sObjectsToQueryFrom);

        for (Schema.SObjectType referenceObject : referenceObjectsToSObjectFields.keySet()) {
            List<Schema.SObjectField> refFieldsForObjectType = referenceObjectsToSObjectFields.get(referenceObject);
            Set<String> idsForQuery = getIdsForQuery(refFieldsForObjectType, valueToRecordKeysByReferenceField);
            if (!idsForQuery.isEmpty()) {
                String queryString = generateQueryString(referenceObject, refFieldsForObjectType, idsForQuery);
                List<SObject> results = Database.query(queryString);
                updateQueryResultWithValuesFromResultUsingRecordKey(queryResult, results, refFieldsForObjectType, valueToRecordKeysByReferenceField);
            }
        }

        return queryResult;
    }

    /**
     * Adds source reference field to referenceObjectsToSObjectFields map.
     * This map contains the Schema.SObjectType => List<Schema.SObjectField> so we do not
     * repeat SOQL queries when we finally build the query.
     */
    private void addSourceReferenceFieldToObjectTypeMap(Schema.SObjectField sObjectFieldReference) {
        for (Schema.SObjectType referenceTo : sObjectFieldReference.getDescribe().getReferenceTo()) {
            if (!objectReferencesToIgnore.contains(referenceTo)) {
                List<Schema.SObjectField> fieldReferencesForSObject = referenceObjectsToSObjectFields.get(referenceTo);
                if (fieldReferencesForSObject == null) {
                    fieldReferencesForSObject = new List<Schema.SObjectField>();
                    this.referenceObjectsToSObjectFields.put(referenceTo, fieldReferencesForSObject);
                }
                fieldReferencesForSObject.add(sObjectFieldReference);
            }
        }
    }

    private Set<String> getIdsForQuery(List<Schema.SObjectField> refFieldsForObjectType,
                                        Map<Schema.SObjectField, Map<String, List<SObject>>> valueToRecordKeysByReferenceField) {
        Set<String> ids = new Set<String>();
        for (Schema.SObjectField refField : refFieldsForObjectType) {
            Map<String, List<SObject>> recordsByReferenceFieldValue = valueToRecordKeysByReferenceField.get(refField);
            ids.addAll(recordsByReferenceFieldValue.keySet());
        }
        return ids;
    }

    /**
     * Generates the Query string for the given referenceObjectType by using refFieldsForObjectType
     * and valueToRecordKeysByReferenceField. valueToRecordKeysByReferenceField contains the Ids we want to
     * filter our Query. refFieldsForObjectType contains the reference fields that were added and point to
     * this referenceObjectType.
     */
    private String generateQueryString(Schema.SObjectType referenceObjectType, List<Schema.SObjectField> refFieldsForObjectType, Set<String> ids) {
        String queryString = String.format('SELECT Id, {0} FROM {1}', new List<String>{COUNTRY_CODE_FIELD, referenceObjectType.getDescribe().getName()});
        queryString += idFilterCriteria(referenceObjectType, ids);
        return queryString;
    }

    /**
     * Reads the passed in Ids and generates a "WHERE ID IN (...)" part of the query string.
     * Also, verifies that all of the Ids passed in match the sObjectType.
     *
     * Note: id must not be null or empty and should be validated prior to this method call.
     */
    private String idFilterCriteria(Schema.SObjectType objectType, Set<String> ids) {
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        String sObjectIdPrefix = objectDescribe.getKeyPrefix();
        List<String> idsWithSurroundingSingleQuotes = new List<String>();
        for (String recordId : ids) {
            idsWithSurroundingSingleQuotes.add('\'' + recordId + '\'');
        }
        String commaSeparatedIds = String.join(idsWithSurroundingSingleQuotes, ', ');
        String filterCriteria = String.format(' WHERE ID IN ({0})', new List<String>{commaSeparatedIds});
        return filterCriteria;
    }

    /**
     * Iterate through all of the refFieldsForObjectType and set the Country_Code_vod__c value in the queryResult
     * using the recordKeys stored in valueToRecordKeysByReferenceField and the individual refField in refFieldsForObjectType.
     */
    private void updateQueryResultWithValuesFromResultUsingRecordKey(VeevaQueryResultMap queryResult, List<SObject> results, List<Schema.SObjectField> refFieldsForObjectType,
                                                                        Map<Schema.SObjectField, Map<String, List<SObject>>> valueToRecordKeysByReferenceField) {
        Map<String, SObject> resultsById = getRecordsById(results);
        for (Schema.SObjectField refField : refFieldsForObjectType) {
            Map<String, List<SObject>> recordKeysByValue = valueToRecordKeysByReferenceField.get(refField);
            for (String resultId : resultsById.keySet()) {
                updateQueryResultWithValueForRefFieldUsingRecordKeys(queryResult, refField, resultId, resultsById, recordKeysByValue);
            }
        }
    }

    private void updateQueryResultWithValueForRefFieldUsingRecordKeys(VeevaQueryResultMap queryResult, Schema.SObjectField refField, String resultId,
                                                                        Map<String, SObject> resultsById, Map<String, List<SObject>> recordKeysByValue) {
        Object countryCodeValue = resultsById.get(resultId).get(COUNTRY_CODE_FIELD);
        List<SObject> recordKeys = recordKeysByValue.get(resultId);
        if (recordKeys != null) {
            for (SObject recordKey : recordKeys) {
                queryResult.put(refField, countryCodeValue, recordKey);
            }
        }
    }

    /**
     * Takes a list of records and returns a map of id to record.
     * Note: We return a string here instead of the Id type.
     */
    private Map<String, SObject> getRecordsById(List<SObject> records) {
        Map<String, SObject> objectsById = new Map<String, SObject>();
        for (SObject record : records) {
            objectsById.put(record.Id, record);
        }
        return objectsById;
    }

    /**
     * Iterates through all sourceReferenceFields and groups the records passed in by reference field id and reference field
     *
     * A Map<Schema.SObjectField, Map<String, List<SObject>> is returned, where the value for this map is a grouping of reference id value to records.
     */
    private Map<Schema.SObjectField, Map<String, List<SObject>>> groupRecordsByReferenceIdAndByReferenceField(List<SObject> records) {
        Map<Schema.SObjectField, Map<String, List<SObject>>>  valueToRecordByReferenceField = new Map<Schema.SObjectField, Map<String, List<SObject>>> ();

        for (Schema.SObjectField field : sourceReferenceFields) {
            String fieldName = field.getDescribe().getName();
            Map<String, List<SObject>> recordKeysByValueForField = getRecordsByValueForFieldOrInsertNew(field, valueToRecordByReferenceField);

            for (SObject record : records) {
                Object referenceIdValue = record.get(fieldName);
                if (referenceIdValue != null && isNotObjectReferenceToIgnore(referenceIdValue.toString())) {
                    List<SObject> recordKeysForValue = getRecordsOrInsertNew(referenceIdValue.toString(), recordKeysByValueForField);
                    recordKeysForValue.add(record);
                }
            }
        }
        return valueToRecordByReferenceField;
    }

    private boolean isNotObjectReferenceToIgnore(String referenceIdValue) {
        boolean idToIgnore = false;
        for (Integer i = 0; !idToIgnore && i < objectReferencesToIgnore.size(); i++) {
            Schema.SObjectType objectReferenceToIgnore = objectReferencesToIgnore.get(i);
            idToIgnore = referenceIdValue.startsWith(objectReferenceToIgnore.getDescribe().getKeyPrefix());
        }


        return !idToIgnore;
    }

    /**
     * Checks to see if there is a value for the field, if not it will create a map and insert it into the larger map.
     *
     * A map will be returned that is the value for this field.
     */
    private Map<String, List<SObject>> getRecordsByValueForFieldOrInsertNew(Schema.SObjectField field, Map<Schema.SObjectField, Map<String, List<SObject>>> valueToRecordKeysByReferenceField) {
        Map<String, List<SObject>> recordsByValue = valueToRecordKeysByReferenceField.get(field);
        if (recordsByValue == null) {
            recordsByValue = new  Map<String, List<SObject>>();
            valueToRecordKeysByReferenceField.put(field, recordsByValue);
        }
        return recordsByValue;
    }

    /**
     * Checks to see if there is a referenceIdValue in the map for the provided referenceIdValue, if not a list will be created and inserted.
     *
     * A list will be returned that is the list of records for the value passed in.
     */
    private List<SObject> getRecordsOrInsertNew(String referenceIdValue, Map<String, List<SObject>> valueToRecordKeysByReferenceField) {
        List<SObject> records = valueToRecordKeysByReferenceField.get(referenceIdValue);
        if (records == null) {
            records = new List<SObject>();
            valueToRecordKeysByReferenceField.put(referenceIdValue, records);
        }
        return records;
    }
}