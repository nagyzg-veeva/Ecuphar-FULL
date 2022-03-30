public inherited sharing class VeevaGASSearchResults {
    
    private List<Account> accounts;
    private Map<Id, Account> accountMap;
    private List<Address_vod__c> addresses;
    private Map<Id, Address_vod__c> addressMap;
        
    public List<Account> getAccounts(){
        return this.accounts;
    }

    public void setAccounts(List<Account> accountList){
        this.accounts = accountList;
        this.accountMap = new Map<Id, Account>();
        for (Account account : accountList){
            this.accountMap.put(account.Id, account);
        }
    }

    public Map<Id, Account> getAccountMap(){
        return this.accountMap;
    }

    public List<Address_vod__c> getAddresses(){
        return this.addresses;
    }

    public void setAddresses(List<Address_vod__c> addressList){
        this.addresses = addressList;
        this.addressMap = new Map<Id, Address_vod__c>();
        for (Address_vod__c address : addressList){
            addressMap.put(address.Account_vod__c, address);
        }
    }

    public Map<Id, Address_vod__c> getAddressMap(){
        return this.addressMap;
    }
}