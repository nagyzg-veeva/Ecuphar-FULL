public without sharing class VeevaEmTeamMemberAfterInsertUpdateHdl {
	private List<EM_Event_Team_Member_vod__c> newEMEventTeamMembers;
    private List<EM_Event_Team_Member_vod__c> oldEMEventTeamMembers;
    private Map<ID, EM_Event_Team_Member_vod__c> newEMEventTeamMembersMap;
    private Map<ID, EM_Event_Team_Member_vod__c> oldEMEventTeamMembersMap;

    public VeevaEmTeamMemberAfterInsertUpdateHdl(List<EM_Event_Team_Member_vod__c> newEventTeamMembers,
                                                            List<EM_Event_Team_Member_vod__c> oldEventTeamMembers,
                                                            Map<ID, EM_Event_Team_Member_vod__c> newEventTeamMembersMap,
                                                            Map<ID, EM_Event_Team_Member_vod__c> oldEventTeamMembersMap) {
        newEMEventTeamMembers = newEventTeamMembers;
        oldEMEventTeamMembers = oldEventTeamMembers;
        newEMEventTeamMembersMap = newEventTeamMembersMap;
        oldEMEventTeamMembersMap = oldEventTeamMembersMap;
    }

    public void emEventTeamMemberAfterInsertUpdate() {
            List<SObject> eventSharesToUpsert = new List<SObject>();
            List<SObject> medicalEventSharesToUpsert = new List<SObject>();
            List<SObject> attendeeSharesToUpsert = new List<SObject>();
            List<SObject> speakerSharesToUpsert = new List<SObject>();
            List<SObject> estimateSharesToUpsert = new List<SObject>();
            List<SObject> sessionSharesToUpsert = new List<SObject>();
            List<SObject> sessionAttendeeSharesToUpsert = new List<SObject>();
            List<SObject> headerSharesToUpsert = new List<SObject>();
            List<SObject> budgetSharesToUpsert = new List<SObject>();
            List<SObject> historySharesToUpsert = new List<SObject>();
            List<SObject> materialSharestoUpsert = new List<SObject>();

            Set<Id> event_ids = new Set<Id>();
            Set<Id> oldTeamMember = new Set<Id>();

            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

            if (Trigger.isInsert) {
                for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
                    event_ids.add(member.Event_vod__c);
                }
            } else {

                Set<String> oldGroupNameSet = new Set<String>();
                for(EM_Event_Team_Member_vod__c member : oldEMEventTeamMembers) {
                    if(member.Group_Name_vod__c != null) {
                        oldGroupNameSet.add(member.Group_Name_vod__c);
                    }
                }

                Map<String, Id> oldGroupNameGroupId = new Map<String, Id>();
                for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :oldGroupNameSet]) {
                    oldGroupNameGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
                }

                List<SObject> toDelete = new List<SObject>();
                List<Id> oldUser = new List<Id>();
                List<Id> oldEvent = new List<Id>();
                Map<Id, Set<Id>> eventToUsers = new Map<Id, Set<Id>>();
                for (EM_Event_Team_Member_vod__c member : oldEMEventTeamMembers) {
                    if (member.Event_vod__c != newEMEventTeamMembersMap.get(member.Id).Event_vod__c ||
                        member.Team_Member_vod__c != newEMEventTeamMembersMap.get(member.Id).Team_Member_vod__c ||
                        member.Group_Name_vod__c != newEMEventTeamMembersMap.get(member.Id).Group_Name_vod__c) {
                        if (eventToUsers.get(member.Event_vod__c) == null) {
                            eventToUsers.put(member.Event_vod__c, new Set<Id>());
                        }
                        if(member.Team_Member_vod__c != null) {
                            eventToUsers.get(member.Event_vod__c).add(member.Team_Member_vod__c);
                            oldUser.add(member.Team_Member_vod__c);
                        } else if(member.Group_Name_vod__c != null) {
                            Id groupUserId = oldGroupNameGroupId.get(member.Group_Name_vod__c);
                            if(groupUserId != null) {
                                oldUser.add(groupUserId);
                                eventToUsers.get(member.Event_vod__c).add(groupUserId);
                            }
                        }
                        oldEvent.add(member.Event_vod__c);
                        oldTeamMember.add(member.Id);
                        event_ids.add(newEMEventTeamMembersMap.get(member.Id).Event_vod__c);
                    }
                }
                if (!oldTeamMember.isEmpty()) {
                    // delete old share records because Event_vod__c or Team_Member_vod__c or Group_Name_vod__c fields on event team member were changed
                    if (VOD_Utils.hasObject('EM_Event_vod__Share')) {
                        List<SObject> eventShares = Database.query('SELECT Id, ParentId, UserOrGroupId FROM EM_Event_vod__Share WHERE UserOrGroupId IN : oldUser AND ParentId IN : oldEvent');
                        for (SObject eventShare : eventShares) {
                            if (eventToUsers.get((Id) eventShare.get('ParentId')).contains((Id) eventShare.get('UserOrGroupId'))) {
                                toDelete.add(eventShare);
                            }
                        }
                    }
                    addToDeleteList(eventToUsers, 'Medical_Event_vod__Share', 'EM_Event_vod__c', 'Medical_Event_vod__c', oldUser, oldEvent, toDelete);
                    addToDeleteList(eventToUsers, 'EM_Attendee_vod__Share', 'Event_vod__c', 'EM_Attendee_vod__c', oldUser, oldEvent, toDelete);
                    addToDeleteList(eventToUsers, 'EM_Event_Speaker_vod__Share', 'Event_vod__c', 'EM_Event_Speaker_vod__c', oldUser, oldEvent, toDelete);
                    addToDeleteList(eventToUsers, 'EM_Expense_Estimate_vod__Share', 'Event_vod__c', 'EM_Expense_Estimate_vod__c', oldUser, oldEvent, toDelete);
                    addToDeleteList(eventToUsers, 'EM_Event_Session_vod__Share', 'Event_vod__c', 'EM_Event_Session_vod__c', oldUser, oldEvent, toDelete);
                    if (VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share')) {
                        List<SObject> sessionAttendeeShares = Database.query('SELECT Id, Parent.Event_Session_vod__r.Event_vod__c, UserOrGroupId FROM EM_Event_Session_Attendee_vod__Share ' +
                                                                             'WHERE UserOrGroupId IN : oldUser AND ParentId IN (SELECT Id FROM EM_Event_Session_Attendee_vod__c ' +
                                                                                                                                 'WHERE Event_Session_vod__r.Event_vod__c IN : oldEvent)');
                        for (SObject sessionAttendeeShare : sessionAttendeeShares) {
                            if (sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r') != null &&
                                eventToUsers.get((Id) sessionAttendeeShare.getSObject('Parent').getSObject('Event_Session_vod__r').get('Event_vod__c')).contains((Id) sessionAttendeeShare.get('UserOrGroupId'))) {
                                toDelete.add(sessionAttendeeShare);
                            }
                        }
                    }
                    addToDeleteList(eventToUsers, 'Expense_Header_vod__Share', 'Event_vod__c', 'Expense_Header_vod__c', oldUser, oldEvent, toDelete);
                    addToDeleteList(eventToUsers, 'EM_Event_Budget_vod__Share', 'Event_vod__c', 'EM_Event_Budget_vod__c', oldUser, oldEvent, toDelete);
                    addToDeleteList(eventToUsers, 'EM_Event_History_vod__Share', 'Event_vod__c', 'EM_Event_History_vod__c', oldUser, oldEvent, toDelete);
                    addToDeleteList(eventToUsers, 'EM_Event_Material_vod__Share', 'Event_vod__c', 'EM_Event_Material_vod__c', oldUser, oldEvent, toDelete);

                    List<Database.DeleteResult> deleteResults = Database.delete(toDelete, false);
                    for (Database.DeleteResult result : deleteResults) {
                       if (!result.isSuccess()) {
                           System.debug('delete error: ' + result.getErrors()[0]);
                       }
                    }
                }
            }

            Set<Id> lockedEvents = new Set<Id>();
            List<SObject> attendees = new List<SObject>();
            List<SObject> speakers = new List<SObject>();
            List<SObject> expenses = new List<SObject>();
            List<SObject> headers = new List<SObject>();
            List<SObject> budgets = new List<SObject>();
            List<SObject> histories = new List<SObject>();
            List<SObject> materials = new List<SObject>();
            Map<Id, Id> eventToMedicalEvent = new Map<Id, Id>();
            Map<Id, Set<Id>> eventToAttendees = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToSpeakers = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToExpenses = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToSessions = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToSessionAttendees = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToHeaders = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToBudgets = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToHistories = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> eventToMaterials = new Map<Id, Set<Id>>();
            if (!event_ids.isEmpty()) {
                List<EM_Event_vod__c> events = [SELECT Id, Override_Lock_vod__c, Lock_vod__c,
                                                (SELECT Id, Event_vod__c FROM EM_Attendee_Event_vod__r), (SELECT Id, Event_vod__c FROM EM_Event_Speaker_vod__r),
                                                (SELECT Id, Event_vod__c FROM Expense_Estimate_vod__r), (SELECT Id, Event_vod__c FROM Expense_Header_vod__r),
                                                (SELECT Id, Event_vod__c FROM Event_vod__r), (SELECT Id, Event_vod__c FROM EM_Event_History_Event_vod__r),
                                                (SELECT Id, Event_vod__c FROM Event_Materials__r)
                                                FROM EM_Event_vod__c WHERE Id IN : event_ids];
                for (EM_Event_vod__c event : events) {
                    for (SObject attendee : (List<SObject>)event.EM_Attendee_Event_vod__r) {
                        attendees.add(attendee);
                    }
                    for (SObject speaker : (List<SObject>)event.EM_Event_Speaker_vod__r) {
                        speakers.add(speaker);
                    }
                    for (SObject expense : (List<SObject>)event.Expense_Estimate_vod__r) {
                        expenses.add(expense);
                    }
                    for (SObject header : (List<SObject>)event.Expense_Header_vod__r) {
                        headers.add(header);
                    }
                    for (SObject budget : (List<SObject>)event.Event_vod__r) {
                        budgets.add(budget);
                    }
                    for (SObject history : (List<SObject>)event.EM_Event_History_Event_vod__r) {
                        histories.add(history);
                    }
                    for (SObject material : (List<SObject>)event.Event_Materials__r) {
                        materials.add(material);
                    }
                }
                if (VOD_Utils.hasObject('Medical_Event_vod__Share')) {
                    List<Medical_Event_vod__c> medicalEvents = [SELECT Id, EM_Event_vod__c FROM Medical_Event_vod__c WHERE EM_Event_vod__c IN : event_ids];
                    for (Medical_Event_vod__c medicalEvent : medicalEvents) {
                        eventToMedicalEvent.put(medicalEvent.EM_Event_vod__c, medicalEvent.Id);
                    }
                }

                constructEventToRecordsMap('EM_Attendee_vod__Share', attendees, eventToAttendees);
                constructEventToRecordsMap('EM_Event_Speaker_vod__Share', speakers, eventToSpeakers);
                constructEventToRecordsMap('EM_Expense_Estimate_vod__Share', expenses, eventToExpenses);
                constructEventToRecordsMap('Expense_Header_vod__Share', headers, eventToHeaders);
                constructEventToRecordsMap('EM_Event_Budget_vod__Share', budgets, eventToBudgets);
                constructEventToRecordsMap('EM_Event_History_vod__Share', histories, eventToHistories);
                constructEventToRecordsMap('EM_Event_Material_vod__Share', materials, eventToMaterials);

                if (VOD_Utils.hasObject('EM_Event_Session_vod__Share') || VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share')) {
                    List<EM_Event_Session_vod__c> sessions = [SELECT Id, Event_vod__c, (SELECT Id FROM Event_Session_vod__r) FROM EM_Event_Session_vod__c WHERE Event_vod__c IN : event_ids];
                    for (EM_Event_Session_vod__c session : sessions) {
                        if (eventToSessions.get(session.Event_vod__c) == null) {
                            eventToSessions.put(session.Event_vod__c, new Set<Id>());
                        }
                        eventToSessions.get(session.Event_vod__c).add(session.Id);
                        for (EM_Event_Session_Attendee_vod__c sessionAttendee : session.Event_Session_vod__r) {
                            if (eventToSessionAttendees.get(session.Event_vod__c) == null) {
                                eventToSessionAttendees.put(session.Event_vod__c, new Set<Id>());
                            }
                            eventToSessionAttendees.get(session.Event_vod__c).add(sessionAttendee.Id);
                        }
                    }
                }
            }

            Set<String> newGroupNameSet = new Set<String>();
            for(EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
                if(member.Group_Name_vod__c != null) {
                    newGroupNameSet.add(member.Group_Name_vod__c);
                }
            }

            Map<String, Id> newGroupNameToGroupId = new Map<String, Id>();
            for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :newGroupNameSet]) {
                newGroupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
            }

        	boolean hasEmEventVodShareObj = VOD_Utils.hasObject('EM_Event_vod__Share');
        	boolean hasMedicalEventVodShareObj = VOD_Utils.hasObject('Medical_Event_vod__Share');
        	boolean hasEmAttendeeVodShareObj = VOD_Utils.hasObject('EM_Attendee_vod__Share');
            boolean hasEmEventSpeakerVodShareObj = VOD_Utils.hasObject('EM_Event_Speaker_vod__Share');
        	boolean hasEmExpenseEstimateVodShareObj = VOD_Utils.hasObject('EM_Expense_Estimate_vod__Share');
         	boolean hasEmEventSessionVodShareObj = VOD_Utils.hasObject('EM_Event_Session_vod__Share');
        	boolean hasEmEventSessionAttendeeVodShareObj = VOD_Utils.hasObject('EM_Event_Session_Attendee_vod__Share');
        	boolean hasExpenseHeaderVodShareObj = VOD_Utils.hasObject('Expense_Header_vod__Share');
         	boolean hasEmEventBudgetVodShareObj = VOD_Utils.hasObject('EM_Event_Budget_vod__Share');
        	boolean hasEmEventHistoryVodShareObj = VOD_Utils.hasObject('EM_Event_History_vod__Share');
         	boolean hasEmEventMaterialVodShareObj = VOD_Utils.hasObject('EM_Event_Material_vod__Share');
            for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
                if (member.Event_vod__c != null && lockedEvents.contains(member.Event_vod__c)) {
                    member.addError('Event is locked');
                }
                if (Trigger.isInsert || (Trigger.isUpdate && oldTeamMember.contains(member.Id))) {
                    if (hasEmEventVodShareObj) {
                        populateSharesToUpsert(member, globalDescribe, 'EM_Event_vod__Share', member.Event_vod__c, newGroupNameToGroupId, eventSharesToUpsert);
                    }

                    if (hasMedicalEventVodShareObj && eventToMedicalEvent.get(member.Event_vod__c) != null) {
                        populateSharesToUpsert(member, globalDescribe, 'Medical_Event_vod__Share', eventToMedicalEvent.get(member.Event_vod__c), newGroupNameToGroupId, medicalEventSharesToUpsert);
                    }

                    if (hasEmAttendeeVodShareObj && eventToAttendees.get(member.Event_vod__c) != null) {
                        for (Id attendeeId : eventToAttendees.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Attendee_vod__Share', attendeeId, newGroupNameToGroupId, attendeeSharesToUpsert);
                        }
                    }

                    if (hasEmEventSpeakerVodShareObj && eventToSpeakers.get(member.Event_vod__c) != null) {
                        for (Id speakerId : eventToSpeakers.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Event_Speaker_vod__Share', speakerId, newGroupNameToGroupId, speakerSharesToUpsert);
                        }
                    }

                    if (hasEmExpenseEstimateVodShareObj && eventToExpenses.get(member.Event_vod__c) != null) {
                        for (Id expenseId : eventToExpenses.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Expense_Estimate_vod__Share', expenseId, newGroupNameToGroupId, estimateSharesToUpsert);
                        }
                    }

                    if (hasEmEventSessionVodShareObj && eventToSessions.get(member.Event_vod__c) != null) {
                        for (Id sessionId : eventToSessions.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Event_Session_vod__Share', sessionId, newGroupNameToGroupId, sessionSharesToUpsert);
                        }
                    }

                    if (hasEmEventSessionAttendeeVodShareObj && eventToSessionAttendees.get(member.Event_vod__c) != null) {
                        for (Id sessionAttendeeId : eventToSessionAttendees.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Event_Session_vod__Share', sessionAttendeeId, newGroupNameToGroupId, sessionAttendeeSharesToUpsert);
                        }
                    }

                    if (hasExpenseHeaderVodShareObj && eventToHeaders.get(member.Event_vod__c) != null) {
                        for (Id headerId : eventToHeaders.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'Expense_Header_vod__Share', headerId, newGroupNameToGroupId, headerSharesToUpsert);
                        }
                    }

                    if (hasEmEventBudgetVodShareObj && eventToBudgets.get(member.Event_vod__c) != null) {
                        for (Id budgetId : eventToBudgets.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Event_Budget_vod__Share', budgetId, newGroupNameToGroupId, budgetSharesToUpsert);
                        }
                    }

                    if (hasEmEventHistoryVodShareObj && eventToHistories.get(member.Event_vod__c) != null) {
                        for (Id historyId : eventToHistories.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Event_History_vod__Share', historyId, newGroupNameToGroupId, historySharesToUpsert);
                        }
                    }

                    if (hasEmEventMaterialVodShareObj && eventToMaterials.get(member.Event_vod__c) != null) {
                        for (Id materialId : eventToMaterials.get(member.Event_vod__c)) {
                            populateSharesToUpsert(member, globalDescribe, 'EM_Event_Material_vod__Share', materialId, newGroupNameToGroupId, materialSharesToUpsert);
                        }
                    }
                }
            }

            List<SObject> toUpsert = new List<SObject>();
            // Add attendees separately due to potential large number of attendees (less than 2k)
            toUpsert.addAll(attendeeSharesToUpsert);
            if(!toUpsert.isEmpty()) {
                Database.insert(toUpsert, false);
            }

            // Add session attendees separately due to potential large number of attendees (less than 2k)
            toUpsert = new List<SObject>();
            toUpsert.addAll(sessionAttendeeSharesToUpsert);
            if(!toUpsert.isEmpty()) {
                Database.insert(toUpsert, false);
            }

            //Can only upsert 10 different types of objects
            toUpsert = new List<SObject>();
            toUpsert.addAll(eventSharesToUpsert);
            toUpsert.addAll(medicalEventSharesToUpsert);
            toUpsert.addAll(speakerSharesToUpsert);
            toUpsert.addAll(estimateSharesToUpsert);
            toUpsert.addAll(sessionSharesToUpsert);
            toUpsert.addAll(headerSharesToUpsert);
            toUpsert.addAll(budgetSharesToUpsert);
            toUpsert.addAll(historySharesToUpsert);
            toUpsert.addAll(materialSharestoUpsert);

            if(!toUpsert.isEmpty()) {
                Database.insert(toUpsert, false);
            }
        }
        private void addToDeleteList(Map<Id, Set<Id>> eventToUsers, String objToCheck, String parentEventField, String parentObj, List<Id> oldUser, List<Id> oldEvent, List<SObject> toDelete) {
            if (VOD_Utils.hasObject(objToCheck)) {
                List<SObject> resultList = Database.query('SELECT Id, Parent.' + parentEventField + ', UserOrGroupId FROM ' + objToCheck +
                                                          ' WHERE UserOrGroupId IN : oldUser AND ParentId IN ( ' +
                                                          ' SELECT Id FROM ' + parentObj + ' WHERE ' + parentEventField + ' IN : oldEvent)');
                for (SObject item : resultList) {
                    if (eventToUsers.get((Id) item.getSObject('Parent').get(parentEventField)).contains((Id) item.get('UserOrGroupId'))) {
                        toDelete.add(item);
                    }
                }
            }
        }
    	private void constructEventToRecordsMap(String objectToCheck, List<SObject> recordsList, Map<Id, Set<Id>> eventToRecordsMap){
            if (VOD_Utils.hasObject(objectToCheck)) {
                for(SObject record: recordsList){
                    String eventId = (String) record.get('Event_vod__c');
                    String recordId = (String) record.get('Id');
                    if(eventToRecordsMap.get(eventId) == null) {
                        eventToRecordsMap.put(eventId, new Set<Id>());
                    }
                    eventToRecordsMap.get(eventId).add(recordId);
                }
            }
        }

    	private void populateSharesToUpsert(EM_Event_Team_Member_vod__c member, Map<String, Schema.SObjectType> globalDescribe,
                                            String shareObjectName, String shareObjectParentId,
                                            Map<String, Id> newGroupNameToGroupId, List<SObject> sharesToUpsertList) {
            if(member.Team_Member_vod__c != null) {
                SObject shareObject = globalDescribe.get(shareObjectName).newSObject();
                shareObject.put('ParentId', shareObjectParentId);
                shareObject.put('UserOrGroupId', member.Team_Member_vod__c);
                shareObject.put('AccessLevel', 'edit');
                shareObject.put('RowCause', 'Event_Team_Member_vod__c');
                sharesToUpsertList.add(shareObject);
            } else if (member.Group_Name_vod__c != null) {
                Id groupUserId = newGroupNameToGroupId.get(member.Group_Name_vod__c);
                if (groupUserId != null) {
                    SObject shareObject = globalDescribe.get(shareObjectName).newSObject();
                    shareObject.put('ParentId', shareObjectParentId);
                    shareObject.put('UserOrGroupId', groupUserId);
                    shareObject.put('AccessLevel', 'edit');
                    shareObject.put('RowCause', 'Event_Team_Member_vod__c');
                    sharesToUpsertList.add(shareObject);
                }
            }
        }
}