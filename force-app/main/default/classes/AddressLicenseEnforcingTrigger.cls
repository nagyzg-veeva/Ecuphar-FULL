public class AddressLicenseEnforcingTrigger {

    private Schema.SObjectField licenseField; // must be a String field
    private Schema.SObjectField statusField; // must be a String field
    private Schema.SObjectField entityIdField; // must be a String field
    private String enforcingAgent; // OH, DEA, etc
    private Address_vod__c[] newAddresses;
    private Address_vod__c[] oldAddresses; // oldAddresses non-null only for updates

    public AddressLicenseEnforcingTrigger(
        Schema.SObjectField licenseField, Schema.SObjectField statusField, 
        Schema.SObjectField entityIdField, String enforcingAgent,
	    Address_vod__c[] newAddresses, Address_vod__c[] oldAddresses) {
            this.licenseField = licenseField;
            this.statusField = statusField;
            this.entityIdField = entityIdField;
            this.enforcingAgent = enforcingAgent;
            this.newAddresses = newAddresses;
            this.oldAddresses = oldAddresses;
    }
    
    public void run() {
        if (!isEnabled()) {
            return;
        }
        
        Set<Id> changedAddresses = new Set<Id>();
	    Set<String> changedLicenses = new Set<String>();
    	Set<Id> accounts = new Set<Id>();
    	
	    // Collect addresses with new / modified license values
	    for (Integer i = newAddresses.size() - 1; i >= 0; i--) {
    	    Address_vod__c addr_new = newAddresses[i];
            String license = (String) addr_new.get(licenseField);
            String status = (String) addr_new.get(statusField);
        	
	        if (license == null || license.length() == 0) {
    	        // Skip this address since the license field isn't set
	            continue;
    	    }
        
        	if (!('Valid_vod'.equals(status))) {
            	// We're only concerned about valid licenses
	            continue;
    	    }
        
        	// Check for changed/added valid licenses and save the information
	        if (oldAddresses != null) {
				Address_vod__c addr_old = oldAddresses[i];
                String oldLicense = (String) addr_old.get(licenseField);
                String oldStatus = (String) addr_old.get(statusField);
	            if (license.equals(oldLicense) && 'Valid_vod'.equals(oldStatus)) {
    	            continue;
            	}
	        }

            changedLicenses.add(license);
	        changedAddresses.add(addr_new.Id);
        	accounts.add(addr_new.Account_vod__c);
	    }

        System.debug('Found ' + changedAddresses.size() + ' changed ' + enforcingAgent + ' addresses');
	    if (changedAddresses.size() == 0) {
    	    return;
        }
    
    	// Find addresses that have matching license values
	    List<Address_vod__c> addrToClear = new List<Address_vod__c>();
        Schema.DescribeFieldResult entityDescribe = entityIdField.getDescribe();
        String licenseFieldName = licenseField.getDescribe().getLocalName();
        String statusFieldName = statusField.getDescribe().getLocalName();
        List<Address_vod__c> allAddresses = 
            Database.query('Select Id From Address_vod__c Where Account_vod__c IN :accounts ' +
                           'And ' + licenseFieldName + ' In :changedLicenses ' + 
                           'And ' + statusFieldName + '=\'Valid_vod\'');
	    for (Address_vod__c addrToCheck : allAddresses) {
	        if (changedAddresses.contains(addrToCheck.Id)) {
				// It found the one that's being changed, skip
                System.debug('Updated address is also the new one');
        	    continue;
	        }
            
        	// Add to the set of addresses that will be cleared
        	addrToCheck.put(statusField, 'Invalid_vod');

        	if (entityDescribe != null && entityDescribe.isUpdateable()) {
                addrToCheck.put(entityIdField, null);
	        }
    	    addrToClear.add(addrToCheck);
	    }
    
    	if (addrToClear.size() == 0) {
        	System.debug('No matching ' + enforcingAgent + ' license values found');
	        return;
    	}
    
	    // Start clearing addresses
		try {
        	update addrToClear;
	    } catch (System.DmlException e) {
    	    Integer numErrors = e.getNumDml();
        	String error = '';
	        for (Integer i = 0; i < numErrors; i++) {
    	        Id thisId = e.getDmlId(i);
        	    if (thisId != null) {
            	    error += thisId + ' - ' + e.getDmlMessage(i) + '\n';
	            }
	        }
	        System.debug('Error handling ' + enforcingAgent + ' addr updates:' + error);
    	}
    }
    
    private boolean isEnabled() {
    	String debugPrefix = 'Address license trigger for ' + enforcingAgent + ' early exit - ';
    	// check that the network feature is even enabled before running other queries
    	if (!VOD_Utils.isNetworkEnabled()) {
        	System.debug(debugPrefix + 'network custom master mode not enabled');
        	return false;
    	}
		
    	// Check that the current user is the network integration user before attempting any address cleanup
    	String userId = UserInfo.getUserId();
		return VOD_Utils.isNetworkIntegrationUser(userId);
    }
}