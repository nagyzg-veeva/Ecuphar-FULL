public without sharing class VeevaEmTeamMemberBeforeInsertUpdateHdl {
	private List<EM_Event_Team_Member_vod__c> newEMEventTeamMembers;
    private List<EM_Event_Team_Member_vod__c> oldEMEventTeamMembers;
    private Map<ID, EM_Event_Team_Member_vod__c> newEMEventTeamMembersMap;
    private Map<ID, EM_Event_Team_Member_vod__c> oldEMEventTeamMembersMap;
    private Map<String, String> errorMessageMap = new Map<String, String>();
    private String emMessageCategory = 'EVENT_MANAGEMENT';
    private String duplicateTeamMemberErrorMsgKey = emMessageCategory + ';;DUPLICATE_TEAM_MEMBER_ERROR';
    private String duplicateTeamMemberErrorGroupMsgKey = emMessageCategory + ';;DUPLICATE_TEAM_MEMBER_ERROR_GROUP';

    public VeevaEmTeamMemberBeforeInsertUpdateHdl(List<EM_Event_Team_Member_vod__c> newEventTeamMembers,
                                                            List<EM_Event_Team_Member_vod__c> oldEventTeamMembers,
                                                            Map<ID, EM_Event_Team_Member_vod__c> newEventTeamMembersMap,
                                                            Map<ID, EM_Event_Team_Member_vod__c> oldEventTeamMembersMap) {
        newEMEventTeamMembers = newEventTeamMembers;
        oldEMEventTeamMembers = oldEventTeamMembers;
        newEMEventTeamMembersMap = newEventTeamMembersMap;
        oldEMEventTeamMembersMap = oldEventTeamMembersMap;
    }


    public void emEventTeamMemberBeforeInsertUpdate(Map<String, String> errorMessageMap, List<EM_Event_Team_Member_vod__c> existingTeamMembers,
                                                    List<User> associatedUsers) {
        Set<String> idSet = new Set<String>();
        Set<String> groupNameSet = new Set<String>();
        Map<String, String> idToFirst = new Map<String, String>();
        Map<String, String> idToLast = new Map<String, String>();
        Map<String, String> idToName = new Map<String, String>();
        Map<String, String> groupNameToLabel = new Map<String, String>();

        RecordType teamMemberRecordType;
        RecordType groupRecordType;

        for(RecordType recordType : [SELECT Id, DeveloperName
                                     FROM RecordType
                                     WHERE SobjectType = 'EM_Event_Team_Member_vod__c'
                                     AND DeveloperName IN ('Event_Team_Member_vod', 'Group_vod')]) {
            if(recordType.DeveloperName == 'Event_Team_Member_vod') {
                teamMemberRecordType = recordType;
            } else if(recordType.DeveloperName == 'Group_vod') {
                groupRecordType = recordType;
            }
        }

        Set<Id> eventIds = new Set<Id>();

        for(EM_Event_Team_Member_vod__c member: newEMEventTeamMembers) {
            eventIds.add(member.Event_vod__c);
        }

        // For existing team member, construct a map
        Map<String, Set<String>> existingEventTeamMembersMap = getEventsTeamMemberOrGroupSet(existingTeamMembers, 'Team_Member_vod__c');
        Map<String, Set<String>> existingEventGroupNamesMap = getEventsTeamMemberOrGroupSet(existingTeamMembers, 'Group_Name_vod__c');

        for(EM_Event_Team_Member_vod__c newMember: newEMEventTeamMembers) {
            if ((Trigger.isInsert || (Trigger.isUpdate && oldEMEventTeamMembersMap.get(newMember.Id).Team_Member_vod__c != newMember.Team_Member_vod__c)) &&
                existingEventTeamMembersMap.get(newMember.Event_vod__c) != null &&
                newMember.Team_Member_vod__c != null &&
                existingEventTeamMembersMap.get(newMember.Event_vod__c).contains(newMember.Team_Member_vod__c)) {
                    newMember.addError(errorMessageMap.get(duplicateTeamMemberErrorMsgKey));
            } else if((Trigger.isInsert || (Trigger.isUpdate && oldEMEventTeamMembersMap.get(newMember.Id).Group_Name_vod__c != newMember.Group_Name_vod__c)) &&
                existingEventGroupNamesMap.get(newMember.Event_vod__c) != null &&
                newMember.Group_Name_vod__c != null &&
                existingEventGroupNamesMap.get(newMember.Event_vod__c).contains(newMember.Group_Name_vod__c)) {
                    newMember.addError(errorMessageMap.get(duplicateTeamMemberErrorGroupMsgKey));
            }
        }


        for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers){
            String id = member.Team_Member_vod__c;
            String groupName = member.Group_Name_vod__c;
            if (id != null) {
                idSet.add(id);
            } else if(groupName != null) {
                groupNameSet.add(groupName);
            }
        }

        for (User user : associatedUsers) {
            idToFirst.put(user.Id, user.FirstName);
            idToLast.put(user.Id, user.LastName);
            idToName.put(user.Id, user.Name);
        }

        for(Group publicGroup : [SELECT Name, DeveloperName
                                 FROM Group
                                 WHERE DeveloperName IN :groupNameSet AND Type IN ('Queue', 'Regular')]) {
            groupNameToLabel.put(publicGroup.DeveloperName, publicGroup.Name);
        }

        for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers){
            String type = member.Team_Member_Type_vod__c;
            String userId = member.Team_Member_vod__c;
            String groupName = member.Group_Name_vod__c;
            if (type == 'User_vod'|| userId != null) {
                String first = idToFirst.get(userId);
                String last = idToLast.get(userId);
                String name = idToName.get(userId);
                if (first != null && last != null) {
                    member.Name = last + ', ' + first;
                } else {
                    member.Name = name;
                }
                if(first != null) {
                    member.First_Name_vod__c = first;
                }
                if(last != null) {
                    member.Last_Name_vod__c = last;
                }
            } else if(type == 'Group_vod' || groupName != null) {

                String groupLabel = groupNameToLabel.get(groupName);
                if(groupLabel != null) {
                    member.Name = groupLabel;
                }
            } else if (type == 'Write_In_vod') {
                String first = member.First_Name_vod__c == null ? '' : member.First_Name_vod__c;
                String last = member.Last_Name_vod__c == null ? '' : member.Last_Name_vod__c;
                member.name = last + ', ' + first;
            }
        }
    }

    private Map<String/*Event IDs*/, Set<String>/*Field IDs*/> getEventsTeamMemberOrGroupSet(List<EM_Event_Team_Member_vod__c> existingTeamMembers, String fieldName) {
        Map<String, Set<String>> existingTeamMemberFieldValueMap = new Map<String, Set<String>>();
        for (EM_Event_Team_Member_vod__c existingMember : existingTeamMembers) {
            if (existingMember.Event_vod__c != null) {
                Set<String> fieldValueSet = existingTeamMemberFieldValueMap.get(existingMember.Event_vod__c);
                if(fieldValueSet == null) {
                    fieldValueSet = new Set<String>();
                }
                if (existingMember.get(fieldName) != null) {
                    fieldValueSet.add((String)existingMember.get(fieldName));
                }
                existingTeamMemberFieldValueMap.put(existingMember.Event_vod__c, fieldValueSet);
            }
        }
        return existingTeamMemberFieldValueMap;
    }
}