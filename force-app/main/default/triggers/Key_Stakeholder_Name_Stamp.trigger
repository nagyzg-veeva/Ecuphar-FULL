trigger Key_Stakeholder_Name_Stamp on Key_Stakeholder_vod__c (before update, before insert) {

    Set<Id> accountIds = new Set<Id> ();

    for(Key_Stakeholder_vod__c stakeholder : Trigger.new) {
        if(stakeholder.Key_Stakeholder_vod__c != null) {
            accountIds.add(stakeholder.Key_Stakeholder_vod__c);
        }
    }

    Map<Id, Account> accountsMapForStakeHolders = new Map<Id, Account>([Select Id, Formatted_Name_vod__c from Account where Id in :accountIds]);

    for(Key_Stakeholder_vod__c stakeholder : Trigger.new) {
        Account acct = accountsMapForStakeHolders.get(stakeholder.Key_Stakeholder_vod__c);
        if(acct != null) {
            stakeholder.Key_Stakeholder_Name_vod__c = acct.Formatted_Name_vod__c;
        }    
    }

}