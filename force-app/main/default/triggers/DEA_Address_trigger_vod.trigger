trigger DEA_Address_trigger_vod on Address_vod__c bulk (after insert, after update) {
	new AddressLicenseEnforcingTrigger(
        Address_vod__c.DEA_vod__c,
        Address_vod__c.DEA_Status_vod__c,
        Address_vod__c.Network_DEA_Entity_ID_vod__c,
        'DEA', Trigger.new, Trigger.old)
        	.run();
}