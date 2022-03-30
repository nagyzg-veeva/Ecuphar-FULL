trigger VEEVA_EMAIL_ACTIVITY_BEFORE_INSERT on Email_Activity_vod__c (before insert) {

    // get record type id for inferring open event
    RecordType emailActivityRecordType = [SELECT Id FROM RecordType WHERE SobjectType='Email_Activity_vod__c' AND DeveloperName = 'Email_Activity_vod'];

    // extracts anonymous id & original sent email id for each new coming email activity
    Set<Id> originalEmailIds = new Set<Id>();
    Set<String> anonymousIds = new Set<String>();
    // creates a map of anonymous id to original sent email record
    Map<String, Id> anonId2OriginalSE = new Map<String, Id>();
    // anonymous id should be appended to the end of Event_Msg_vod__c
    for(Email_Activity_vod__c newEvent : trigger.new) {
        String eventType = newEvent.Event_type_vod__c;
        String originalSeId = newEvent.Sent_Email_vod__c;
        originalEmailIds.add(originalSeId);
        // only get anonymous id for events that needs stub email
        if(newEvent.Event_Msg_vod__c != null && (eventType == 'Opened_vod' || eventType == 'Clicked_vod' || eventType == 'Viewed_vod' || eventType == 'Downloaded_vod')) {
            for(String part : newEvent.Event_Msg_vod__c.split('\\|')) {
                if(part.contains('anonymousId:')) {
                    String anonId = part.remove('anonymousId:');
                    anonymousIds.add(anonId);
                    anonId2OriginalSE.put(anonId, originalSeId);
                    break;
                }
            }
        }
    }

    // query all associated emails (original and stub emails)
    List<Sent_Email_vod__c> allAssocEmails = [SELECT Id, RecordTypeId, Approved_Email_Template_vod__c, Detail_Group_vod__c, Product_vod__c,
                                                Content_Type_vod__c, VExternal_Id_vod__c FROM Sent_Email_vod__c WHERE VExternal_Id_vod__c IN :anonymousIds OR Id IN :originalEmailIds];

    // maps anonId to the stub email record
    Map<String, Sent_Email_vod__c> stubEmails = new Map<String,Sent_Email_vod__c>();
    // maps sfdc id to the original email record
    Map<Id, Sent_Email_vod__c> originalEmails = new Map<Id,Sent_Email_vod__c>();
    for(Sent_Email_vod__c se : allAssocEmails) {
        if(se.VExternal_Id_vod__c != null && anonymousIds.contains(se.VExternal_Id_vod__c)) {
            // stub email
            stubEmails.put(se.VExternal_Id_vod__c, se);
        } else {
            originalEmails.put(se.Id, se);
        }
    }

    // create missing stub emails
    List<Sent_Email_vod__c> stubToCreate = new List<Sent_Email_vod__c>();
    for(String anonId : anonymousIds) {
        if(!stubEmails.containsKey(anonId)) {
            Id originalEmailId = anonId2OriginalSE.get(anonId);
            if(originalEmailId != null && originalEmails.containsKey(originalEmailId)) {
                Sent_Email_vod__c originalSE = originalEmails.get(originalEmailId);
                Sent_Email_vod__c newStubSE = new Sent_Email_vod__c (

                    // copy the following fields from original to stub
                    RecordTypeId = originalSE.RecordTypeId,
                    Approved_Email_Template_vod__c = originalSE.Approved_Email_Template_vod__c,
                    Detail_Group_vod__c = originalSE.Detail_Group_vod__c,
                    Product_vod__c = originalSE.Product_vod__c,
                    Content_Type_vod__c = originalSE.Content_Type_vod__c,

                    // add Anon Id as VExternal_Id_vod
                    VExternal_Id_vod__c = anonId,

                    // set status as Delivered
                    Status_vod__c = 'Delivered_vod'
                );
                stubToCreate.add(newStubSE);
            }
        }
    }
    if(stubToCreate.size() > 0) {
        insert stubToCreate;
        for(Sent_Email_vod__c created : stubToCreate) {
            // add the new stubs to the list of stub emails
            stubEmails.put(created.VExternal_Id_vod__c, created);
        }
    }

    // set of sent email id which has a new open event
    Set<Id> seWithNewOpenRecord = new Set<Id>();
    // Sent_Email_vod.Id map to the clicked email activity (that might infer an open activity)
    Map<Id, Email_Activity_vod__c> seWithNewClickRecord = new Map<Id, Email_Activity_vod__c>();
    // update email activity for anonymous tracking
    for(Email_Activity_vod__c newEvent : trigger.new) {
        // extract anonymous id
        String anonId = null;
        if(newEvent.Event_Msg_vod__c != null) {
            for(String part : newEvent.Event_Msg_vod__c.split('\\|')) {
                if(part.contains('anonymousId:')) {
                    anonId = part.remove('anonymousId:');
                }
            }
        }
        String eventType = newEvent.Event_type_vod__c;

        if(anonId != null && anonId.length() > 0) {
            // original sent email has enabled anonymous tracking
            if (eventType == 'Opened_vod' || eventType == 'Clicked_vod' || eventType == 'Viewed_vod' || eventType == 'Downloaded_vod') {

                // stamp these events under stub email
                Sent_Email_vod__c stubEmail = stubEmails.get(anonId);
                if(stubEmail != null) {
                    newEvent.Sent_Email_vod__c = stubEmail.Id;
                }

                // do not stamp any values in the following fields
                newEvent.Event_Msg_vod__c = null;
                newEvent.IP_Address_vod__c = null;
                newEvent.Click_URL_vod__c = null;
                newEvent.User_Agent_vod__c = null;

            } else if(eventType == 'Delivered_vod' || eventType == 'Bounced_vod' || eventType == 'Dropped_vod' ||
                        eventType == 'Unsubscribe_vod' || eventType == 'Unsubscribed_All_vod' || eventType == 'Marked_as_Spam_vod') {
                // stamp under original sent email record; however, clear event msg
                newEvent.Event_Msg_vod__c = null;
            }
        }

        // skip this se when check for infer open, as there's a new open being created
        if(eventType == 'Opened_vod') {
            seWithNewOpenRecord.add(newEvent.Sent_Email_vod__c);
        }

        // add id after we update the parent Sent_Email_vod lookup
        // any inferred open event for anonymous tracking has to be created under stub email if needed
        if(eventType == 'Clicked_vod') {
            seWithNewClickRecord.put(newEvent.Sent_Email_vod__c, newEvent);
        }
    }

    List<Email_Activity_vod__c> openEventsToCreate = new List<Email_Activity_vod__c>();
    for(Email_Activity_vod__c eventWithOpen : [SELECT Id, Sent_Email_vod__c, Event_type_vod__c FROM Email_Activity_vod__c
                                                      WHERE Sent_Email_vod__c IN :seWithNewClickRecord.keySet()
                                                        AND Sent_Email_vod__c NOT IN :seWithNewOpenRecord
                                                        AND Event_type_vod__c = 'Opened_vod']) {
        // remove sent email id for those emails that have open event from list
        seWithNewClickRecord.remove(eventWithOpen.Sent_Email_vod__c);
    }

    if(seWithNewClickRecord.size() > 0) {
        // we need to infer open event for these click events
        for(Email_Activity_vod__c clickEvent : seWithNewClickRecord.values()) {
            Email_Activity_vod__c openEvent = new Email_Activity_vod__c (

                // set record type to Email Activity and event type to Opened
                RecordTypeId = emailActivityRecordType.Id,
                Event_type_vod__c = 'Opened_vod',

                // use same values as the click event for following fields
                Sent_Email_vod__c = clickEvent.Sent_Email_vod__c,
                Activity_DateTime_vod__c = clickEvent.Activity_DateTime_vod__c,
                City_vod__c = clickEvent.City_vod__c,
                User_Agent_vod__c = clickEvent.User_Agent_vod__c,
                Client_Name_vod__c = clickEvent.Client_Name_vod__c,
                Client_OS_vod__c = clickEvent.Client_OS_vod__c,
                Client_Type_vod__c = clickEvent.Client_Type_vod__c,
                Country_vod__c = clickEvent.Country_vod__c,
                Device_Type_vod__c = clickEvent.Device_Type_vod__c,
                IP_Address_vod__c = clickEvent.IP_Address_vod__c,
                Region_vod__c = clickEvent.Region_vod__c
            );
            openEventsToCreate.add(openEvent);
        }

        insert openEventsToCreate;
    }
}