trigger Stakeholder_Owner_Name_Stamp on Key_Stakeholder_vod__c (before update, before insert) {
    
    Set<Id> userIds = new Set<Id> ();
    
    for(Key_Stakeholder_vod__c stakeholder : Trigger.new) {
        if(stakeholder.Stakeholder_Owner_vod__c != null) {
            userIds.add(stakeholder.Stakeholder_Owner_vod__c);
        }    
    }
    
    Map<Id, User> usersMapForStakeHolders = new Map<Id, User>([select Id,Name FROM User where Id in :userIds]);
    
    for(Key_Stakeholder_vod__c stakeholder : Trigger.new) {
        User user = usersMapForStakeHolders.get(stakeholder.Stakeholder_Owner_vod__c);
        if(user != null) {
            stakeholder.Stakeholder_Owner_Name_vod__c = user.Name;
        }
    }
}