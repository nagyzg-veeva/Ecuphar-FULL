public inherited sharing class VeevaAddressDeletionFilter {

    private static final Set<String> ADDRESS_STATUSES_TO_ALWAYS_KEEP = new Set<String>{'Valid_vod', 'Under_Review_vod'};

    private final boolean filterInactive;
    private final Decimal addressDeletionMode;

    public VeevaAddressDeletionFilter(Network_Settings_vod__c networkSettings) {
        this.filterInactive = networkSettings.FILTER_INACTIVE_NETWORK_RECORDS_vod__c == 1;
        this.addressDeletionMode = networkSettings.NETWORK_ADDRESS_DELETION_PROCESS_vod__c;
    }


    /**
     * Creates a List of Addresses that are considered Deleteable, this decision is made using the necessary
     * custom settings values.
     * 
     * Addresses require Account_vod__c, Customer_Master_Status_vod__c, and Primary_vod__c fields.
     */
    public List<Address_vod__c> getDeleteableAddresses(List<Address_vod__c> addresses) {
        List<Address_vod__c> deleteableAddresses;

        if (addressDeletionMode == 0) {
            // do not delete addresses if address deletion mode is 0
            deleteableAddresses = new List<Address_vod__c>();
        } else if (addressDeletionMode == 1) {
            deleteableAddresses = getDeleteableAddressesForMode1(addresses);
        } else if (addressDeletionMode == 2) {
            deleteableAddresses = getDeleteableAddressesForMode2(addresses);
        } else {
            // delete nothing if an invalid mode is selected
            deleteableAddresses = new List<Address_vod__c>();
        }

        return deleteableAddresses;
    }


    private List<Address_vod__c> getDeleteableAddressesForMode1(List<Address_vod__c> addresses) {
        List<Address_vod__c> deleteableAddresses = new List<Address_vod__c>();

        for (Address_vod__c address : addresses) {
            String customerMasterStatus = address.Customer_Master_Status_vod__c;
            if (!shouldKeepAddressBasedOnStatus(customerMasterStatus)) {
                deleteableAddresses.add(address);
            }
        }

        return deleteableAddresses;
    }


    private List<Address_vod__c> getDeleteableAddressesForMode2(List<Address_vod__c> addresses) {
        List<Address_vod__c> deleteableAddresses = new List<Address_vod__c>();

        // Map<AccountIds, List<AddressIds>> acctIdToAddrList
        Map<Id, List<Id>> acctIdToAddrIdList = getAccountToAddressMap(addresses);

        for (Address_vod__c address : addresses) {
            String customerMasterStatus = address.Customer_Master_Status_vod__c;
            if (!isPrimaryOrLastAddressForAccount(address, acctIdToAddrIdList) && !shouldKeepAddressBasedOnStatus(customerMasterStatus)) {
                deleteableAddresses.add(address);
                removeAddressFromAccountIdToAddressesMap(address, acctIdToAddrIdList);
            }
        }

        return deleteableAddresses;
    }

    private boolean isPrimaryOrLastAddressForAccount(Address_vod__c address, Map<Id, List<Id>> acctIdToAddrIdList) {
        boolean isPrimary = address.Primary_vod__c;
        List<Id> addressIdsForAccount = acctIdToAddrIdList.get(address.Account_vod__c);

        if (addressIdsForAccount == null) {
            System.debug(LoggingLevel.ERROR, 'Addresses for Account ' + address.Account_vod__c + ' should not be null. Something went wrong');
        }

        return isPrimary 
            || (addressIdsForAccount != null && addressIdsForAccount.size() == 1);
            
    }

    private boolean shouldKeepAddressBasedOnStatus(String customerMasterStatus) {
        return ADDRESS_STATUSES_TO_ALWAYS_KEEP.contains(customerMasterStatus)
            || (!filterInactive && 'Inactive_vod'.equals(customerMasterStatus));
    }

    private void removeAddressFromAccountIdToAddressesMap(Address_vod__c address, Map<Id, List<Id>> acctIdToAddrIdList) {
        List<Id> addressIdsForAccount = acctIdToAddrIdList.get(address.Account_vod__c);
        if (addressIdsForAccount != null) {
            Integer indexOfAddressToRemove = addressIdsForAccount.indexOf(address.Id);
            addressIdsForAccount.remove(indexOfAddressToRemove);
        } else {
            System.debug(LoggingLevel.ERROR, 'Unable to find Address for Account ' + address.Account_vod__c);
        }
    }

    /**
     *  Creates a map of Account Id to a List of Address Ids.
     */
    private Map<Id, List<Id>> getAccountToAddressMap(List<Address_vod__c> addresses) {
        Map<Id, List<Id>> acctIdToAddrIdList = new Map<Id, List<Id>>();

        List<Id> accountIds = getAccountIdsFromAddresses(addresses);
        List<SObject> accountsListWithAddresses = [SELECT Id, (SELECT Id FROM Address_vod__r ORDER BY CreatedDate DESC) FROM Account WHERE Id = :accountIds];
        

        for (SObject accountWithAddresses : accountsListWithAddresses) {
            List<Id> addressIds = new List<Id>();
            for (SObject address : accountWithAddresses.getSObjects('Address_vod__r')) {
                addressIds.add(address.Id);
            }
            acctIdToAddrIdList.put(accountWithAddresses.Id, addressIds);
        }

        return acctIdToAddrIdList;
    }

    private List<Id> getAccountIdsFromAddresses(List<Address_vod__c> addresses) {
        List<Id> accountIds = new List<Id>();
        for (Address_vod__c address : addresses) {
            accountIds.add(address.Account_vod__c);
        }
        return accountIds;
    }

}