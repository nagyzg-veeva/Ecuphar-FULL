public with sharing class VeevaDynamicAttributeTriggerHandler {

    // queue up last active records per account + dac across the entire transaction
    // so the final after insert / update pass can clean up the active states
    private static Map<String, Dynamic_Attribute_vod__c> lastActives = new Map<String, Dynamic_Attribute_vod__c>();
    // queue up all Multi-Select Picklist records per account + dac across the entire transaction
    // so the final after insert / update pass can delete the inactive states
    private static Map<String, Dynamic_Attribute_vod__c> multiSelectRecords = new Map<String, Dynamic_Attribute_vod__c>();
    // "sticky" flag that knows we're already in the process of handling
    // bookkeeping for the last inactive DA so we don't start doing other updates
    private static boolean alreadyHandlingActiveStates = false;

    private boolean isExecuting = false;
    private integer batchSize = 0;

    public VeevaDynamicAttributeTriggerHandler(boolean isExecuting, integer size) {
        this.isExecuting = isExecuting;
        this.batchSize = size;
    }

    public void onBeforeInsert(List<Dynamic_Attribute_vod__c> newDAs) {
        if (!alreadyHandlingActiveStates) {
            VeevaDynamicAttributeActions.migratePicklistValues(newDAs);
            VeevaDynamicAttributeActions.groupLastActives(newDAs, lastActives);
            VeevaDynamicAttributeActions.groupMultiSelectConfigs(newDAs, multiSelectRecords);
        }
    }

    public void onBeforeUpdate(List<Dynamic_Attribute_vod__c> newDAs, List<Dynamic_Attribute_vod__c> originalDAs) {
        preventChangingRecordType(newDAs, originalDAs);
        if (!alreadyHandlingActiveStates) {
            VeevaDynamicAttributeActions.migratePicklistValues(newDAs);
            VeevaDynamicAttributeActions.groupLastActives(newDAs, lastActives);
            VeevaDynamicAttributeActions.groupMultiSelectConfigs(newDAs, multiSelectRecords);
        }
    }

    public void onAfterInsert(List<Dynamic_Attribute_vod__c> newDAs) {
        if (!alreadyHandlingActiveStates) {
            alreadyHandlingActiveStates = true;
            VeevaDynamicAttributeActions.maintainLastActives(lastActives);
            VeevaDynamicAttributeActions.deleteInactiveDynamicAttributesRecord(multiSelectRecords);
        }
        alreadyHandlingActiveStates = false;
    }

    public void onAfterUpdate(List<Dynamic_Attribute_vod__c> newDAs, List<Dynamic_Attribute_vod__c> originalDAs) {
        if (!alreadyHandlingActiveStates) {
            alreadyHandlingActiveStates = true;
            VeevaDynamicAttributeActions.maintainLastActives(lastActives);
            VeevaDynamicAttributeActions.deleteInactiveDynamicAttributesRecord(multiSelectRecords);
        }
        alreadyHandlingActiveStates = false;
    }

    private void preventChangingRecordType(List<Dynamic_Attribute_vod__c> newDAs, List<Dynamic_Attribute_vod__c> originalDAs) {
        VeevaDynamicAttributeActions.preventChangingRecordType(newDAs, originalDAs);
    }
}