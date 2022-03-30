/**
 * VeevaQueryReferenceFieldStrategy - An abstract class which should be used like an interface for various Reference Field Query Strategies.
 *
 * Salesforce currently does not support constants in interfaces so we will make this an abstract class
 * and define constants that can be shared between Strategy's.
 * 
 * DO NOT PLACE IMPLEMENTATION DETAILS IN THIS ABSTRACT CLASS
 */
public abstract class VeevaQueryReferenceFieldStrategy {

    public static final String COUNTRY_CODE_FIELD = 'Country_Code_vod__c';

    /**
     * Adds source reference fields to the query strategy to use when building the final VeevaQueryResultMap.
     * 
     * Validation will not be done of the source reference fields to see if they are reference fields.
     */
    public abstract void addSourceReferenceFieldToQuery(Schema.SObjectField sObjectFieldReference);

    /**
     * Builds a VeevaQueryResultMap using the passed in sObjectsToQueryFrom and source reference fields set via public method.
     *
     * Requires that sObjectsToQueryFrom is not null or empty otherwise Strategy may not build correct query for VeevaQueryResultMap.
     */
    public abstract VeevaQueryResultMap buildQueryResultWith(List<SObject> sObjectsToQueryFrom);
}