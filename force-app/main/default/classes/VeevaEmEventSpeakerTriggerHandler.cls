public without sharing class VeevaEmEventSpeakerTriggerHandler extends VeevaTriggerHandler{
	private List<EM_Event_Speaker_vod__c> newEMEventSpeakers;
    private List<EM_Event_Speaker_vod__c> oldEMEventSpeakers;
    private Map<ID, EM_Event_Speaker_vod__c> newEMEventSpeakersMap;
    private Map<ID, EM_Event_Speaker_vod__c> oldEMEventSpeakersMap;
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'EM_Event_Speaker_vod__c';
    }
    
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newEMEventSpeakers = (List<EM_Event_Speaker_vod__c>) triggerNew;
        oldEMEventSpeakers = (List<EM_Event_Speaker_vod__c>) triggerOld;
        newEMEventSpeakersMap = (Map<ID, EM_Event_Speaker_vod__c>) triggerNewMap;
        oldEMEventSpeakersMap = (Map<ID, EM_Event_Speaker_vod__c>) triggerOldMap;
    }
    
    protected override void beforeInsert() {
        vodEmEventSpeakerBeforeInsertUpdateDelete();
    }
    
    protected override void beforeUpdate() {
        vodEmEventSpeakerBeforeInsertUpdateDelete();
    }
    
    protected override void beforeDelete() {
        vodEmEventSpeakerBeforeInsertUpdateDelete();
        vodEmEventSpeakerBeforeDelete();
    }
    
    protected override void afterInsert() {
        vodEmEventSpeakerAfterInsertUpdate();
        vodEmEventSpeakerRollup();
    }
    
    protected override void afterUpdate() {
        vodEmEventSpeakerAfterInsertUpdate();
        vodEmEventSpeakerRollup();
    }
    
    protected override void afterDelete() {
        vodEmEventSpeakerRollup();
    }
    
    private void vodEmEventSpeakerBeforeInsertUpdateDelete() {
        List<EM_Event_Speaker_vod__c> speakers;

        if (Trigger.isInsert || Trigger.isUpdate) {
            speakers = newEMEventSpeakers;

            if (Trigger.isInsert) {
                Map<String, EM_Event_Speaker_vod__c> eventSpeakers = new Map<String, EM_Event_Speaker_vod__c>();
                Map<String, List<String>> speakerToEventSpeakers = new Map<String, List<String>>();

                for(EM_Event_Speaker_vod__c speaker: speakers) {
                    if(speaker.Speaker_vod__c != null) {
                        eventSpeakers.put(speaker.Id, speaker);
                        if(speakerToEventSpeakers.get(speaker.Speaker_vod__c ) == null) {
                            speakerToEventSpeakers.put(speaker.Speaker_vod__c , new List<String>());
                        }
                        speakerToEventSpeakers.get(speaker.Speaker_vod__c ).add(speaker.Id);
                    }
                }
                for(EM_Speaker_vod__c speaker : [ SELECT Id, Tier_vod__c, Furigana_vod__c FROM EM_Speaker_vod__c WHERE Id IN :speakerToEventSpeakers.keySet() ]) {
                    for(String eventSpeakerId : speakerToEventSpeakers.get(speaker.Id)) {
                        EM_Event_Speaker_vod__c eventSpeaker = eventSpeakers.get(eventSpeakerId);
                        if(eventSpeaker != null) {
                            eventSpeaker.Tier_vod__c = speaker.Tier_vod__c;
                            eventSpeaker.Furigana_vod__c = speaker.Furigana_vod__c;
                        }
                    }
                }
            }
        } else {
            speakers = oldEMEventSpeakers;
        }
    	checkSpeakerOverrideLockAndEventLock(speakers, Trigger.isInsert || Trigger.isUpdate);
    }

    @TestVisible private void checkSpeakerOverrideLockAndEventLock(List<EM_Event_Speaker_vod__c> speakers, boolean isInsertOrUpdate) {
        Set<String> associatedEvents = new Set<String>();
        Set<String> lockedEvents = new Set<String>();
        // could be from newEMEventSpeakers or oldEMEventSpeakers
        for(EM_Event_Speaker_vod__c speaker: speakers) {
            if(speaker.Event_vod__c != null) {
                associatedEvents.add(speaker.Event_vod__c);
            }
        }

        for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                       FROM EM_Event_vod__c
                                       WHERE Id IN :associatedEvents AND Lock_vod__c = true]) {
            lockedEvents.add(event.Id);
        }
        if(isInsertOrUpdate) {
            VOD_EVENT_UTILS.eventsWithOverrideLockTrue = new List<ID>();
            for (EM_Event_Speaker_vod__c speaker : speakers) {
                if (speaker.Override_Lock_vod__c == true) {
                    speaker.Override_Lock_vod__c = false;
                    if (speaker.Event_vod__c != null) {
                        VOD_EVENT_UTILS.eventsWithOverrideLockTrue.add(speaker.Event_vod__c);
                    }
                } else if (speaker.Event_vod__c != null && lockedEvents.contains(speaker.Event_vod__c)) {
                    speaker.addError('Event is locked');
                }
            }
        } else {
            VOD_EVENT_UTILS.addErrorToLockedEventChildObject(speakers, lockedEvents);
        }
    }
    
    private void vodEmEventSpeakerAfterInsertUpdate() {
        if (!VOD_Utils.isTriggerEventAttendee()) {
            Map<String, String> statusMap = new Map<String, String>();
            statusMap.put('Invited_vod', 'Invited');
            statusMap.put('Accepted_vod', 'Accepted');
            statusMap.put('Rejected_vod', 'Rejected');
            statusMap.put('Attended_vod', 'Attended');

            VOD_Utils.setTriggerEmSpeaker(true);
            List<String> emEventIds = new List<String>();
            Map<String, EM_Event_Speaker_vod__c> emSpeakerMap = new Map<String, EM_Event_Speaker_vod__c>();
            for (EM_Event_Speaker_vod__c emSpeaker : newEMEventSpeakers) {
                emEventIds.add(emSpeaker.Event_vod__c);
                emSpeakerMap.put(emSpeaker.Id, emSpeaker);
            }
    
            Map<String,String> emEventsToMedEvents = new Map<String,String>();
            for (Medical_Event_vod__c eventStub : [SELECT Id, EM_Event_vod__c
                                                   FROM Medical_Event_vod__c
                                                   WHERE EM_Event_vod__c in :emEventIds]) {
                                                       emEventsToMedEvents.put(eventStub.EM_Event_vod__c, eventStub.Id);
                                                   }

            Map<String,String> rtNameToId = new Map<String,String>();
            for (RecordType rt : [SELECT Id, DeveloperName
                                  FROM RecordType
                                  WHERE SobjectType = 'Event_Attendee_vod__c']) {
                                      rtNameToId.put(rt.DeveloperName, rt.Id);
                                  }
        
            List<Event_Attendee_vod__c> attStubs = new List<Event_Attendee_vod__c>();
            if (Trigger.isInsert) {
                List<String> emSpeakerIds = new List<String>();
                for (EM_Event_Speaker_vod__c emSpeaker : newEMEventSpeakers) {
                    emSpeakerIds.add(emSpeaker.Speaker_vod__c);
                }
                Map<String,String> speakerToAccount = new Map<String,String>();
                for (EM_Speaker_vod__c speaker : [SELECT Id, Account_vod__c
                                                  FROM EM_Speaker_vod__c
                                                  WHERE Id IN :emSpeakerIds]) {
                                                      speakerToAccount.put(speaker.Id, speaker.Account_vod__c);
                                                  }

                for (EM_Event_Speaker_vod__c emSpeaker : newEMEventSpeakers) {
                    Event_Attendee_vod__c newStub = new Event_Attendee_vod__c(
                        Entity_Reference_Id_vod__c = emSpeaker.Entity_Reference_Id_vod__c,
                        Account_vod__c = speakerToAccount.get(emSpeaker.Speaker_vod__c),
                        Attendee_vod__c = emSpeaker.Speaker_Name_vod__c,
                        EM_Event_Speaker_vod__c = emSpeaker.Id,
                        Meal_Opt_In_vod__c = emSpeaker.Meal_Opt_In_vod__c,
                        Mobile_Id_vod__c = emSpeaker.Stub_Mobile_Id_vod__c,
                        Medical_Event_vod__c = emEventsToMedEvents.get(emSpeaker.Event_vod__c),
                        Signature_vod__c = emSpeaker.Signature_vod__c,
                        Signature_Datetime_vod__c = emSpeaker.Signature_Datetime_vod__c,
                        Override_Lock_vod__c = true
                    );
                    if (statusMap.get(emSpeaker.Status_vod__c) != null) {
                        newStub.Status_vod__c = statusMap.get(emSpeaker.Status_vod__c);
                    } else {
                        newStub.Status_vod__c = emSpeaker.Status_vod__c;
                    }
                    if (emSpeaker.RecordType != null && rtNameToId.get(emSpeaker.RecordType.DeveloperName) != null) {
                        newStub.RecordTypeId = rtNameToId.get(emSpeaker.RecordType.DeveloperName);
                    }
                    attStubs.add(newStub);
                }

                if(attStubs.size() > 0) {
                    insert attStubs;
                }
    
                Map<String, String> idToStubMap = new Map<String,String>();

                for(Event_Attendee_vod__c stub: attStubs) {
                    for (EM_Event_Speaker_vod__c speaker : newEMEventSpeakers) {
                        if(stub.EM_Event_Speaker_vod__c == speaker.Id) {
                            idtoStubMap.put(speaker.Id, stub.Id);
                        }
                    }
                }

                VOD_EVENT_UTILS.updateSpeakerStub(idToStubMap);

            } else if (Trigger.isUpdate) {
                Set<Id> changedSpeakerIds = new Set<Id>();

                Set<String> changeFields = new Set<String>();
                changeFields.add('Entity_Reference_Id_vod__c');
                changeFields.add('Account_vod__c');
                changeFields.add('Speaker_Name_vod__c');
                changeFields.add('Signature_vod__c');
                changeFields.add('Signature_Datetime_vod__c');
                changeFields.add('RecordTypeId');
                changeFields.add('Status_vod__c');
                changeFields.add('Meal_Opt_In_vod__c');

                for(EM_Event_Speaker_vod__c oldSpeaker: oldEMEventSpeakers) {
                    EM_Event_Speaker_vod__c newSpeaker = newEMEventSpeakersMap.get(oldSpeaker.Id);
                    for(String field: changeFields){
                        if(newSpeaker.get(field) != oldSpeaker.get(field)) {
                            changedSpeakerIds.add(newSpeaker.Id);
                            break;
                        }
                    }
                }
                if(changedSpeakerIds.size() > 0) {
                    for (Event_Attendee_vod__c attStub : [SELECT Account_vod__c, Contact_vod__c, User_vod__c, Attendee_vod__c,
                                                          Status_vod__c, EM_Event_Speaker_vod__c, Meal_Opt_In_vod__c,
                                                          Signature_vod__c, Signature_Datetime_vod__c, Entity_Reference_Id_vod__c
                                                          FROM Event_Attendee_vod__c
                                                          WHERE EM_Event_Speaker_vod__c IN :changedSpeakerIds]) {
                                                              EM_Event_Speaker_vod__c emSpeaker = emSpeakerMap.get(attStub.EM_Event_Speaker_vod__c);
                                                              attStub.Entity_Reference_Id_vod__c = emSpeaker.Entity_Reference_Id_vod__c;
                                                              attStub.Account_vod__c = emSpeaker.Account_vod__c;
                                                              attStub.Attendee_vod__c = emSpeaker.Speaker_Name_vod__c;
                                                              attStub.EM_Event_Speaker_vod__c = emSpeaker.Id;
                                                              attStub.Signature_vod__c = emSpeaker.Signature_vod__c;
                                                              attStub.Signature_Datetime_vod__c = emSpeaker.Signature_Datetime_vod__c;
                                                              attStub.Meal_Opt_In_vod__c = emSpeaker.Meal_Opt_In_vod__c;
                                                              attStub.Override_Lock_vod__c = true;
                                                              if (emSpeaker.RecordType != null && rtNameToId.get(emSpeaker.RecordType.DeveloperName) != null) {
                                                                  attStub.RecordTypeId = rtNameToId.get(emSpeaker.RecordType.DeveloperName);
                                                              }
                                                              if (statusMap.get(emSpeaker.Status_vod__c) != null) {
                                                                  attStub.Status_vod__c = statusMap.get(emSpeaker.Status_vod__c);
                                                              } else {
                                                                  attStub.Status_vod__c = emSpeaker.Status_vod__c;
                                                              }
                                                              attStubs.add(attStub);
                                                          }
                }
                if(attStubs.size() > 0) {
                    update attStubs;
                }
            }
        }
        if (VOD_Utils.hasObject('EM_Event_Speaker_vod__Share')) {
            List<SObject> newShares = new List<SObject>();
            Set<Id> eventIds = new Set<Id>();
            for (EM_Event_Speaker_vod__c speaker : newEMEventSpeakers) {
                eventIds.add(speaker.Event_vod__c);
            }
    
            Set<String> groupNameSet = new Set<String>();
            List<EM_Event_Team_Member_vod__c> members = [SELECT Id, Event_vod__c, Team_Member_vod__c, Group_Name_vod__c FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c IN : eventIds];
            for(EM_Event_Team_Member_vod__c member : members) {
                if(member.Group_Name_vod__c != null) {
                    groupNameSet.add(member.Group_Name_vod__c);    
                }          
            }

            Map<String, Id> groupNameToGroupId = new Map<String, Id>();
            for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
                groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
            }
    
            
            Map<Id, Set<Id>> eventToMembers = new Map<Id, Set<Id>>();
            for (EM_Event_Team_Member_vod__c member : members) {
                if (eventToMembers.get(member.Event_vod__c) == null) {
                    eventToMembers.put(member.Event_vod__c, new Set<Id>());
                }
                if(member.Team_Member_vod__c != null) {
                    eventToMembers.get(member.Event_vod__c).add(member.Team_Member_vod__c);
                } else if(member.Group_Name_vod__c != null) {
                    Id groupUserId = groupNameToGroupId.get(member.Group_Name_vod__c);
                    if(groupUserId != null) {
                        eventToMembers.get(member.Event_vod__c).add(groupUserId);
                    }
                }
            }

            if (Trigger.isUpdate) {
                Map<Id, EM_Event_Speaker_vod__c> speakerMap = new Map<Id, EM_Event_Speaker_vod__c>();
                for (EM_Event_Speaker_vod__c speaker : newEMEventSpeakers) {
                    if (speaker.Event_vod__c != oldEMEventSpeakersMap.get(speaker.Id).Event_vod__c) {
                        speakerMap.put(speaker.Id, speaker);
                    }
                }
                if (!speakerMap.isEmpty()) {
                    Set<Id> speakerSet = speakerMap.keySet();
                    List<SObject> speakerShares = Database.query('SELECT Id FROM EM_Event_Speaker_vod__Share WHERE ParentId IN : speakerSet');
                    List<Database.DeleteResult> results = Database.delete(speakerShares, false);
                    for (Database.DeleteResult result: results) {
                        if (!result.isSuccess()) {
                         system.debug('Insert error: ' + result.getErrors()[0]);
                       }
                    }
                }

                for (Id speakerId : speakerMap.keySet()) {
                    EM_Event_Speaker_vod__c speaker = speakerMap.get(speakerId);
                    if (eventToMembers.get(speaker.Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(speaker.Event_vod__c)) {
                            SObject speakerShare = Schema.getGlobalDescribe().get('EM_Event_Speaker_vod__Share').newSObject();
                            speakerShare.put('ParentId', speakerId);
                            speakerShare.put('UserOrGroupId', memberId);
                            speakerShare.put('AccessLevel', 'edit');
                            speakerShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(speakerShare);
                        }
                    }
                }
            } else {
                for (EM_Event_Speaker_vod__c speaker : newEMEventSpeakers) {
                    if (eventToMembers.get(speaker.Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(speaker.Event_vod__c)) {
                            SObject speakerShare = Schema.getGlobalDescribe().get('EM_Event_Speaker_vod__Share').newSObject();
                            speakerShare.put('ParentId', speaker.Id);
                            speakerShare.put('UserOrGroupId', memberId);
                            speakerShare.put('AccessLevel', 'edit');
                            speakerShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(speakerShare);
                        }
                    }
                }
            }
            List<Database.SaveResult> results = Database.insert(newShares, false);
            for (Database.SaveResult result: results) {
                if (!result.isSuccess()) {
                    system.debug('Insert error: ' + result.getErrors()[0]);
                }
            }
    	}
    }
    
    private void vodEmEventSpeakerBeforeDelete() {
        Set<String> associatedEvents = new Set<String>();
        Set<String> lockedEvents = new Set<String>();
        
        for (EM_Event_Speaker_vod__c speaker : oldEMEventSpeakers) {
            if (speaker.Event_vod__c != null) {
                associatedEvents.add(speaker.Event_vod__c);
            }
        }
        
        for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                       FROM EM_Event_vod__c
                                       WHERE Id IN :associatedEvents AND Lock_vod__c = true]) {
            lockedEvents.add(event.Id);
        }
        
        for (EM_Event_Speaker_vod__c speaker : oldEMEventSpeakers) {
            if (speaker.Event_vod__c != null && lockedEvents.contains(speaker.Event_vod__c)) {
                speaker.addError('Event is locked');
            }
        }
        
        for (Event_Attendee_vod__c[] deleteAttStubs :
            [SELECT Id FROM Event_Attendee_vod__c 
             WHERE EM_Event_Speaker_vod__c IN :Trigger.oldMap.keySet()]) {
            try {
                delete deleteAttStubs;
            } catch (System.DmlException e) {
                Integer numErrors = e.getNumDml();
                String error = '';
                for (Integer i = 0; i < numErrors; i++) {
                      Id thisId = e.getDmlId(i);
                      if (thisId != null)  {
                            error += e.getDmlMessage(i) +'\n';
                      }
                }
        
                for (EM_Event_Speaker_vod__c errorRec : oldEMEventSpeakers) {
                    errorRec.Id.addError(error);    
                }   
                        
            }
        }
    }
    
    private void vodEmEventSpeakerRollup() {
        Set<Id> speakersToRecalculate = new Set<Id>();
        Set<ID> eventIds = new Set<ID>();
        
        if(Trigger.isDelete) {
            for(EM_Event_Speaker_vod__c speaker: oldEMEventSpeakers) {
                eventIds.add(speaker.Event_vod__c);
            }    
        } else if (Trigger.isInsert) {
            for(EM_Event_Speaker_vod__c speaker: newEMEventSpeakers) {
                eventIds.add(speaker.Event_vod__c);
            }
        } else if (Trigger.IsUpdate) {
            for(EM_Event_Speaker_vod__c speaker: newEMEventSpeakers) {
                EM_Event_Speaker_vod__c oldSpeaker = oldEMEventSpeakersMap.get(speaker.Id);
                if(speaker.Meal_Opt_In_vod__c != oldSpeaker.Meal_Opt_In_vod__c || speaker.Status_vod__c != oldSpeaker.Status_vod__c) {
                    eventIds.add(speaker.Event_vod__c);
                }
            }
        }
    
    
        if(Trigger.isDelete) {
            for(EM_Event_speaker_vod__c speaker: oldEMEventSpeakers) {
                if(speaker.Speaker_vod__c != null) {
                    speakersToRecalculate.add(speaker.Speaker_vod__c);
                }
            }
        } else if (trigger.isUpdate) {
            for (EM_Event_Speaker_vod__c speaker : newEMEventSpeakers) {
                EM_Event_Speaker_vod__c oldSpeaker = oldEMEventSpeakersMap.get(speaker.Id);
                if((speaker.Speaker_vod__c != oldSpeaker.Speaker_vod__c) || (speaker.Status_vod__c != oldSpeaker.Status_vod__c)) {
                    speakersToRecalculate.add(oldSpeaker.Speaker_vod__c);
                    speakersToRecalculate.add(speaker.Speaker_vod__c);
                }
            }
        } else if (Trigger.isInsert) {
            for (EM_Event_Speaker_vod__c speaker : newEMEventSpeakers) {
                if (speaker.Speaker_vod__c != null) {
                    speakersToRecalculate.add(speaker.Speaker_vod__c);
                }
            }
        }
        if(!speakersToRecalculate.isEmpty()) {
            SpeakerYTDCalculator.calculate(speakersToRecalculate);
        }
    
        if(eventIds.size() > 0) {
            List<EM_Event_vod__c> eventsToUpdate = new List<EM_Event_vod__c>();
            eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
            setEventOverrideLock(eventsToUpdate);
            update eventsToUpdate;// needToCheck override lock
        }
    }

    @TestVisible private void setEventOverrideLock(List<EM_Event_vod__c> eventsToUpdate) {
        if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue != null && VOD_EVENT_UTILS.eventsWithOverrideLockTrue.size() > 0) {
            for(EM_Event_vod__c event: eventsToUpdate){
                if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue.contains(event.Id)){
                    event.Override_Lock_vod__c = true;
                }
            }
            VOD_EVENT_UTILS.eventsWithOverrideLockTrue.clear();
        }
    }
}