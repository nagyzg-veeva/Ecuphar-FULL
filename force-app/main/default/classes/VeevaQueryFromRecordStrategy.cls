/**
 * VeevaQueryFromRecordStrategy - Constructs a single query to retrieve Country_Code_vod__c values from source reference fields
 * and places the result in a VeevaQueryResultMap.
 *
 * This class builds a single SOQL queries using the source reference field added.
 * This Strategy should be used on new records that will be updated or already exist.
 */
public inherited sharing class VeevaQueryFromRecordStrategy extends VeevaQueryReferenceFieldStrategy {

    private final List<Schema.SObjectField> sourceReferenceFieldsToQuery;
    private final List<Schema.SObjectField> polymorphicSourceReferenceFieldsToQuery;
    private final Schema.SObjectType sObjectType;

    public VeevaQueryFromRecordStrategy(Schema.SObjectType sObjectType) {
        this.sourceReferenceFieldsToQuery = new List<Schema.SObjectField>();
        this.polymorphicSourceReferenceFieldsToQuery = new List<Schema.SObjectField>();
        this.sObjectType = sObjectType;
    }

    public override void addSourceReferenceFieldToQuery(Schema.SObjectField sObjectFieldReference) {
        Schema.DescribeFieldResult fieldDescribe = sObjectFieldReference.getDescribe();
        List<Schema.SObjectType> referencesTo = fieldDescribe.getReferenceTo();

        // we need to check to see if this field is polymorphic since this will affect the resulting query we create.
        // Polymorphic Reference Fields will have more than 1 referenceTo's.
        boolean isPolymorphicReferenceField = referencesTo.size() > 1;
        addSourceReferenceFieldToQuery(sObjectFieldReference, isPolymorphicReferenceField);
    }

    public override VeevaQueryResultMap buildQueryResultWith(List<SObject> sObjectsToQueryFrom) {
        VeevaQueryResultMap queryResult;
        // it's possible that field references have not been defined and it is also possible for
        // a customer to pass in a null sObjectType
        if (hasReferenceFields() && sObjectType != null) {
            queryResult = buildQueryResultUsingReferenceFieldsWith(sObjectsToQueryFrom);
        } else {
            // set queryResult to an empty VeevaQueryResultMap
            queryResult = new VeevaQueryResultMap();
        }
        return queryResult;
    }

    public VeevaQueryResultMap buildQueryResultUsingReferenceFieldsWith(List<SObject> sObjectsToQueryFrom) {
        VeevaQueryResultMap queryResult = new VeevaQueryResultMap();
        Map<Id, SObject> sObjectsToQueryFromMap = recordsById(sObjectsToQueryFrom);
        String queryString = generateQueryString(sObjectsToQueryFromMap.keySet());
        List<SObject> result = Database.query(queryString);
        if (result != null && !result.isEmpty()) {
            for(SObject record : result) {
                List<Schema.SObjectField> allSourceFields = new List<Schema.SObjectField>();
                allSourceFields.addAll(sourceReferenceFieldsToQuery);
                allSourceFields.addAll(polymorphicSourceReferenceFieldsToQuery);
                for (Schema.SObjectField sourceReferenceField : allSourceFields) {
                    // we must keep the key consistent with the SObjects passed in
                    SObject recordToUseAsKey = sObjectsToQueryFromMap.get(record.Id);
                    setQueryResultForFieldIfValueAvailable(queryResult, sourceReferenceField, record, recordToUseAsKey);
                }
            }
        }
        return queryResult;
    }

    /**
     * Checks that sourceReferenceFieldsToQuery and polymorphicSourceReferenceFieldsToQuery are not empty.
     */
    private boolean hasReferenceFields() {
        return !sourceReferenceFieldsToQuery.isEmpty() || !polymorphicSourceReferenceFieldsToQuery.isEmpty();
    }

    private Map<Id, SObject> recordsById(List<SObject> records) {
        Map<Id, SObject> objectsById = new Map<Id, SObject>();
        for (SObject record : records) {
            objectsById.put(record.Id, record);
        }
        return objectsById;
    }

    private void addSourceReferenceFieldToQuery(Schema.SObjectField sObjectFieldReference, boolean isPolymorphicReferenceField) {
        if (isPolymorphicReferenceField) {
            polymorphicSourceReferenceFieldsToQuery.add(sObjectFieldReference);
        } else {
            sourceReferenceFieldsToQuery.add(sObjectFieldReference);
        }
    }

    private String generateQueryString(Set<Id> ids) {
        String objectApiName = sObjectType.getDescribe().getName();
        String fieldsString = generateFieldsString();
        String queryString = String.format('SELECT Id, {0} FROM {1}', new List<String>{fieldsString, objectApiName});
        queryString += idFilterCriteria(ids);
        return queryString;
    }

    private void setQueryResultForFieldIfValueAvailable(VeevaQueryResultMap queryResult, Schema.SObjectField sourceReferenceField, SObject record, SObject recordAsKey) {
        SObject relationshipObject = record.getSObject(sourceReferenceField.getDescribe().getRelationshipName());
        if (relationshipObject != null) {
            Object value = relationshipObject.get(COUNTRY_CODE_FIELD);
            queryResult.put(sourceReferenceField, value, recordAsKey);
        }
    }

    /**
     * Reads the passed in Ids and generates a "WHERE ID IN (...)" part of the query string.
     * Also, verifies that all of the Ids passed in match the sObjectType.
     *
     * Note: id must not be null or empty and should be validated prior to this method call.
     */
    private String idFilterCriteria(Set<Id> ids) {
        Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
        String sObjectIdPrefix = objectDescribe.getKeyPrefix();
        List<String> idsWithSurroundingSingleQuotes = new List<String>();
        for (String recordId : ids) {
            if (recordId.startsWith(sObjectIdPrefix)) {
                idsWithSurroundingSingleQuotes.add('\'' + recordId + '\'');
            } else {
                // this means the ids passed in were not validated prior to being passed into strategy
                throw new VeevaQueryArgumentException('Expected Ids to be of the Object Type: ' + objectDescribe.getName());
            }
        }
        String commaSeparatedIds = String.join(idsWithSurroundingSingleQuotes, ', ');
        String filterCriteria = String.format(' WHERE ID IN ({0})', new List<String>{commaSeparatedIds});
        return filterCriteria;
    }

    private String generateFieldsString() {
        List<String> allFields = new List<String>();
        // we join all of the non-polymorphic fields first and then join the polymorphic fields
        // since the TYPEOF format must come second in the fields string
        allFields.addAll(sourceReferenceCountryCodeFieldsForQuery());
        allFields.addAll(typeOfOperationForPolymorphicReferenceFieldsForQuery());
        return String.join(allFields, ', ');
    }

    /**
     * Iterate through all of the source reference fields to query and format them in the
     * relationship field format: relationshipName.Country_Code_vod__c
     *
     * Returns a compiled list of all of the source reference fields in the relationship field format
     */
    private List<String> sourceReferenceCountryCodeFieldsForQuery() {
        List<String> commaSeparatedSourceCountryCodeFields = new List<String>();
        for (Schema.SObjectField sourceReferenceField : sourceReferenceFieldsToQuery) {
            String relationshipName = sourceReferenceField.getDescribe().getRelationshipName();
            String fieldWithReferenceToCountryCode = String.format('{0}.{1}', new List<String>{relationshipName, COUNTRY_CODE_FIELD});
            commaSeparatedSourceCountryCodeFields.add(fieldWithReferenceToCountryCode);
        }
        return commaSeparatedSourceCountryCodeFields;
    }

    /**
     * Iterate through all of the polymorphic reference fields and format them in the
     * TYPEOF format: TYPEOF relationshipName WHEN User THEN Country_Code_vod__c END
     *
     * We use this format since we only expect the field OwnerId to be polymorphic
     * and this may have User or Group as the possible type it is a reference to.
     * We will only retrieve the Country_Code_vod__c field if the polymorphic reference field
     * is pointing to a User record.
     *
     * Returns a compiled list of all of the polymorphic reference fields in the TYPEOF format
     */
    private List<String> typeOfOperationForPolymorphicReferenceFieldsForQuery() {
        List<String> commaSeparatedPolymorphicReferenceFields = new List<String>();
        for (Schema.SObjectField sourceReferenceField : polymorphicSourceReferenceFieldsToQuery) {
            String relationshipName = sourceReferenceField.getDescribe().getRelationshipName();
            String typeOfQueryForPolymorphicFields = String.format('TYPEOF {0} WHEN User THEN {1} END', new List<String>{relationshipName, COUNTRY_CODE_FIELD});
            commaSeparatedPolymorphicReferenceFields.add(typeOfQueryForPolymorphicFields);
        }
        return commaSeparatedPolymorphicReferenceFields;
    }
}