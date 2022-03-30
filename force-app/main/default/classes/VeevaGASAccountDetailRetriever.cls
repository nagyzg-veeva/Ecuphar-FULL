public with sharing class VeevaGASAccountDetailRetriever {

    private List<String> accountFieldNames;
    private List<String> addressFieldNames;
    private List<String> childAccontFieldNames;

    public VeevaGASAccountDetailRetriever() {
        this.accountFieldNames = getAllFields(Account.getSObjectType().getDescribe());
        this.addressFieldNames = getAllFields(Address_vod__c.getSObjectType().getDescribe());
        this.childAccontFieldNames = getAllFields(Child_Account_vod__c.getSObjectType().getDescribe());
    }

    public VeevaGASAccountWithDetails retrieveAccountAndRelatedRecords(String accountId, List<String> parentAccountIds) {
        Set<String> accountIdsToQuery = new Set<String>();
        accountIdsToQuery.add(accountId);
        accountIdsToQuery.addAll(parentAccountIds);

        List<Account> accountAndParentAccounts = Database.query('SELECT ' + String.join(accountFieldNames, ',') + ' FROM Account WHERE Id in :accountIdsToQuery');
        Map<Id, Account> accountAndParentAccountsById = new Map<Id, Account>(accountAndParentAccounts);
        List<Address_vod__c> accountRelatedAddresses = Database.query('SELECT ' + String.join(addressFieldNames, ',') + ' FROM Address_vod__c WHERE Account_vod__c = :accountIdsToQuery');
        // We will limit the result set to 1000 so we do not run into potential heap size issues
        List<Child_Account_vod__c> accountRelatedChildAccounts = Database.query('SELECT ' + String.join(childAccontFieldNames, ',') + ' FROM Child_Account_vod__c WHERE Child_Account_vod__c = :accountId OR Parent_Account_vod__c = :accountId LIMIT 1000');
        Integer relatedChildAccountCount = accountRelatedChildAccounts.size();
        // Check to see if we are missing additional related child account records
        if (relatedChildAccountCount >= 1000) {
            relatedChildAccountCount = [SELECT COUNT() FROM Child_Account_vod__c WHERE Child_Account_vod__c = :accountId OR Parent_Account_vod__c = :accountId];
        }

        Account account = accountAndParentAccountsById.get(accountId);
        List<Account> parentAccounts = getParentAccounts(accountAndParentAccountsById, parentAccountIds);
        boolean includedAllRecords = relatedChildAccountCount == accountRelatedChildAccounts.size();

        return new VeevaGASAccountWithDetails(account, accountRelatedAddresses, accountRelatedChildAccounts, parentAccounts, includedAllRecords);
    }

    private List<Account> getParentAccounts(Map<Id, Account> accountAndParentAccountsById, List<String> parentAccountIds) {
        List<Account> parentAccounts = new List<Account>();
        for (String parentAccountId : parentAccountIds) {
            parentAccounts.add(accountAndParentAccountsById.get(parentAccountId));
        }
        return parentAccounts;
    }

    private List<String> getAllFields(Schema.DescribeSObjectResult describe) {
        return new List<String>(describe.fields.getMap().keySet());
    }
}