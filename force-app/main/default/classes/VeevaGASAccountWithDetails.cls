public inherited sharing class VeevaGASAccountWithDetails {
    public Account account { get; private set; }
    public List<Address_vod__c> addresses { get; private set; }
    public List<Child_Account_vod__c> childAccounts { get; private set; }
    public List<Account> parentAccounts { get; private set; }
    public boolean includedAllRecords { get; private set; }

    public VeevaGASAccountWithDetails(Account account, List<Address_vod__c> addresses, List<Child_Account_vod__c> childAccounts, List<Account> parentAccounts, boolean includedAllRecords) {
        this.account = account;
        this.addresses = addresses != null ? addresses: new List<Address_vod__c>();
        this.childAccounts = childAccounts != null ? childAccounts : new List<Child_Account_vod__c>();
        this.parentAccounts = parentAccounts != null ? parentAccounts : new List<Account>();
        this.includedAllRecords = includedAllRecords;
    }

    public Map<String, Object> getAccountAsMap() {
        return getSObjectAsMap(account, Account.getSObjectType().getDescribe());
    }

    public List<Map<String, Object>> getAddressAsMapList() {
        return getSObjectAsMapList(addresses, Address_vod__c.getSObjectType().getDescribe());
    }

    public List<Map<String, Object>> getParentAccountsAsMapList() {
        return getSObjectAsMapList(parentAccounts, Account.getSObjectType().getDescribe());
    }

    public List<Map<String, Object>> getChildAccountsAsMapList() {
        return getSObjectAsMapList(childAccounts, Child_Account_vod__c.getSObjectType().getDescribe());
    }

    private Map<String, Object> getSObjectAsMap(SObject record, Schema.DescribeSObjectResult describe) {
        Map<String, Object> sObjectAsMap = new Map<String, Object>();
        sObjectAsMap.putAll(record.getPopulatedFieldsAsMap());
        sObjectAsMap.put('_type', describe.getName());
        return sObjectAsMap;
    }

    private List<Map<String, Object>> getSObjectAsMapList(List<SObject> records, Schema.DescribeSObjectResult describe) {
        List<Map<String, Object>> sObjectMapList = new List<Map<String, Object>>();
        for (Sobject record : records) {
            sObjectMapList.add(getSObjectAsMap(record, describe));
        }
        return sObjectMapList;
    }
}