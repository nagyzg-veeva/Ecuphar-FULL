public with sharing class VeevaDynAttrConfigTriggerHandler {
    private boolean isExecuting = false;
    private integer batchSize = 0;

    public VeevaDynAttrConfigTriggerHandler(boolean isExecuting, integer size) {
        this.isExecuting = isExecuting;
        this.batchSize = size;
    }

    public void onBeforeUpdate(List<Dynamic_Attribute_Configuration_vod__c> originalDAConfig,
                               List<Dynamic_Attribute_Configuration_vod__c> newDAConfig) {
        VeevaDynAttrConfigActions.checkMultiSelectPicklistLength(newDAConfig);
        VeevaDynAttrConfigActions.checkChanges(originalDAConfig, newDAConfig);
    }

    public void onBeforeInsert(List<Dynamic_Attribute_Configuration_vod__c> newDAConfig) {
        VeevaDynAttrConfigActions.checkMultiSelectPicklistLength(newDAConfig);
    }
}