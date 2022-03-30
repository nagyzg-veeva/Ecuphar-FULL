trigger OH_Address_trigger_vod on Address_vod__c bulk (after insert, after update) {
    new AddressLicenseEnforcingTrigger(
        Address_vod__c.State_Distributor_vod__c,
        Address_vod__c.State_Distributor_Status_vod__c,
        Address_vod__c.Network_Distributor_Entity_ID_vod__c,
        'OH', Trigger.new, Trigger.old)
        	.run();
}