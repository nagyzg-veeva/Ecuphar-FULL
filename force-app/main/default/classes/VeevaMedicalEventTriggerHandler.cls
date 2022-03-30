public class VeevaMedicalEventTriggerHandler extends VeevaTriggerHandler{

    private List<Medical_Event_vod__c> newMedicalEvents;
    private List<Medical_Event_vod__c> oldMedicalEvents;
    private Map<ID, Medical_Event_vod__c> newMedicalEventsMap;
    private Map<ID, Medical_Event_vod__c> oldMedicalEventsMap;

    protected override boolean doRecursionCheck() {
            return true;
    }

    protected override String sObjectType() {
        return 'Medical_Event_vod__c';
    }
    
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newMedicalEvents = (List<Medical_Event_vod__c>) triggerNew;
        oldMedicalEvents = (List<Medical_Event_vod__c>) triggerOld;
        newMedicalEventsMap = (Map<ID, Medical_Event_vod__c>) triggerNewMap;
        oldMedicalEventsMap = (Map<ID, Medical_Event_vod__c>) triggerOldMap;
    }
    
    protected override void beforeInsert() {
        vodMedicalEventLock();
        veevaMedicalEventConcurExpense();
    }
    
    protected override void beforeUpdate() {
        vodMedicalEventLock();
        veevaMedicalEventConcurExpense();
    }
    
    protected override void beforeDelete() {
        vodMedicalEventLock();
        vodMedicalEventBeforeDelete();
    }
    
    protected override void afterInsert() {
        vodMedicalEventAfterInsertUpdate();
    }
    
    protected override void afterUpdate() {
        vodMedicalEventAfterInsertUpdate();
    }
    
    private void veevaMedicalEventConcurExpense() {
        // If this is a Concur Update, then skip all trigger logic.
        if (VEEVA_CONCUR_UTILS.isConcurUpdate(oldMedicalEvents, newMedicalEvents)) {
            return;
        }

        // Mark off medical events as either needing a Concur Sync or not
        for (Medical_Event_vod__c medicalEvent : newMedicalEvents) {
            if(VEEVA_CONCUR_UTILS.concurSyncPending(medicalEvent)) {
                medicalEvent.Expense_Post_Status_vod__c = 'Pending';
            }
    	}
    }
    
    private void vodMedicalEventLock() {
        Set<String> associatedEvents = new Set<String>();
    	Set<String> lockedEvents = new Set<String>();

        if(trigger.isDelete) {
            for (Medical_Event_vod__c medEvent : oldMedicalEvents) {
                if (medEvent.EM_Event_vod__c != null) {
                    associatedEvents.add(medEvent.EM_Event_vod__c);
                }
            }        
        } else {
            for (Medical_Event_vod__c medEvent : newMedicalEvents) {
                if (medEvent.EM_Event_vod__c != null) {
                    associatedEvents.add(medEvent.EM_Event_vod__c);
                }
            }      
        }
        
        if(associatedEvents.size() > 0) {
            for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                       FROM EM_Event_vod__c
                                       WHERE Id IN :associatedEvents ]) {
                if (VOD_Utils.isEventLocked(event)) {
                    lockedEvents.add(event.Id);
                }
            }    
        }
        
        if(Trigger.isUpdate || Trigger.isInsert) {
            VOD_EVENT_UTILS.eventsWithOverrideLockTrue = new List<ID>();
            for (Medical_Event_vod__c medEvent : newMedicalEvents) {
                if(medEvent.Override_Lock_vod__c == true) {
                    medEvent.Override_Lock_vod__c = false;
                    //If medEvent's Override_Lock_vod__c is true, put its EM event into VOD_EVENT_UTILS.eventsWithOverrideLockTrue 
                    //which will be used to update event in trigger VOD_MEDICAL_EVENT_AFTER_INSERT_UPDATE
                    if (medEvent.EM_Event_vod__c != null){
                        VOD_EVENT_UTILS.eventsWithOverrideLockTrue.add(medEvent.EM_Event_vod__c);
                    }
                } else if (medEvent.EM_Event_vod__c != null && lockedEvents.contains(medEvent.EM_Event_vod__c)) {
                    medEvent.addError('Event is locked');
                }
            }        
        } else {
            for (Medical_Event_vod__c medEvent : oldMedicalEvents) {
                if (medEvent.EM_Event_vod__c != null && lockedEvents.contains(medEvent.EM_Event_vod__c)) {
                    medEvent.addError('Event is locked');
                }
            }       
        }
    }
    
    private void vodMedicalEventBeforeDelete() {
        VOD_ERROR_MSG_BUNDLE bundle = new VOD_ERROR_MSG_BUNDLE();
        Map <Id,Medical_Event_vod__c> medMap = new Map<Id,Medical_Event_vod__c> (
               [Select Id, EM_Event_vod__c, EM_Event_vod__r.Override_Lock_vod__c, EM_Event_vod__r.Lock_vod__c,
                       (Select Id From Call2_Discussion_vod__r LIMIT 1),
                       (Select Id From Call2_vod__r LIMIT 1),
                       (Select Id,Signature_Datetime_vod__c From Event_Attendee_vod__r WHERE Signature_Datetime_vod__c != null LIMIT 1)
                from Medical_Event_vod__c
                where Id in :Trigger.old]);
    
        for (Integer i = 0; i < Trigger.old.size(); i++) {
            Medical_Event_vod__c med = medMap.get(Trigger.old[i].Id);
    
            Integer k = 0;
            Integer j = 0;
    
            for (Call2_vod__c cal2 : med.Call2_vod__r) {
                k++;
            }
    
            for (Call2_Discussion_vod__c cal2 : med.Call2_Discussion_vod__r) {
                k++;
            }
    
            for (Event_Attendee_vod__c attendee : med.Event_Attendee_vod__r) {
                j++;
            }
    
            if (k > 0)
                Trigger.old[i].Id.addError(bundle.getErrorMsg('NO_DEL_MEDEVENT'), false);
    
            if (j > 0)
                Trigger.old[i].Id.addError(System.Label.NO_DEL_MEDEVENT_SIGNED, false);
        }
    }
    
    private void vodMedicalEventAfterInsertUpdate() {
        Map<String, Medical_Event_vod__c> emEventMap = new Map<String, Medical_Event_vod__c>();
        VOD_Utils.setTriggerMedicalEvent(true);
        for (Medical_Event_vod__c medEvent : newMedicalEvents) {
            if (medEvent.EM_Event_vod__c != null) {
                emEventMap.put(medEvent.EM_Event_vod__c, medEvent);
            }
        }
    
        if(emEventMap.values().size() > 0) {
            Set<String> groupNameSet = new Set<String>();
            for (EM_Event_Team_Member_vod__c member : [SELECT Group_Name_vod__c
                                                       FROM EM_Event_Team_Member_vod__c
                                                       WHERE Event_vod__c IN :emEventMap.keySet() AND Group_Name_vod__c != null]) {
                groupNameSet.add(member.Group_Name_vod__c);
            }
        
            Map<String, Id> groupNameToGroupId = new Map<String, Id>();
            for(Group publicGroup : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :groupNameSet]) {
                groupNameToGroupId.put(publicGroup.DeveloperName, publicGroup.Id);
            }
            
            Map<Id,Set<EM_Event_Team_Member_vod__c>> teamMemberMap = new Map<Id,Set<EM_Event_Team_Member_vod__c>>();
            for(EM_Event_Team_Member_vod__c member: [SELECT Id, Event_vod__c, Team_Member_vod__c, Group_Name_vod__c  FROM EM_Event_Team_Member_vod__c WHERE Event_vod__c IN :emEventMap.keySet()]) {                                           
                Set<EM_Event_Team_Member_vod__c> currentSet = teamMemberMap.get(member.Event_vod__c);
                if(currentSet == null) {
                    currentSet = new Set<EM_Event_Team_Member_vod__c>();
                }
                currentSet.add(member);
                teamMemberMap.put(member.Event_vod__c, currentSet); 
            }
            
            Map<Id, Set<Id>> eventToMembers = new Map<Id, Set<Id>>();
            for(Id eventId : emEventMap.keySet()) {
                if (teamMemberMap.get(eventId) != null) {
                    eventToMembers.put(eventId, new Set<Id>());
                    for (EM_Event_Team_Member_vod__c member : teamMemberMap.get(eventId)) {
                        if(member.Team_Member_vod__c != null) {
                            eventToMembers.get(eventId).add(member.Team_Member_vod__c);
                        } else if(member.Group_Name_vod__c != null) {
                            Id groupUserId = groupNameToGroupId.get(member.Group_Name_vod__c);
                            if(groupUserId != null) {
                                eventToMembers.get(eventId).add(groupUserId);
                            }
                        }
                    }
                }    
            }
            
        
            List<EM_Event_vod__c> updateEvent = new List<EM_Event_vod__c>();
            for (EM_Event_vod__c emEvent : [SELECT Id, Stub_SFDC_Id_vod__c, Override_Lock_vod__c, Lock_vod__c
                                            FROM EM_Event_vod__c
                                            WHERE Id IN :emEventMap.keySet()]) {
                boolean updateEventBool = false;
                Medical_Event_vod__c medEvent = emEventMap.get(emEvent.Id);
                if(Trigger.IsInsert) {
                    emEvent.Stub_SFDC_Id_vod__c = medEvent.Id;
                    updateEvent.add(emEvent);
                    updateEventBool = true;
                }
        
                if(!VOD_Utils.isTriggerEMEvent()) {
                    emEvent.Event_Display_Name_vod__c = medEvent.Event_Display_Name_vod__c;
                    if(!updateEventBool) {
                        updateEvent.add(emEvent);
                        updateEventBool = true;
                    }
                }      
            }
            if (!updateEvent.isEmpty()) {
                for(EM_Event_vod__c event: updateEvent){
                    if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue != null && VOD_EVENT_UTILS.eventsWithOverrideLockTrue.size() > 0 && VOD_EVENT_UTILS.eventsWithOverrideLockTrue.contains(event.Id)){
                        event.Override_Lock_vod__c = true;
                    }
                }
                if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue != null){
                   VOD_EVENT_UTILS.eventsWithOverrideLockTrue.clear(); 
                }
                update updateEvent;
            }
        
            if (VOD_Utils.hasObject('Medical_Event_vod__Share')) {
                List<SObject> newShares = new List<SObject>();
                if (Trigger.isUpdate) {
                    Map<Id, Medical_Event_vod__c> medicalEventMap = new Map<Id, Medical_Event_vod__c>();
                    for (Medical_Event_vod__c medicalEvent : newMedicalEvents) {
                        if (medicalEvent.EM_Event_vod__c != oldMedicalEventsMap.get(medicalEvent.Id).EM_Event_vod__c) {
                            medicalEventMap.put(medicalEvent.Id, medicalEvent);
                        }
                    }
                    if (!medicalEventMap.isEmpty()) {
                        Set<Id> medicalEventSet = medicalEventMap.keySet();
                        List<SObject> medicalEventShares = Database.query('SELECT Id FROM Medical_Event_vod__Share WHERE ParentId IN : medicalEventSet');
                        List<Database.DeleteResult> results = Database.delete(medicalEventShares, false);
                        for (Database.DeleteResult result: results) {
                            if (!result.isSuccess()) {
                             system.debug('Insert error: ' + result.getErrors()[0]);
                           }
                        }
                    }
        
                    for (Id medicalEventId : medicalEventMap.keySet()) {
                        Medical_Event_vod__c medicalEvent = medicalEventMap.get(medicalEventId);
                        if (eventToMembers.get(medicalEvent.EM_Event_vod__c) != null) {
                            for (Id memberId : eventToMembers.get(medicalEvent.EM_Event_vod__c)) {
                                SObject medicalEventShare = Schema.getGlobalDescribe().get('Medical_Event_vod__Share').newSObject();
                                medicalEventShare.put('ParentId', medicalEventId);
                                medicalEventShare.put('UserOrGroupId', memberId);
                                medicalEventShare.put('AccessLevel', 'edit');
                                medicalEventShare.put('RowCause', 'Event_Team_Member_vod__c');
                                newShares.add(medicalEventShare);
                            }
                        }
                    }
                } else {
                    for (Medical_Event_vod__c medicalEvent : newMedicalEvents) {
                        if (eventToMembers.get(medicalEvent.EM_Event_vod__c) != null) {
                            for (Id memberId : eventToMembers.get(medicalEvent.EM_Event_vod__c)) {
                                SObject medicalEventShare = Schema.getGlobalDescribe().get('Medical_Event_vod__Share').newSObject();
                                medicalEventShare.put('ParentId', medicalEvent.Id);
                                medicalEventShare.put('UserOrGroupId', memberId);
                                medicalEventShare.put('AccessLevel', 'edit');
                                medicalEventShare.put('RowCause', 'Event_Team_Member_vod__c');
                                newShares.add(medicalEventShare);
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
    }
}