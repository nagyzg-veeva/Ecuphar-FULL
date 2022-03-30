/**
 * VeevaCountryQueryBuilder - Builds a VeevaQueryResultMap based on the sObjectFieldReferences added and the SObjects to Query from.
 */
public inherited sharing class VeevaCountryQueryBuilder {

    private VeevaQueryReferenceFieldStrategy queryStrategy;

    public VeevaCountryQueryBuilder(VeevaQueryReferenceFieldStrategy queryStrategy) {
        this.queryStrategy = queryStrategy;
    }

    public VeevaCountryQueryBuilder addSourceReferenceFieldToQuery(Schema.SObjectField sObjectFieldReference) {
        Schema.DescribeFieldResult fieldDescribe = sObjectFieldReference.getDescribe();
        List<Schema.SObjectType> referencesTo = fieldDescribe.getReferenceTo();
        if (isValidSourceReferenceFieldToAdd(sObjectFieldReference, referencesTo)) {
            queryStrategy.addSourceReferenceFieldToQuery(sObjectFieldReference);
        }
        return this;
    }

    public VeevaQueryResultMap buildQueryResultWith(List<SObject> sObjectsToQueryFrom) {
        VeevaQueryResultMap queryResult;
        if (sObjectsToQueryFrom != null && !sObjectsToQueryFrom.isEmpty()) {
            try {
                queryResult = queryStrategy.buildQueryResultWith(sObjectsToQueryFrom);
            } catch (VeevaQueryArgumentException ex) {
                // we do not want to propagate this exception forward, instead we will return an "empty" result
                // System.debug(LoggingLevel.WARN, 'Could not build VeevaQueryResultMap due to: ' + ex.getMessage());
                queryResult = new VeevaQueryResultMap();
            }
        } else {
            queryResult = new VeevaQueryResultMap();
        }
        return queryResult;
    }

    /**
     * Validates that the source reference field to be added is a reference field and a reference field which contains a field called
     * "Country_Code_vod__c".
     */
    private boolean isValidSourceReferenceFieldToAdd(Schema.SObjectField sObjectFieldReference, List<Schema.SObjectType> referencesTo) {
        boolean validSourceFieldToAdd = true;
        if (referencesTo == null || referencesTo.isEmpty()) {
            validSourceFieldToAdd = false;
        } else {
            boolean referencedObjectsContainsCountryCodeField = referenceToObjectsContainsCountryCodeField(referencesTo);
            if (!referencedObjectsContainsCountryCodeField) {
                validSourceFieldToAdd = false;
            }
        }
        return validSourceFieldToAdd;
    }

    /**
     * Checks that at least one of the referencesTo contains the field "Country_Code_vod__c".
     * This is important since we care about retrieving the Country_Code_vod value for the ultimate VeevaQueryResultMap.
     */
    private boolean referenceToObjectsContainsCountryCodeField(List<Schema.SObjectType> referencesTo) {
        boolean referencedObjectsContainsCountryCodeField = false;
        for (Schema.SObjectType sObjectType : referencesTo) {
            Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            referencedObjectsContainsCountryCodeField = referencedObjectsContainsCountryCodeField || fieldMap.containsKey(VeevaQueryReferenceFieldStrategy.COUNTRY_CODE_FIELD);
        }
        return referencedObjectsContainsCountryCodeField;
    }
}