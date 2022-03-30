public without sharing class VeevaEmTeamMemberAfterDeleteHdl {
	private List<EM_Event_Team_Member_vod__c> newEMEventTeamMembers;
    private List<EM_Event_Team_Member_vod__c> oldEMEventTeamMembers;
    private Map<ID, EM_Event_Team_Member_vod__c> newEMEventTeamMembersMap;
    private Map<ID, EM_Event_Team_Member_vod__c> oldEMEventTeamMembersMap;

    public VeevaEmTeamMemberAfterDeleteHdl(List<EM_Event_Team_Member_vod__c> newEventTeamMembers,
                                                            List<EM_Event_Team_Member_vod__c> oldEventTeamMembers,
                                                            Map<ID, EM_Event_Team_Member_vod__c> newEventTeamMembersMap,
                                                            Map<ID, EM_Event_Team_Member_vod__c> oldEventTeamMembersMap) {
        newEMEventTeamMembers = newEventTeamMembers;
        oldEMEventTeamMembers = oldEventTeamMembers;
        newEMEventTeamMembersMap = newEventTeamMembersMap;
        oldEMEventTeamMembersMap = oldEventTeamMembersMap;
    }
    public void emEventTeamMemberAfterDelete() {
        Set<String> groupNameSet = new Set<String>();
        for(EM_Event_Team_Member_vod__c member : oldEMEventTeamMembers) {
            if(member.Group_Name_vod__c != null) {
                groupNameSet.add(member.Group_Name_vod__c);
            }
        }

        Map<String, Id> groupNameToGroupId = new Map<String, Id>();
        for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
            groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
        }

        Set<Id> membersId = new Set<Id>();
        Map<Id, Set<Id>> eventToMembers = new Map<Id, Set<Id>>();
        for (EM_Event_Team_Member_vod__c member : oldEMEventTeamMembers) {
            if (eventToMembers.get(member.Event_vod__c) == null) {
                eventToMembers.put(member.Event_vod__c, new Set<Id>());
            }
            if(member.Team_Member_vod__c != null) {
                membersId.add(member.Team_Member_vod__c);
                eventToMembers.get(member.Event_vod__c).add(member.Team_Member_vod__c);
            } else if(member.Group_Name_vod__c != null) {
                Id groupUserId = groupNameToGroupId.get(member.Group_Name_vod__c);
                if(groupUserId != null) {
                    membersId.add(groupUserId);
                    eventToMembers.get(member.Event_vod__c).add(groupUserId);
                }
            }
        }
        Set<Id> eventsId = eventToMembers.keySet();

        List<SObject> toDelete = new List<SObject>();

        String medicalEventSharesQuery = 'SELECT Id, Parent.EM_Event_vod__c, UserOrGroupId FROM Medical_Event_vod__Share ' +
                                            'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM Medical_Event_vod__c WHERE EM_Event_vod__c IN : eventsId)';
        String attendeeSharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Attendee_vod__Share ' +
                                       'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Attendee_vod__c WHERE Event_vod__c IN : eventsId)';
        String speakerSharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Speaker_vod__Share ' +
                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Speaker_vod__c WHERE Event_vod__c IN : eventsId)';
        String expenseSharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Expense_Estimate_vod__Share ' +
                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Expense_Estimate_vod__c WHERE Event_vod__c IN : eventsId)';
        String sessionSharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Session_vod__Share ' +
                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Session_vod__c WHERE Event_vod__c IN : eventsId)';
        String headerSharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM Expense_Header_vod__Share ' +
                                    'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM Expense_Header_vod__c WHERE Event_vod__c IN : eventsId)';
        String budgetSharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Budget_vod__Share ' +
                                    'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Budget_vod__c WHERE Event_vod__c IN : eventsId)';
        String historySharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_History_vod__Share ' +
                                     'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_History_vod__c WHERE Event_vod__c IN : eventsId)';
        String materialSharesQuery = 'SELECT Id, Parent.Event_vod__c, UserOrGroupId FROM EM_Event_Material_vod__Share ' +
                                      'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Material_vod__c WHERE Event_vod__c IN : eventsId)';

        if (VOD_Utils.hasObject('EM_Event_vod__Share')) {
            List<SObject> eventShares = Database.query('SELECT Id, ParentId, UserOrGroupId FROM EM_Event_vod__Share WHERE UserOrGroupId IN : membersId AND ParentId IN : eventsId');
            for (SObject eventShare : eventShares) {
                if (eventToMembers.get((Id) eventShare.get('ParentId')).contains((Id) eventShare.get('UserOrGroupId'))) {
                    toDelete.add(eventShare);
                }
            }
        }

        if (VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share')) {
            List<SObject> sessionAttendeeShares = Database.query('SELECT Id, Parent.Event_Session_vod__r.Event_vod__c, UserOrGroupId FROM EM_Event_Session_Attendee_vod__Share ' +
                                                                 'WHERE UserOrGroupId IN : membersId AND ParentId IN (SELECT Id FROM EM_Event_Session_Attendee_vod__c ' +
                                                                                                                     'WHERE Event_Session_vod__r.Event_vod__c IN : eventsId)');
            for (SObject sessionAttendeeShare : sessionAttendeeShares) {
                if (sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r') != null &&
                    eventToMembers.get((Id) sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r').get('Event_vod__c')).contains((Id) sessionAttendeeShare.get('UserOrGroupId'))) {
                    toDelete.add(sessionAttendeeShare);
                }
            }
        }

        addToDeleteCheckParentName('Medical_Event_vod__Share', membersId, eventsId, medicalEventSharesQuery, eventToMembers, toDelete, 'EM_Event_vod__c');
        addToDeleteCheckParentName('EM_Attendee_vod__Share', membersId, eventsId, attendeeSharesQuery, eventToMembers, toDelete, 'Event_vod__c');
        addToDeleteCheckParentName('EM_Event_Speaker_vod__Share', membersId, eventsId, speakerSharesQuery, eventToMembers, toDelete, 'Event_vod__c');
        addToDeleteCheckParentName('EM_Expense_Estimate_vod__Share', membersId, eventsId, expenseSharesQuery, eventToMembers, toDelete, 'Event_vod__c');
        addToDeleteCheckParentName('EM_Event_Session_vod__Share', membersId, eventsId, sessionSharesQuery, eventToMembers, toDelete, 'Event_vod__c');
		addToDeleteCheckParentName('Expense_Header_vod__Share', membersId, eventsId, headerSharesQuery, eventToMembers, toDelete, 'Event_vod__c');
        addToDeleteCheckParentName('EM_Event_Budget_vod__Share', membersId, eventsId, budgetSharesQuery, eventToMembers, toDelete, 'Event_vod__c');
        addToDeleteCheckParentName('EM_Event_History_vod__Share', membersId, eventsId, historySharesQuery, eventToMembers, toDelete, 'Event_vod__c');
        addToDeleteCheckParentName('EM_Event_Material_vod__Share', membersId, eventsId, materialSharesQuery, eventToMembers, toDelete, 'Event_vod__c');

        List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
        for (Database.DeleteResult result : deleteResults) {
           if (!result.isSuccess()) {
               system.debug('delete error: ' + result.getErrors()[0]);
           }
        }
    }

    private void addToDeleteCheckParentName(String objectToCheck, Set<Id> membersId, Set<Id> eventsId,
                                            String query, Map<Id, Set<Id>> eventToMembersMap, List<SObject> toDelete,
                                            String parentName) {
        if (VOD_Utils.hasObject(objectToCheck)) {
            List<SObject> sharesList = Database.query(query);
            for(SObject share : sharesList) {
                if(eventToMembersMap.get((Id) share.getSObject('Parent').get(parentName)).contains((Id) share.get('UserOrGroupId'))) {
                    toDelete.add(share);
                }
            }
        }
    }
}