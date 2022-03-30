public class VeevaEventAttendeeTriggerHandler extends VeevaTriggerHandler{
	private List<Event_Attendee_vod__c > newEventAttendees;
    private List<Event_Attendee_vod__c > oldEventAttendees;
    private Map<ID, Event_Attendee_vod__c > newEventAttendeesMap;
    private Map<ID, Event_Attendee_vod__c > oldEventAttendeesMap;
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'Event_Attendee_vod__c';
    }
    
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newEventAttendees = (List<Event_Attendee_vod__c>) triggerNew;
        oldEventAttendees = (List<Event_Attendee_vod__c>) triggerOld;
        newEventAttendeesMap = (Map<ID, Event_Attendee_vod__c>) triggerNewMap;
        oldEventAttendeesMap = (Map<ID, Event_Attendee_vod__c>) triggerOldMap;
    }
    
    protected override void beforeInsert() {
        vodEventAttendeeLock();
        eventAttendee();
    }
    
    protected override void beforeUpdate() {
        vodEventAttendeeLock();
        eventAttendee();
    }
    
    protected override void beforeDelete() {
        vodEventAttendeeLock();
        eventAttendeeBeforeDelete();
    }
    
    protected override void afterInsert() {
        vodEventAttendeeAfterInsert();
    }
    
    protected override void afterUpdate() {
        vodEventAttendeeAfterInsert();
    }
        
    private void eventAttendeeBeforeDelete() {
        VOD_Utils.setTriggerEventAttendee(true);
        VOD_ERROR_MSG_BUNDLE bnd = new VOD_ERROR_MSG_BUNDLE ();
        
        Set<Id> emIds = new Set<Id>();
        for (Event_Attendee_vod__c attendee : oldEventAttendees) {
            if (attendee.Signature_Datetime_vod__c != null){
                attendee.addError(System.Label.NO_DEL_SIGNED_ATTENDEE, false);
                return;
            }
            if(attendee.EM_Attendee_vod__c != null) {
                emIds.add(attendee.EM_Attendee_vod__c);
            }
        }
        
        if(!emIds.isEmpty() && !VOD_Utils.isTriggerEmAttendee()) {
            List<EM_Attendee_vod__c> emAttendees = new List<EM_Attendee_vod__c>();
            for(Id attendeeId: emIds) {
                emAttendees.add(new EM_Attendee_vod__c(Id = attendeeId));
            }
            delete emAttendees;
        }
    }
    
    private void eventAttendee() {
        Set<String> accountIds = new Set<String>();
        Set<String> contactIds = new Set<String>();
        Set<String> userIds = new Set<String>();
        Set<String> childAccountIds = new Set<String>();
        // assumption is we will only get one of the below values per record (one of Entity Reference, Account, User, or Contact)
        for (Event_Attendee_vod__c eventAttendee : newEventAttendees) {
            if (eventAttendee.Entity_Reference_Id_vod__c != null) {
                eventAttendee.Account_vod__c = eventAttendee.Entity_Reference_Id_vod__c;
                accountIds.add(eventAttendee.Account_vod__c);
            } else if (eventAttendee.Account_vod__c != null) {
                accountIds.add(eventAttendee.Account_vod__c);
            } else if (eventAttendee.Contact_vod__c != null) {
                contactIds.add(eventAttendee.Contact_vod__c);
            } else if (eventAttendee.User_vod__c != null) {
                userIds.add(eventAttendee.User_vod__c);
            }
            if (eventAttendee.Child_Account_vod__c != null) {
                //if inserting a child account attendee through manage attendees, only Child_Account_vod__c will be populated (Account_vod__c gets populated below)
                //if updating a child account attendee, both Child_Account_vod__c and Account_vod__c will be populated
                childAccountIds.add(eventAttendee.Child_Account_vod__c);
            }
        }
    
        Map<Id, Account> accounts = new Map<Id, Account>();
        if (accountIds.size() > 0) {
            accounts = new Map<Id, Account>([Select Id,Name,Formatted_Name_vod__c,FirstName,LastName From Account Where Id In :accountIds]);
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        if (contactIds.size() > 0) {
            contacts = new Map<Id, Contact>([Select Id,Name,FirstName,LastName From Contact Where Id In :contactIds]);
        }
        Map<Id, User> users = new Map<Id, User>();
        if (userIds.size() > 0) {
            users = new Map<Id, User>([Select Id,Name,FirstName,LastName From User Where Id In :userIds]);
        }
        Map<Id, Child_Account_vod__c> childAccounts = new Map<Id, Child_Account_vod__c>();
        if (childAccountIds.size() > 0) {
            childAccounts = new Map<Id, Child_Account_vod__c>([Select Id,Parent_Child_Name_vod__c,Child_Account_vod__r.FirstName,Child_Account_vod__r.LastName,Child_Account_vod__c From Child_Account_vod__c Where Id In :childAccountIds]);
        }
    
        for (Event_Attendee_vod__c eventAttendee : newEventAttendees) {
            String attendeeName = '';
            String attendeeFirstName = '';
            String attendeeLastName = '';
            if (eventAttendee.Account_vod__c != null && eventAttendee.Child_Account_vod__c == null) {
                Account acct = accounts.get(eventAttendee.Account_vod__c);
                if (acct != null) {
                    if (acct.Formatted_Name_vod__c != null) {
                        attendeeName = acct.Formatted_Name_vod__c;
                    } else if (acct.LastName != null && acct.FirstName != null) {
                        attendeeName = acct.LastName + ', ' + acct.FirstName;
                    } else {
                        attendeeName = acct.Name;
                    }
    
                    if(acct.LastName != null) {
                        attendeeLastName = acct.LastName;
                    }
    
                    if(acct.FirstName != null) {
                        attendeeFirstName = acct.FirstName;
                    }
                }
            } else if (eventAttendee.Contact_vod__c != null) {
                Contact ctct = contacts.get(eventAttendee.Contact_vod__c);
                if (ctct != null) {
                    if (ctct.LastName != null && ctct.FirstName != null) {
                        attendeeName = ctct.LastName + ', ' + ctct.FirstName;
                    } else {
                        attendeeName = ctct.Name;
                    }
    
                    if(ctct.LastName != null) {
                        attendeeLastName = ctct.LastName;
                    }
    
                    if(ctct.FirstName != null) {
                        attendeeFirstName = ctct.FirstName;
                    }
                }
            } else if (eventAttendee.User_vod__c != null) {
                User usr = users.get(eventAttendee.User_vod__c);
                if (usr != null) {
                    if (usr.LastName != null && usr.FirstName != null) {
                        attendeeName = usr.LastName + ', ' + usr.FirstName;
                    } else {
                        attendeeName = usr.Name;
                    }
    
                    if(usr.LastName != null) {
                        attendeeLastName = usr.LastName;
                    }
    
                    if(usr.FirstName != null) {
                        attendeeFirstName = usr.FirstName;
                    }
                }
            } else if (eventAttendee.Child_Account_vod__c != null) {
                Child_Account_vod__c childAcc = childAccounts.get(eventAttendee.Child_Account_vod__c);
                if (childAcc != null) {
                    if (childAcc.Parent_Child_Name_vod__c != null) {
                        attendeeName = childAcc.Parent_Child_Name_vod__c;
                    }
                    if (childAcc.Child_Account_vod__c != null) {
                        eventAttendee.Account_vod__c = childAcc.Child_Account_vod__c;
                    }
                    Account acc = (Account)childAcc.getSObject('Child_Account_vod__r');
                    if (acc != null) {
                        if(acc.LastName != null) {
                            attendeeLastName = acc.LastName;
                        } else {
                            attendeeLastName = null;
                        }
    
                        if(acc.FirstName != null) {
                            attendeeFirstName = acc.FirstName;
                        } else {
                            attendeeFirstName = null;
                        }
                    }
                }
            }
            if (attendeeName != '') {
                Integer nameMaxLen = SObjectType.Event_Attendee_vod__c.Fields.Attendee_vod__c.Length;
                if (attendeeName.length() > nameMaxLen) {
                    attendeeName = attendeeName.substring(0, nameMaxLen);
                }
                eventAttendee.Attendee_vod__c = attendeeName;
            }
    
            if(attendeeFirstName != '') {
                eventAttendee.First_Name_vod__c = attendeeFirstName;
            }
    
            if(attendeeLastName != '') {
                if (attendeeLastName != null) {
                    Integer lastNameMaxLen = SObjectType.Event_Attendee_vod__c.Fields.Last_Name_vod__c.Length;
                    if (attendeeLastName.length() > lastNameMaxLen) {
                        attendeeLastName = attendeeLastName.substring(0, lastNameMaxLen);
                    }
                }
                eventAttendee.Last_Name_vod__c = attendeeLastName;
            }
        }    
    
        if(Trigger.IsInsert &&!VOD_Utils.isTriggerEmAttendee() && !VOD_Utils.isTriggerEmSpeaker()) {
            Map<String, String> statusMap = new Map<String, String>();
            statusMap.put('Invited', 'Invited_vod');
            statusMap.put('Accepted', 'Accepted_vod');
            statusMap.put('Rejected', 'Rejected_vod');
            statusMap.put('Attended', 'Attended_vod');
            Set<DescribeFieldResult> emFields = new Set<DescribeFieldResult>();
            Set<DescribeFieldResult> meFields = new Set<DescribeFieldResult>();
            String[] types = new String[]{'Event_Attendee_vod__c','EM_Attendee_vod__c'};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
    
            for(Schema.DescribeSObjectResult res :results) {
                Map<String,Schema.SObjectField> mfields = res.fields.getMap();
                for(Schema.SObjectField field: mfields.values()) {
                    DescribeFieldResult fDescribe = field.getDescribe();
                    if(fDescribe.isCustom() && !fDescribe.getName().endsWith('vod__c')) {
                        if(res.getName() == 'Event_Attendee_vod__c') {
                            meFields.add(fDescribe);
                        } else if(res.getName() == 'EM_Attendee_vod__c') {
                            emFields.add(fDescribe);
                        }
                    }
                }
            }
            Set<String> mappedFields = new Set<String>();
            for(DescribeFieldResult emDescribe: emFields) {
                for(DescribeFieldResult meDescribe: meFields) {
                    if(emDescribe.getName() == meDescribe.getName() && emDescribe.getType() == meDescribe.getType() &&
                     !(emDescribe.isCalculated() || meDescribe.isCalculated())) {
                        mappedFields.add(meDescribe.getName());
                        break;
                    }
                }
            }
    
            List<EM_Attendee_vod__c> emAtts = new List<EM_Attendee_vod__c>();
            List<EM_Event_Speaker_vod__c> emSpeakers = new List<EM_Event_Speaker_vod__c>();
            List<String> stubReferencedEmAtts = new List<String>();
            List<String> stubReferencedEmSpeakers = new List<String>();
            List<String> medEventIds = new List<String>();
            Map<String,Event_Attendee_vod__c> emIdsToStubs = new Map<String,Event_Attendee_vod__c>();
            Map<String,String> medEventIdsToEmEventIds = new Map<String,String>();
            Map<String, EM_Attendee_vod__c> emAttsStubMobileIdMap = new Map<String, EM_Attendee_vod__c>();
            Map<String, Event_Attendee_vod__c> eventAttsMobileIdMap = new Map<String, Event_Attendee_vod__c>();
    
            for (Event_Attendee_vod__c att : newEventAttendees) {
                if (att.Medical_Event_vod__c != null) {
                    medEventIds.add(att.Medical_Event_vod__c);
                }
            }
    
            if (medEventIds.size() > 0) {
                for (Medical_Event_vod__c medEvent : [SELECT Id, EM_Event_vod__c
                                                      FROM Medical_Event_vod__c
                                                      WHERE Id in :medEventIds AND EM_Event_vod__c != null]) {
                    medEventIdsToEmEventIds.put(medEvent.Id, medEvent.EM_Event_vod__c);
                }
            }
            Map<ID,Schema.RecordTypeInfo> eaRTMap = Event_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();
            // Get record type developer name instead of label
            Map<String,Schema.RecordTypeInfo> emRTMap = EM_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
            for (Integer i=0; i< newEventAttendees.size(); i++) {
                Event_Attendee_vod__c attStub = newEventAttendees[i];
                if (medEventIdsToEmEventIds.get(attStub.Medical_Event_vod__c) != null) {
                    if(attStub.Mobile_ID_vod__c == null) {
                        attStub.Mobile_ID_vod__c = GuidUtil.NewGuid();
                    }
                    EM_Attendee_vod__c newEmAtt = new EM_Attendee_vod__c(
                        Entity_Reference_Id_vod__c = attStub.Entity_Reference_Id_vod__c,
                        Account_vod__c = attStub.Account_vod__c,
                        Contact_vod__c = attStub.Contact_vod__c,
                        User_vod__c = attStub.User_vod__c,
                        Child_Account_vod__c = attStub.Child_Account_vod__c,
                        Attendee_Name_vod__c = attStub.Attendee_vod__c,
                        Signee_vod__c = attStub.Signee_vod__c,
                        Signature_Datetime_vod__c = attStub.Signature_Datetime_vod__c,
                        Signature_vod__c = attStub.Signature_vod__c,
                        Meal_Opt_In_vod__c = attStub.Meal_Opt_In_vod__c,
                        Event_vod__c = medEventIdsToEmEventIds.get(attStub.Medical_Event_vod__c),
                        Walk_In_Status_vod__c = attStub.Walk_In_Status_vod__c,
                        Address_Line_1_vod__c = attStub.Address_Line_1_vod__c,
                        Address_Line_2_vod__c = attStub.Address_Line_2_vod__c,
                        City_vod__c = attStub.City_vod__c,
                        Zip_vod__c = attStub.Zip_vod__c,
                        Phone_vod__c = attStub.Phone_vod__c,
                        Email_vod__c = attStub.Email_vod__c,
                        Prescriber_vod__c = attStub.Prescriber_vod__c,
                        First_Name_vod__c = attStub.First_Name_vod__c,
                        Last_Name_vod__c = attStub.Last_Name_vod__c,
                        Organization_vod__c = attStub.Organization_vod__c,
                        Stub_Mobile_ID_vod__c = attStub.Mobile_ID_vod__c,
                        Override_Lock_vod__c = true
                    );
                    //CRM-187623 make sure there will be no de-reference a null object
                    RecordTypeInfo eaInfo;
                    if (attStub.RecordTypeId != null && eaRTMap.get(attStub.RecordTypeId) != null) {
                        eaInfo = emRTMap.get(eaRTMap.get(attStub.RecordTypeId).getDeveloperName());
                    }
    
                    if(eaInfo != null && eaInfo.isAvailable()) {
                        newEmAtt.RecordTypeId = eaInfo.getRecordTypeId();
                    }
    
                    if (statusMap.get(attStub.Status_vod__c) != null) {
                        newEmAtt.Status_vod__c = statusMap.get(attStub.Status_vod__c);
                    } else {
                        newEmAtt.Status_vod__c = attStub.Status_vod__c;
                    }
                    for(String mfield: mappedFields) {
                        newEmAtt.put(mfield, attStub.get(mfield));
                    }
                    emAttsStubMobileIdMap.put(newEmAtt.Stub_Mobile_Id_vod__c, newEmAtt);
                    eventAttsMobileIdMap.put(attStub.Mobile_Id_vod__c, attStub);
                    emAtts.add(newEmAtt);
                }
            }
            List<String> stubMobileIdList = new List<String>(emAttsStubMobileIdMap.keySet());
            List<EM_Attendee_vod__c> stubMobileIdDuplicates = [SELECT Stub_Mobile_Id_vod__c FROM EM_Attendee_vod__c WHERE Stub_Mobile_Id_vod__c IN :stubMobileIdList];
            
            for(EM_Attendee_vod__c duplicate : stubMobileIdDuplicates) {
                Integer emAttsIndex;
                emAttsIndex = emAtts.indexOf(emAttsStubMobileIdMap.get(duplicate.Stub_Mobile_Id_vod__c));
                if(emAttsIndex != -1) {
                	emAtts.remove(emAttsIndex);
                }
            }
            if (emAtts.size() > 0) {
                List<Event_Attendee_vod__c> updateAttendees = new List<Event_Attendee_vod__c>();
                VOD_Utils.setTriggerEventAttendee(true);
                Database.SaveResult[] emAttResults = Database.insert(emAtts, false);
                for(integer i=0; i<emAttResults.size(); i++) {
                    Database.SaveResult createdEmAtt = emAttResults[i];
                    Event_Attendee_vod__c attStub = eventAttsMobileIdMap.get(emAtts.get(i).Stub_Mobile_ID_vod__c);
                    if (!createdEmAtt.isSuccess()) {
                        for (Database.Error err : createdEmAtt.getErrors()) { 
                            attStub.addError(err.getMessage());                    
                        }
                    } else if (createdEmAtt.getId() != null) {
                        attStub.EM_Attendee_vod__c = createdEmAtt.getId();
                    }
                }
                VOD_Utils.setTriggerEventAttendee(false);
            }
        }
    }
    
    private void vodEventAttendeeLock() {
        Map<String, String> attendeeToEvent = new Map<String, String>();
        Set<String> attendees = new Set<String>();
        Map<String, String> speakerToEvent = new Map<String, String>();
        Set<String> speakers = new Set<String>();
    
        if (Trigger.isUpdate || Trigger.isInsert) {
            for (Event_Attendee_vod__c eventAttendee : newEventAttendees) {
                if (eventAttendee.EM_Attendee_vod__c != null) {
                    attendees.add(eventAttendee.EM_Attendee_vod__c);
                } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                    speakers.add(eventAttendee.EM_Event_Speaker_vod__c);
                }
            }
        } else {
            for (Event_Attendee_vod__c eventAttendee : oldEventAttendees) {
                if (eventAttendee.EM_Attendee_vod__c != null) {
                    attendees.add(eventAttendee.EM_Attendee_vod__c);
                } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                    speakers.add(eventAttendee.EM_Event_Speaker_vod__c);
                }
            }
        }
    
        Set<Id> lockedEvents = new Set<Id>();
        for (EM_Attendee_vod__c attendee : [ SELECT Id, Event_vod__c, Event_vod__r.Override_Lock_vod__c, Event_vod__r.Lock_vod__c
                                             FROM EM_Attendee_vod__c
                                             WHERE Id IN :attendees ]) {
            if (attendee.Event_vod__c != null) {
                attendeeToEvent.put(attendee.Id, attendee.Event_vod__c);
                if (attendee.Event_vod__r.Lock_vod__c && !attendee.Event_vod__r.Override_Lock_vod__c) {
                    lockedEvents.add(attendee.Event_vod__c);
                }
            }
        }
    
        for (EM_Event_Speaker_vod__c speaker : [ SELECT Id, Event_vod__c, Event_vod__r.Override_Lock_vod__c, Event_vod__r.Lock_vod__c
                                                 FROM EM_Event_Speaker_vod__c
                                                 WHERE Id IN :speakers ]) {
            if (speaker.Event_vod__c != null) {
                speakerToEvent.put(speaker.Id, speaker.Event_vod__c);
                if (speaker.Event_vod__r.Lock_vod__c && !speaker.Event_vod__r.Override_Lock_vod__c) {
                    lockedEvents.add(speaker.Event_vod__c);
                }
            }
        }
    
        if (Trigger.isUpdate || Trigger.isInsert) {
            for (Event_Attendee_vod__c eventAttendee : newEventAttendees) {
                String id = null;
                if (eventAttendee.EM_Attendee_vod__c != null) {
                    id = attendeeToEvent.get(eventAttendee.EM_Attendee_vod__c);
                } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                    id = speakerToEvent.get(eventAttendee.EM_Event_Speaker_vod__c);
                }
                if(eventAttendee.Override_Lock_vod__c == true) {
                    eventAttendee.Override_Lock_vod__c = false;
                } else if (id != null && lockedEvents.contains(id)) {
                    eventAttendee.addError('Event is locked');
                }
            }
        } else {
            for (Event_Attendee_vod__c eventAttendee : oldEventAttendees) {
                String id = null;
                if (eventAttendee.EM_Attendee_vod__c != null) {
                    id = attendeeToEvent.get(eventAttendee.EM_Attendee_vod__c);
                } else if (eventAttendee.EM_Event_Speaker_vod__c != null) {
                    id = speakerToEvent.get(eventAttendee.EM_Event_Speaker_vod__c);
                }
                if (id != null && lockedEvents.contains(id)) {
                    eventAttendee.addError('Event is locked');
                }
            }
        }
    }
    
    private void vodEventAttendeeAfterInsert() {
        //Event Management logic
        if (!VOD_Utils.isTriggerEmAttendee() && !VOD_Utils.isTriggerEmSpeaker()) {
            if (Trigger.isInsert) {
                Map<String, String> idToStubMap = new Map<String,String>();
                for(Event_Attendee_vod__c attStub: newEventAttendees) {
                    if(attStub.EM_Attendee_vod__c != null) {
                        idToStubMap.put(attStub.EM_Attendee_vod__c, attStub.Id);
                    }
                }
                VOD_EVENT_UTILS.updateAttendeeStub(idToStubMap);
            } else if (Trigger.isUpdate) {
                Map<String, String> statusMap = new Map<String, String>();
                statusMap.put('Invited', 'Invited_vod');
                statusMap.put('Accepted', 'Accepted_vod');
                statusMap.put('Rejected', 'Rejected_vod');
                statusMap.put('Attended', 'Attended_vod');
                Set<DescribeFieldResult> emFields = new Set<DescribeFieldResult>();
                Set<DescribeFieldResult> meFields = new Set<DescribeFieldResult>();
                String[] types = new String[]{'Event_Attendee_vod__c','EM_Attendee_vod__c'};
                    Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
    
                for(Schema.DescribeSObjectResult res :results) {
                    Map<String,Schema.SObjectField> mfields = res.fields.getMap();
                    for(Schema.SObjectField field: mfields.values()) {
                        DescribeFieldResult fDescribe = field.getDescribe();
                        if(fDescribe.isCustom() && !fDescribe.getName().endsWith('vod__c')) {
                            if(res.getName() == 'Event_Attendee_vod__c') {
                                meFields.add(fDescribe);
                            } else if(res.getName() == 'EM_Attendee_vod__c') {
                                emFields.add(fDescribe);
                            }
                        }
                    }
                }
                Set<String> mappedFields = new Set<String>();
                for(DescribeFieldResult emDescribe: emFields) {
                    for(DescribeFieldResult meDescribe: meFields) {
                        if(emDescribe.getName() == meDescribe.getName() && emDescribe.getType() == meDescribe.getType() &&
                           !(emDescribe.isCalculated() || meDescribe.isCalculated())) {
                               mappedFields.add(meDescribe.getName());
                               break;
                           }
                    }
                }
    
                List<EM_Attendee_vod__c> emAtts = new List<EM_Attendee_vod__c>();
                List<EM_Event_Speaker_vod__c> emSpeakers = new List<EM_Event_Speaker_vod__c>();
                List<String> stubReferencedEmAtts = new List<String>();
                List<String> stubReferencedEmSpeakers = new List<String>();
                List<String> medEventIds = new List<String>();
                Map<String,Event_Attendee_vod__c> emIdsToStubs = new Map<String,Event_Attendee_vod__c>();
                Map<String,String> medEventIdsToEmEventIds = new Map<String,String>();
    
                for (Event_Attendee_vod__c att : newEventAttendees) {
                    if (att.Medical_Event_vod__c != null) {
                        medEventIds.add(att.Medical_Event_vod__c);
                    }
                }
    
                if (medEventIds.size() > 0) {
                    for (Medical_Event_vod__c medEvent : [SELECT Id, EM_Event_vod__c
                                                          FROM Medical_Event_vod__c
                                                          WHERE Id in :medEventIds AND EM_Event_vod__c != null]) {
                                                              medEventIdsToEmEventIds.put(medEvent.Id, medEvent.EM_Event_vod__c);
                                                          }
                }
                for (Event_Attendee_vod__c attStub : newEventAttendees) {
                    if (attStub.EM_Attendee_vod__c != null) {
                        stubReferencedEMAtts.add(attStub.EM_Attendee_vod__c);
                        emIdsToStubs.put(attStub.EM_Attendee_vod__c, attStub);
                    } else if (attStub.EM_Event_Speaker_vod__c != null) {
                        stubReferencedEmSpeakers.add(attStub.EM_Event_Speaker_vod__c);
                        emIdsToStubs.put(attStub.EM_Event_Speaker_vod__c, attStub);
                    }
                }
                if (medEventIdsToEmEventIds.size() > 0) {
                    Map<Id, EM_Event_vod__c> emEvents = new Map<Id, EM_Event_vod__c>([SELECT Id, (SELECT Id, Status_vod__c, Signature_vod__c, Signature_Datetime_vod__c, Meal_Opt_In_vod__c
                                                                                        FROM EM_Attendee_Event_vod__r WHERE Id IN : stubReferencedEMAtts),
                                                                                        (SELECT Id, Status_vod__c, Signature_vod__c, Signature_Datetime_vod__c, Meal_Opt_In_vod__c
                                                                                        FROM EM_Event_Speaker_vod__r WHERE Id IN : stubReferencedEmSpeakers)
                                                                                        FROM EM_Event_vod__c WHERE Id IN : medEventIdsToEmEventIds.values()]);
                    Map<Id, EM_Attendee_vod__c> attendeeMap = new Map<Id, EM_Attendee_vod__c>();
                    Map<Id, EM_Event_Speaker_vod__c> speakerMap = new Map<Id, EM_Event_Speaker_vod__c>();
                    for (Id eventId : emEvents.keySet()) {
                        EM_Event_vod__c emEvent = emEvents.get(eventId);
                        for (EM_Attendee_vod__c attendee : emEvent.EM_Attendee_Event_vod__r) {
                            attendeeMap.put(attendee.Id, attendee);
                        }
                        for (EM_Event_Speaker_vod__c speaker : emEvent.EM_Event_Speaker_vod__r) {
                            speakerMap.put(speaker.Id, speaker);
                        }
                    }
                    for (Id attendeeId : attendeeMap.keySet()) {
                        Event_Attendee_vod__c currAttStub = emIdsToStubs.get(attendeeId);
                        EM_Attendee_vod__c attendee = attendeeMap.get(attendeeId);
                        attendee.Attendee_Name_vod__c = currAttStub.Attendee_vod__c;
                        attendee.Signature_vod__c = currAttStub.Signature_vod__c;
                        attendee.Signature_Datetime_vod__c = currAttStub.Signature_Datetime_vod__c;
                        attendee.Meal_Opt_In_vod__c = currAttStub.Meal_Opt_In_vod__c;
                        if (currAttStub.Status_vod__c != oldEventAttendeesMap.get(currAttStub.Id).Status_vod__c) {
                            if (statusMap.get(currAttStub.Status_vod__c) != null) {
                                attendee.Status_vod__c = statusMap.get(currAttStub.Status_vod__c);
                            } else {
                                attendee.Status_vod__c = currAttStub.Status_vod__c;
                            }
                        }
                        attendee.Walk_In_Status_vod__c = currAttStub.Walk_In_Status_vod__c;
                        attendee.Address_Line_1_vod__c = currAttStub.Address_Line_1_vod__c;
                        attendee.Address_Line_2_vod__c = currAttStub.Address_Line_2_vod__c;
                        attendee.City_vod__c = currAttStub.City_vod__c;
                        attendee.Zip_vod__c = currAttStub.Zip_vod__c;
                        attendee.Phone_vod__c = currAttStub.Phone_vod__c;
                        attendee.Email_vod__c = currAttStub.Email_vod__c;
                        attendee.Prescriber_vod__c = currAttStub.Prescriber_vod__c;
                        attendee.First_Name_vod__c = currAttStub.First_Name_vod__c;
                        attendee.Last_Name_vod__c = currAttStub.Last_Name_vod__c;
                        attendee.Organization_vod__c = currAttStub.Organization_vod__c;
                        attendee.Override_Lock_vod__c = true;
                        emAtts.add(attendee);
                        for(String mfield: mappedFields) {
                            attendee.put(mfield, currAttStub.get(mfield));
                        }
                    }
                    if (emAtts.size() > 0) {
                        update emAtts;
                    }
                    for (Id speakerId : speakerMap.keySet()) {
                        Event_Attendee_vod__c currSpeakerStub = emIdsToStubs.get(speakerId);
                        EM_Event_Speaker_vod__c speaker = speakerMap.get(speakerId);
                        speaker.Signature_vod__c = currSpeakerStub.Signature_vod__c;
                        speaker.Signature_Datetime_vod__c = currSpeakerStub.Signature_Datetime_vod__c;
                        speaker.Meal_Opt_In_vod__c = currSpeakerStub.Meal_Opt_In_vod__c;
                        speaker.Override_Lock_vod__c = true;
                        if (currSpeakerStub.Status_vod__c != oldEventAttendeesMap.get(currSpeakerStub.Id).Status_vod__c) {
                            if (statusMap.get(currSpeakerStub.Status_vod__c) != null) {
                                speaker.Status_vod__c = statusMap.get(currSpeakerStub.Status_vod__c);
                            } else {
                                speaker.Status_vod__c = currSpeakerStub.Status_vod__c;
                            }
                        }
                        emSpeakers.add(speaker);
                    }
                    if (emSpeakers.size() > 0) {
                        update emSpeakers;
                    }
                }
            }
        }
    }
}