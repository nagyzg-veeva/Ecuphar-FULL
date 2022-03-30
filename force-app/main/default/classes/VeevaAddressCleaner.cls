public inherited sharing class VeevaAddressCleaner {

    private final VeevaAddressDeletionFilter addressDeletionFilter;
    private final boolean networkModeSet;

    public VeevaAddressCleaner(VeevaAddressDeletionFilter addressDeletionFilter, Network_Settings_vod__c networkSettings) {
        this.addressDeletionFilter = addressDeletionFilter;
        this.networkModeSet = networkSettings.NETWORK_CUSTOMER_MASTER_MODE_vod__c == 1;
    }

    /**
     * Deletes addresses which are considered deleteable by the VeevaAddressDeletionFilter.
     * 
     * Addresses require Account_vod__c, Customer_Master_Status_vod__c, and Primary_vod__c fields.
     */
    public List<Database.DeleteResult> deleteAddresses(List<Address_vod__c> addresses) {        
        List<Database.DeleteResult> deleteResults;
        if (networkModeSet) {
            // use address deletion filter if network mode is 1
            List<Address_vod__c> addressesToDelete = addressDeletionFilter.getDeleteableAddresses(addresses);
            deleteProvidedAddresses(addressesToDelete);
        } else {
            // Delete all addresses
            deleteProvidedAddresses(addresses);
        }
        return deleteResults;
    }

    private List<Database.DeleteResult> deleteProvidedAddresses(List<Address_vod__c> addressesToDelete) {
        List<Database.DeleteResult> deleteResults;
        if (!addressesToDelete.isEmpty()) {
            // Currently only VEEVA_CHILD_ACCOUNT_ADDRESS_CLEAN trigger calls this method and does not do anything with the DeleteResults returned
            // this is done to keep the logic consistent with prior logic in the trigger since it has a try/catch surrounding the method call before deleting.
            // When this logic is updated we will want to change this hard-coded "true" to "false" so the returned DeleteResults are actually utilized.
            deleteResults = Database.delete(addressesToDelete, true);
        } else {
            deleteResults = new List<Database.DeleteResult>();
        }
        return deleteResults;
    }
}