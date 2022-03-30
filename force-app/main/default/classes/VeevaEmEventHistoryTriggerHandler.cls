public class VeevaEmEventHistoryTriggerHandler {
    boolean hasTeamMemberTypeFLS = Schema.SObjectType.EM_Event_Team_Member_vod__c.fields.Team_Member_Type_vod__c.isUpdateable();
    
    public boolean checkDuplicateTeamMember(EM_Event_Team_Member_vod__c teamMember, List<EM_Event_Team_Member_vod__c> teamMembersToUpdate) {
        return teamMembersToUpdate.contains(teamMember);
    }
    
    public boolean checkAllDuplicateTeamMembers(List<EM_Event_Team_Member_vod__c> oldTeamMembers, List<EM_Event_Team_Member_vod__c> teamMembersToUpdate) {
        for (EM_Event_Team_Member_vod__c teamMember : oldTeamMembers) {
            if (teamMembersToUpdate.contains(teamMember)) {
                return true;
            }
        }

        return false;
    }
    
    public EM_Event_Team_Member_vod__c newApproverTeamMemberPojo(EM_Event_History_vod__c currEventHistory, String referenceId, String memberType) {
        String roleValue = null;
        if (currEventHistory.Next_Approver_Role_vod__c == null) {
            roleValue = 'Approver_vod';
        }
        else {
            roleValue = currEventHistory.Next_Approver_Role_vod__c;
        }

        EM_Event_Team_Member_vod__c newApprover = new EM_Event_Team_Member_vod__c(
            Event_vod__c = currEventHistory.Event_vod__c,
            Role_vod__c = roleValue,
            Team_Member_vod__c = referenceId);
        
        if (hasTeamMemberTypeFLS) {
            newApprover.put('Team_Member_Type_vod__c', memberType);
        }
        
        return newApprover;
    }

    public void addSingleDelegateApprover(EM_Event_History_vod__c history, List<EM_Event_Team_Member_vod__c> emTeamMembers, Map<Id, List<EM_Event_Team_Member_vod__c>> eventToTeamMembers) {
        boolean duplicateDelegate = false;
        EM_Event_Team_Member_vod__c oldDelegateTeamMember;

        if (eventToTeamMembers.get(history.Event_vod__c) != null) {
            for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                if (existingMember.Team_Member_vod__c == history.Delegate_Approver_vod__c) {
                    if (history.Next_Approver_Role_vod__c != null && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                        oldDelegateTeamMember = existingMember;
                        oldDelegateTeamMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                    }
                    else {
                        duplicateDelegate = true;
                    }
                    break;
                }
            }
        }

        if (oldDelegateTeamMember != null && !checkDuplicateTeamMember(oldDelegateTeamMember, emTeamMembers)) {
            emTeamMembers.add(oldDelegateTeamMember);
        }
        else if (!duplicateDelegate && !checkDuplicateTeamMember(oldDelegateTeamMember, emTeamMembers)) {
            EM_Event_Team_Member_vod__c delegateTeamMember = newApproverTeamMemberPojo(history, history.Delegate_Approver_vod__c, 'User_vod');
            emTeamMembers.add(delegateTeamMember);
        }
    }

    public void addMultipleDelegateApprovers(EM_Event_History_vod__c history, List<EM_Event_Team_Member_vod__c> emTeamMembers, Map<Id, List<EM_Event_Team_Member_vod__c>> eventToTeamMembers) {
        List<EM_Event_Team_Member_vod__c> oldTeamMembers = new List<EM_Event_Team_Member_vod__c>();
        Set<String> delegateIds = new Set<String>(history.Delegate_Approver_IDs_vod__c.split(','));
        if (eventToTeamMembers.get(history.Event_vod__c) != null) {
            for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                if (delegateIds.contains(existingMember.Team_Member_vod__c)) {
                    delegateIds.remove(existingMember.Team_Member_vod__c);
                    if(history.Next_Approver_Role_vod__c != null  && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                        existingMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                        oldTeamMembers.add(existingMember);
                    }
                }
            }
        }

        if (!checkAllDuplicateTeamMembers(oldTeamMembers, emTeamMembers)) {
            emTeamMembers.addAll(oldTeamMembers);
        }

        for (String delegateId : delegateIds) {
            EM_Event_Team_Member_vod__c delegateTeamMember = newApproverTeamMemberPojo(history, delegateId, 'User_vod');

            if (!checkDuplicateTeamMember(delegateTeamMember, emTeamMembers)) {
                emTeamMembers.add(delegateTeamMember);
            }
        }
    }
}