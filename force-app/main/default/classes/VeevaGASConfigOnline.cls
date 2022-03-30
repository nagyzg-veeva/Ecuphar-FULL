public inherited sharing class VeevaGASConfigOnline extends VeevaGASConfigBase {
    private List<String> BASE_ACCOUNT_FIELDS = new List<String> { 'Id', 'RecordTypeId.Id', 'RecordTypeId.Name', 'IsPersonAccount' };
    private List<String> BASE_ADDRESS_FIELDS = new List<String> { 'Id', 'Account_vod__c', 'Primary_vod__c', 'CreatedDate' };

    private List<String> ACCOUNT_RESULTSET_FIELDS = new List<String> { 'Name', 'Specialty_1_vod__c', 'Primary_Parent_vod__c.Name' };
    private List<String> ADDRESS_RESULTSET_FIELDS = new List<String> { 'Name', 'City_vod__c', 'State_vod__c', 'Zip_vod__c' };
    private String MAX_ROW_LIMIT = '100';

    public override List<String> getAccountObjectFields(){
        List<String> allConfiguredAccountFields = new List<String>();
        allConfiguredAccountFields.addAll(BASE_ACCOUNT_FIELDS);
        allConfiguredAccountFields.addAll(ACCOUNT_RESULTSET_FIELDS);
        Map<String, Schema.SObjectField> accountFieldsMap = Schema.SObjectType.Account.fields.getMap();
        List<String> allAccountObjectFields = getObjectQueryFields(allConfiguredAccountFields, accountFieldsMap, false);
        return allAccountObjectFields;
    }

    public override List<String> getAddressObjectFields(){
        List<String> allConfiguredAddressFields = new List<String>();
        allConfiguredAddressFields.addAll(BASE_ADDRESS_FIELDS);
        allConfiguredAddressFields.addAll(ADDRESS_RESULTSET_FIELDS);
        Map<String, Schema.SObjectField> addressFieldsMap = Schema.SObjectType.Address_vod__c.fields.getMap();
        List<String> allAddressObjectFields = getObjectQueryFields(allConfiguredAddressFields, addressFieldsMap, false);
        return allAddressObjectFields;
    }

    public override List<String> getAccountQueryFields(){
        List<String> allConfiguredAccountFields = new List<String>();
        allConfiguredAccountFields.addAll(BASE_ACCOUNT_FIELDS);
        allConfiguredAccountFields.addAll(ACCOUNT_RESULTSET_FIELDS);
        Map<String, Schema.SObjectField> accountFieldsMap = Schema.SObjectType.Account.fields.getMap();
        List<String> allAccountQueryFields = getObjectQueryFields(allConfiguredAccountFields, accountFieldsMap, true);
        return allAccountQueryFields;
    }

    public override List<String> getAddressQueryFields(){
        List<String> allConfiguredAddressFields = new List<String>();
        allConfiguredAddressFields.addAll(BASE_ADDRESS_FIELDS);
        allConfiguredAddressFields.addAll(ADDRESS_RESULTSET_FIELDS);
        Map<String, Schema.SObjectField> addressFieldsMap = Schema.SObjectType.Address_vod__c.fields.getMap();
        List<String> allAddressQueryFields = getObjectQueryFields(allConfiguredAddressFields, addressFieldsMap, true);
        return allAddressQueryFields;
    }

    public override String getMaxRowLimit(){
        return MAX_ROW_LIMIT;
    }

    public override List<Map<String, String>> getResultSetColumnInfo(){
        List<Map<String, String>> resultSetInfo = new List<Map<String, String>>();
        Map<String, Schema.SObjectField> accountFieldsMap = Schema.SObjectType.Account.fields.getMap();
        resultSetInfo.addAll(getResultSetFieldsInfo('Account', ACCOUNT_RESULTSET_FIELDS, accountFieldsMap));
        Map<String, Schema.SObjectField> addressFieldsMap = Schema.SObjectType.Address_vod__c.fields.getMap();
        resultSetInfo.addAll(getResultSetFieldsInfo('Address_vod__c', ADDRESS_RESULTSET_FIELDS, addressFieldsMap));
        return resultSetInfo;
    }
}