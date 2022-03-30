trigger VOD_EM_EVENT_HISTORY_UPSERT on EM_Event_History_vod__c (before insert, before update) {
 	List<EM_Event_Team_Member_vod__c> emTeamMembers = new List<EM_Event_Team_Member_vod__c>();
    boolean hasTeamMemberTypeFLS = Schema.SObjectType.EM_Event_Team_Member_vod__c.fields.Team_Member_Type_vod__c.isUpdateable();
    VeevaEmEventHistoryTriggerHandler emHistoryHandler = new VeevaEmEventHistoryTriggerHandler();

    Set<Id> eventIds = new Set<Id>();
    for (EM_Event_History_vod__c history : Trigger.new) {
        eventIds.add(history.Event_vod__c);
    }
    List<EM_Event_vod__c> events = [SELECT Id, Override_Lock_vod__c, Lock_vod__c, OwnerId, (SELECT Id, Event_vod__c, Role_vod__c, Team_Member_vod__c, Group_Name_vod__c FROM EM_Event_Team_Member_vod__r)
                                    FROM EM_Event_vod__c
                                    WHERE Id IN : eventIds];
    Map<Id, List<EM_Event_Team_Member_vod__c>> eventToTeamMembers = new Map<Id, List<EM_Event_Team_Member_vod__c>>();
    Set<Id> lockedEvents = new Set<Id>();
    Map<Id, EM_Event_vod__c> eventsMap = new Map<Id, EM_Event_vod__c>();
    for (EM_Event_vod__c event : events) {
        if (Trigger.isUpdate && VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
        eventsMap.put(event.Id, event);
        if (event.EM_Event_Team_Member_vod__r != null) {
            eventToTeamMembers.put(event.Id, new List<EM_Event_Team_Member_vod__c>());
            for (EM_Event_Team_Member_vod__c teamMember : event.EM_Event_Team_Member_vod__r) {
                eventToTeamMembers.get(event.Id).add(teamMember);
            }
        }
    }
    for(EM_Event_history_vod__c history: Trigger.new) {
        if (history.Event_vod__c != null) {
            if(history.Override_Lock_vod__c == true) {
                history.Override_Lock_vod__c = false;
            } else if (history.Event_vod__c != null && lockedEvents.contains(history.Event_vod__c)) {
                history.addError('Event is locked');
            }

            boolean duplicate = false;
            EM_Event_Team_Member_vod__c teamMember;
            EM_Event_Team_Member_vod__c oldTeamMember = null;
            if(history.Next_Approver_Group_vod__c != null) {
                if (eventToTeamMembers.get(history.Event_vod__c) != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (existingMember.Group_Name_vod__c == history.Next_Approver_Group_vod__c) {
                            if(history.Next_Approver_Role_vod__c != null  && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                                oldTeamMember = existingMember;
                                oldTeamMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                            } else {
                            	duplicate = true;
                            }
                            break;
                        }
                    }
                }
                if(oldTeamMember != null) {
                    emTeamMembers.add(oldTeamMember);
                } else if (!duplicate) {
                    String roleValue = null;
                    if(history.Next_Approver_Role_vod__c == null) {
                        roleValue = 'Approver_vod';
                    } else {
                        roleValue = history.Next_Approver_Role_vod__c;
                    }
                    teamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Role_vod__c = roleValue,
                        Group_Name_vod__c = history.Next_Approver_Group_vod__c
                    );
                    if (hasTeamMemberTypeFLS) {
                        teamMember.put('Team_Member_Type_vod__c', 'Group_vod');
                    }
                    emTeamMembers.add(teamMember);
                }
            } else if(history.Next_Approver_vod__c != null) {
                if (eventToTeamMembers.get(history.Event_vod__c) != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (existingMember.Team_Member_vod__c == history.Next_Approver_vod__c) {
                            if(history.Next_Approver_Role_vod__c != null  && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                                oldTeamMember = existingMember;
                                oldTeamMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                            } else {
                            	duplicate = true;
                            }
                            break;
                        }
                    }
                }
                if(oldTeamMember != null) {
                    emTeamMembers.add(oldTeamMember);
                } else if (!duplicate) {
                    String roleValue = null;
                    if(history.Next_Approver_Role_vod__c == null) {
                        roleValue = 'Approver_vod';
                    } else {
                        roleValue = history.Next_Approver_Role_vod__c;
                    }
                    teamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Role_vod__c = roleValue,
                        Team_Member_vod__c = history.Next_Approver_vod__c
                     );
                    if (hasTeamMemberTypeFLS) {
                        teamMember.put('Team_Member_Type_vod__c', 'User_vod');
                    }
                    emTeamMembers.add(teamMember);
                }
            } else if (history.Approver_IDs_vod__c != null) {
            	List<EM_Event_Team_Member_vod__c> oldTeamMembers = new List<EM_Event_Team_Member_vod__c>();
                Set<String> approverIds = new Set<String>(history.Approver_IDs_vod__c.split(','));
                Map<String, Id> existingGroupTeamMembers = new Map<String, Id>();
            	if (eventToTeamMembers.get(history.Event_vod__c) != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (approverIds.contains(existingMember.Team_Member_vod__c)) {
                            approverIds.remove(existingMember.Team_Member_vod__c);
                            if(history.Next_Approver_Role_vod__c != null  && existingMember.Role_vod__c != history.Next_Approver_Role_vod__c) {
                                existingMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                                oldTeamMembers.add(existingMember);
                            }
                        } else if (String.isNotBlank(existingMember.Group_Name_vod__c)) {
                            existingGroupTeamMembers.put(existingMember.Group_Name_vod__c, existingMember.Id);
                        }
                    }
                }
                emTeamMembers.addAll(oldTeamMembers);
                String roleValue = null;
                if(history.Next_Approver_Role_vod__c == null) {
                    roleValue = 'Approver_vod';
                } else {
                    roleValue = history.Next_Approver_Role_vod__c;
                }
                //first create User Team Members to insert
                String userKeyPrefix = Schema.SObjectType.User.getKeyPrefix();
                List<String> groupIds = new List<String>();
                for(String approverId: approverIds) {
                    if (!approverId.startsWith(userKeyPrefix)) {
                        groupIds.add(approverId);
                        continue; //don't add newTeamMember to list of emTeamMembers to upsert
                    }
                    //approver id is a user id after this point
                    EM_Event_Team_Member_vod__c newTeamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Role_vod__c = roleValue,
                        Team_Member_vod__c = approverId
                    );
                    if (hasTeamMemberTypeFLS) {
                        newTeamMember.put('Team_Member_Type_vod__c', 'User_vod');
                    }
                    emTeamMembers.add(newTeamMember);
                }
                //now create Group Team Members to insert
                for (Group groupApprover : [SELECT DeveloperName FROM Group WHERE Id IN :groupIds]) {
                    EM_Event_Team_Member_vod__c groupTeamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Role_vod__c = roleValue,
                        Group_Name_vod__c = groupApprover.DeveloperName
                    );
                    if (existingGroupTeamMembers.get(groupApprover.DeveloperName) != null) { //if it exists, stamp the Id so we do an update instead of insert
                        groupTeamMember.Id = existingGroupTeamMembers.get(groupApprover.DeveloperName);
                    }
                    if (hasTeamMemberTypeFLS) {
                        groupTeamMember.put('Team_Member_Type_vod__c', 'Group_vod');
                    }
                    emTeamMembers.add(groupTeamMember);
                }
            } else if(history.Ending_Status_vod__c == null) {
                EM_Event_vod__c historyEvent = eventsMap.get(history.Event_vod__c);
                Id userId;
                if(historyEvent != null) {
                    userId = historyEvent.OwnerId;
                }
                if (eventToTeamMembers.get(history.Event_vod__c) != null && userId != null) {
                    for (EM_Event_Team_Member_vod__c existingMember : eventToTeamMembers.get(history.Event_vod__c)) {
                        if (existingMember.Team_Member_vod__c == userId) {
                            duplicate = true;
                            break;
                        }
                    }
                }
                if (!duplicate && userId != null) {
					teamMember = new EM_Event_Team_Member_vod__c(
                        Event_vod__c = history.Event_vod__c,
                        Team_Member_vod__c = userId
                    );
                    if (hasTeamMemberTypeFLS) {
                        teamMember.put('Team_Member_Type_vod__c', 'User_vod');
                    }

                    if(history.Next_Approver_Role_vod__c != null) {
                        teamMember.Role_vod__c = history.Next_Approver_Role_vod__c;
                    }

                    emTeamMembers.add(teamMember);
                }
            }

            if (history.Next_Approver_Group_vod__c == null) {
                if (history.Delegate_Approver_vod__c != null) {
                    emHistoryHandler.addSingleDelegateApprover(history, emTeamMembers, eventToTeamMembers);
                } else if (history.Delegate_Approver_IDs_vod__c != null) {
                    emHistoryHandler.addMultipleDelegateApprovers(history, emTeamMembers, eventToTeamMembers);
                }
            }
        }
    }
    if (emTeamMembers.size() > 0) {
	    upsert emTeamMembers;
    }
}