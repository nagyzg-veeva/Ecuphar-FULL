trigger Account_Team_Member_Name_Stamp on Account_Team_Member_vod__c (before update, before insert) {
    Set<Id> userIds = new Set<Id>();

    for(Account_Team_Member_vod__c accountTeamMember : Trigger.new) {
        if(accountTeamMember.Team_Member_vod__c != null) {
            userIds.add(accountTeamMember.Team_Member_vod__c);
        }
    }

    Map<Id, User> usersById = new Map<Id, User>([SELECT Id, Name FROM User where Id in :userIds]);

    for(Account_Team_Member_vod__c member : Trigger.new) {
        User user = usersById.get(member.Team_Member_vod__c);
        if(user != null) {
            member.Team_Member_Name_vod__c = user.Name;
        }    
    }
}