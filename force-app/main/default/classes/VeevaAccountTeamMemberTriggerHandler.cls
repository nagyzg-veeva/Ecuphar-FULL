public without sharing class VeevaAccountTeamMemberTriggerHandler extends VeevaAccountPlanSharingTriggerHandler {


    public void onBeforeInsert(List<Account_Team_Member_vod__c> newAccountTeamMembers) {
        // place holder
    }

    public void onBeforeUpdate( List<Account_Team_Member_vod__c> newAccountTeamMembers, List<Account_Team_Member_vod__c> oldAccountTeamMembers, Map<ID, Account_Team_Member_vod__c> newAccountTeamMembersMap , Map<ID, Account_Team_Member_vod__c> oldAccountTeamMembersMap ) {
       // place holder
    }

    public void onBeforeDelete (List<Account_Team_Member_vod__c> oldAccountTeamMembers) {
        //place holder

    }

    public void onAfterInsert(List<Account_Team_Member_vod__c> newAccountTeamMembers) {
        // sharing rules
        super.onAfterInsert(newAccountTeamMembers, 'Account_Team_Member_vod__c');
    }

    public void onAfterUpdate( List<Account_Team_Member_vod__c> newAccountTeamMembers, List<Account_Team_Member_vod__c> oldAccountTeamMembers, Map<ID, Account_Team_Member_vod__c> newAccountTeamMembersMap , Map<ID, Account_Team_Member_vod__c> oldAccountTeamMembersMap ) {
        // sharing rules
        super.onAfterUpdate(newAccountTeamMembers, 'Account_Team_Member_vod__c', oldAccountTeamMembersMap);
    }

    public void onAfterDelete(List<Account_Team_Member_vod__c> oldAccountTeamMembers, Map<ID, Account_Team_Member_vod__c> oldAccountTeamMembersMap) {
        // sharing rules
        super.onAfterDelete(oldAccountTeamMembers);
    }

}