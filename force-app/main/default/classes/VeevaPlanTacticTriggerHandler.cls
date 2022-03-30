public without sharing class VeevaPlanTacticTriggerHandler extends VeevaAccountPlanSharingTriggerHandler{
    public void onBeforeInsert(List<Plan_Tactic_vod__c> newPlanTactics) {
        // place holder
    }
    public void onBeforeUpdate( List<Plan_Tactic_vod__c> newPlanTactics, List<Plan_Tactic_vod__c> oldPlanTactics, Map<ID, Plan_Tactic_vod__c> newPlanTacticsMap , Map<ID, Plan_Tactic_vod__c> oldPlanTacticsMap ) {
        // place holder
    }

    public void onBeforeDelete (List<Plan_Tactic_vod__c> oldPlanTactics) {
        // place holder
    }

    public void onAfterInsert(List<Plan_Tactic_vod__c> newPlanTactics) {
        // sharing rules
        system.debug('Plan Tactic Trigger On After Insert');
        super.onAfterInsert(newPlanTactics, 'Plan_Tactic_vod__c');
    }

    public void onAfterUpdate( List<Plan_Tactic_vod__c> newPlanTactics, List<Plan_Tactic_vod__c> oldPlanTactics, Map<ID, Plan_Tactic_vod__c> newPlanTacticsMap , Map<ID, Plan_Tactic_vod__c> oldPlanTacticsMap ) {
        // sharing rules
        system.debug('Plan Tactic Trigger On After Update ');
        super.onAfterUpdate(newPlanTactics, 'Plan_Tactic_vod__c', oldPlanTacticsMap);
    }

    public void onAfterDelete(List<Plan_Tactic_vod__c> oldPlanTactics, Map<ID, Plan_Tactic_vod__c> oldPlanTacticsMap) {
        // place holder
    }

}