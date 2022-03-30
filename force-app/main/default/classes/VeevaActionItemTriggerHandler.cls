public without sharing class VeevaActionItemTriggerHandler extends  VeevaAccountPlanSharingTriggerHandler {
    public void onBeforeInsert(List<Action_Item_vod__c> newActionItems) {
        // stamp the completed date and completed user
        VeevaActionItemLogic.actionItemStamping(newActionItems);
    }
    public void onBeforeUpdate( List<Action_Item_vod__c> newActionItems, List<Action_Item_vod__c> oldActionItems, Map<ID, Action_Item_vod__c> newActionItemsMap , Map<ID, Action_Item_vod__c> oldActionItemsMap ) {
        // stamp the completed date and completed user
        VeevaActionItemLogic.actionItemStamping(newActionItems);
    }

    public void onBeforeDelete (List<Action_Item_vod__c> oldActionItems, Map<ID, Action_Item_vod__c> oldActionItemsMap) {
        // place holder
    }

    public void onAfterInsert(List<Action_Item_vod__c> newActionItems) {
        // sharing rules
        super.onAfterInsert(newActionItems, 'Action_Item_vod__c');
    }
    public void onAfterUpdate( List<Action_Item_vod__c> newActionItems, List<Action_Item_vod__c> oldActionItems, Map<ID, Action_Item_vod__c> newActionItemsMap , Map<ID, Action_Item_vod__c> oldActionItemsMap ) {
        // sharing rules
        super.onAfterUpdate(newActionItems, 'Action_Item_vod__c', oldActionItemsMap);
    }

    public void onAfterDelete(List<Action_Item_vod__c> oldActionItems, Map<ID, Action_Item_vod__c> oldActionItemsMap) {
        // place holder
    }

}