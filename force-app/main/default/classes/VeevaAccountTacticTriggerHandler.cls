public without sharing class VeevaAccountTacticTriggerHandler extends VeevaAccountPlanSharingTriggerHandler {

   public void onBeforeInsert(List<Account_Tactic_vod__c> newAccountTactics) {
        // place holder for before insert event handling
   }

   public void onBeforeUpdate( List<Account_Tactic_vod__c> newAccountTactics, List<Account_Tactic_vod__c> oldAccountTactics, Map<ID, Account_Tactic_vod__c> newAccountTacticsMap , Map<ID, Account_Tactic_vod__c> oldAccountTacticsMap ) {
        // place holder
   }

   public void onBeforeDelete (List<Account_Tactic_vod__c> oldAccountTactics, Map<ID, Account_Tactic_vod__c> oldAccountTacticsMap) {
       // place holder

   }

   public void onAfterInsert(List<Account_Tactic_vod__c> newAccountTactics) {
        // sharing rules
       super.onAfterInsert(newAccountTactics, 'Account_Tactic_vod__c');
   }

    public void onAfterUpdate( List<Account_Tactic_vod__c> newAccountTactics, List<Account_Tactic_vod__c> oldAccountTactics, Map<ID, Account_Tactic_vod__c> newAccountTacticsMap , Map<ID, Account_Tactic_vod__c> oldAccountTacticsMap ) {
        // sharing rules
        super.onAfterUpdate(newAccountTactics, 'Account_Tactic_vod__c', oldAccountTacticsMap);
    }

    public void onAfterDelete(List<Account_Tactic_vod__c> oldAccountTactics, Map<ID, Account_Tactic_vod__c> oldAccountTacticsMap) {
        // place holder
    }


}