public without sharing class VeevaEmAttendeeTriggerHandler extends VeevaTriggerHandler {

    private List<EM_Attendee_vod__c> newAttendees = new List<EM_Attendee_vod__c>();
    private List<EM_Attendee_vod__c> oldAttendees = new List<EM_Attendee_vod__c>();
    private Map<ID, EM_Attendee_vod__c> newAttendeesMap = new Map<ID, EM_Attendee_vod__c>();
    private Map<ID, EM_Attendee_vod__c> oldAttendeesMap = new Map<ID, EM_Attendee_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newAttendees = (List<EM_Attendee_vod__c>) triggerNew;
        this.oldAttendees = (List<EM_Attendee_vod__c>) triggerOld;
        this.newAttendeesMap = (Map<ID, EM_Attendee_vod__c>) triggerNewMap;
        this.oldAttendeesMap = (Map<ID, EM_Attendee_vod__c>) triggerOldMap;
    }
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'EM_Attendee_vod__c';
    }

    protected override void beforeInsert() {
        vodEmAttendeeLock();
        vodEmAttendeeBeforeInsUpd();
    }
    
    protected override void beforeUpdate() {
        vodEmAttendeeLock();
        vodEmAttendeeBeforeInsUpd();
    }
    
    protected override void beforeDelete() {
        vodEmAttendeeLock();
        vodEmAttendeeBeforeDel();
    }
    
    protected override void afterInsert() {
        vodEmAttendeeAfterInsertUpdate();
        vodEmAttendeeAfterInsUpd();
        vodEmAttendeeCountRollupInsert();
    }
    
    protected override void afterUpdate() {
        vodEmAttendeeAfterInsertUpdate();
        vodEmAttendeeAfterInsUpd();
        vodEmAttendeeCountRollupUpdate();
    }
    
    protected override void afterDelete() {
        vodEmAttendeeCountRollupDelete();
    }

    private void vodEmAttendeeLock() {
        Set<String> associatedEvents = new Set<String>();
        Set<String> lockedEvents = new Set<String>();

        if (Trigger.isInsert || Trigger.isUpdate) {
            for (EM_Attendee_vod__c attendee : newAttendees) {
                if (attendee.Event_vod__c != null) {
                    associatedEvents.add(attendee.Event_vod__c);
                }
            }
        } else {
            for (EM_Attendee_vod__c attendee : oldAttendees) {
                if (attendee.Event_vod__c != null) {
                    associatedEvents.add(attendee.Event_vod__c);
                }
            }
        }

        for (EM_Event_vod__c event : [ SELECT Id, Override_Lock_vod__c, Lock_vod__c
                                    FROM EM_Event_vod__c
                                    WHERE Id IN :associatedEvents ]) {
            if (VOD_Utils.isEventLocked(event)) {
                lockedEvents.add(event.Id);
            }
        }

        if (Trigger.isInsert || Trigger.isUpdate) {
            VOD_EVENT_UTILS.eventsWithOverrideLockTrue = new List<ID>();
            for (EM_Attendee_vod__c attendee : newAttendees) {
                if (attendee.Override_Lock_vod__c == true) {
                    attendee.Override_Lock_vod__c = false;
                    //If attendee's Override_Lock_vod__c is true, put its event into VOD_EVENT_UTILS.eventsWithOverrideLockTrue 
                    //which will be used to update event in trigger VOD_EM_ATTENDEE_COUNT_ROLLUP_UPDATE
                    if (attendee.Event_vod__c != null) {
                        VOD_EVENT_UTILS.eventsWithOverrideLockTrue.add(attendee.Event_vod__c);
                    }
                } else if (attendee.Event_vod__c != null && lockedEvents.contains(attendee.Event_vod__c)) {
                    attendee.addError('Event is locked');
                }
            }
        } else {
            for (EM_Attendee_vod__c attendee : oldAttendees) {
                if (attendee.Event_vod__c != null && lockedEvents.contains(attendee.Event_vod__c)) {
                    attendee.addError('Event is locked');
                }
            }
        }
    }

    private void vodEmAttendeeBeforeDel() {
        VOD_Utils.setTriggerEmAttendee(true);
        if(!VOD_Utils.isTriggerEventAttendee()) {
            for (Event_Attendee_vod__c[] deleteAttStubs :[SELECT Id FROM Event_Attendee_vod__c 
                WHERE EM_Attendee_vod__c IN :oldAttendeesMap.keySet()]) {
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
                    
                    for (EM_Attendee_vod__c errorRec : oldAttendees) {
                        errorRec.Id.addError(error);    
                    }   
                    
                }
            }         
        }
    }

    private void vodEmAttendeeCountRollupDelete() {
        Set<ID> eventIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: oldAttendees) {
            if(attendee.Event_vod__c != null) {
                eventIds.add(attendee.Event_vod__c);
            }
        }
        
        //CRM-190304 The size of eventIds should be larger than 0
        if (eventIds.size() > 0) {
            List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
            
            if(eventsToUpdate.size() > 0) {
                update eventsToUpdate;
            }        
        }   
    }

    private void vodEmAttendeeBeforeInsUpd() {
        Set<ID> contactIds = new Set<ID>();
        Set<ID> userIds = new Set<ID>();
        Set<ID> accountIds = new Set<ID>();
        Set<ID> walkInIds = new Set<ID>();
        Set<ID> childAccountIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: newAttendees) {
            contactIds.add(attendee.Contact_vod__c);
            userIds.add(attendee.User_vod__c);
            if (attendee.Entity_Reference_Id_vod__c != null) {
                attendee.Account_vod__c = attendee.Entity_Reference_Id_vod__c;
                attendee.Entity_Reference_Id_vod__c = null;
            }

            if (attendee.Walk_In_Reference_ID_vod__c != null //not null
                && VOD_Utils.matchesSfdcId(attendee.Walk_In_Reference_ID_vod__c) //matches SFDC Id pattern regex
                && attendee.Walk_In_Reference_ID_vod__c.startsWith(Schema.SObjectType.Account.getKeyPrefix())) { //matches Account key prefix
                walkInIds.add(attendee.Walk_In_Reference_ID_vod__c);
            }
            accountIds.add(attendee.Account_vod__c);
            childAccountIds.add(attendee.Child_Account_vod__c);
        }
        
        Map<String, List<String>> emailMap = new Map<String, List<String>>();		          
        String[] types = new String[]{'Account','Address_vod__c', 'User'};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        for(Schema.DescribeSobjectResult res : results) {
            List<String> emailFields = new List<String>();
            SObjectType currType = res.getSObjectType();
            Map<String,Schema.SObjectField> mfields = currType.getDescribe().fields.getMap();
            for(Schema.SObjectField field: mfields.values()) {
                if(field.getDescribe().getType().equals(Schema.DisplayType.EMAIL)) {
                    emailFields.add(field.getDescribe().getName());
                }
            }
            emailMap.put(res.getName(), emailFields);
        }
        
        Map<Id, Child_Account_vod__c> childAccounts = new Map<Id, Child_Account_vod__c>();
        for (Child_Account_vod__c ca : [SELECT Id, Child_Account_vod__c, Parent_Child_Name_vod__c FROM Child_Account_vod__c WHERE Id in :childAccountIds]) {
            childAccounts.put(ca.Id, ca); //create child account map
            if (!accountIds.contains(ca.Child_Account_vod__c)) {
                accountIds.add(ca.Child_Account_vod__c); //add child account id's into the set
            }
        }
        Map<Id, Contact> contacts = new Map<Id, Contact>([Select Id, FirstName, LastName, Name FROM Contact WHERE Id in :contactIds]);
        Map<Id, User> users = new Map<Id, User>([Select Id, FirstName, LastName, Name FROM User WHERE Id in :userIds]);
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Formatted_Name_vod__c, FirstName, LastName, PersonTitle, Credentials_vod__c, Name, Furigana_vod__c FROM Account WHERE Id in :accountIds]);
        Map<Id, Account> existingWalkInAccounts = new Map<Id, Account>([SELECT Id FROM Account WHERE Id in :walkInIds]);

        Events_Management_Settings_vod__c emSetting = Events_Management_Settings_vod__c.getOrgDefaults();
        Integer autoMatchMode = 1;

        if(emSetting.Attendee_Automatch_Mode_vod__c != null) {
            autoMatchMode = emSetting.Attendee_Automatch_Mode_vod__c.intValue();
        }

        for (EM_Attendee_vod__c emAtt : newAttendees) {
            String lastName = '';
            String firstName = '';
            if(Trigger.isInsert && autoMatchMode == 1 && (emAtt.Walk_In_Status_vod__c == 'Needs_Reconciliation_vod' || emAtt.Online_Registration_Status_vod__c == 'Needs_Reconciliation_vod')) {
                //Find Matching Accounts
                List<sObject> matchAccounts = new List<sObject>();
                List<String> accountEmails = emailMap.get('Account');
                List<String> addressEmails = emailMap.get('Address_vod__c');
                String accountQuery = 'SELECT Id, LastName, FirstName';
                boolean hasAccountEmail = false;
                boolean hasAccountName = false;
                boolean hasAddressEmail = false;
                String attendeeLastName = emAtt.Last_Name_vod__c;
                String accountClause = '';
                if(attendeeLastName != null) {
                    if(attendeeLastName.length() <= 2) {
                        accountClause += ' LastName = \'' + String.escapeSingleQuotes(attendeeLastName) + '\' AND (';
                    } else {
                        accountClause += ' LastName Like \'' + String.escapeSingleQuotes(attendeeLastName.subString(0,3)) + '%\' AND (';
                    }
                } else {
                    continue;
                }

                if(!accountEmails.isEmpty()) {
                    if(emAtt.Email_vod__c != null) {
                        hasAccountEmail = true;
                    }
                    for(Integer i = 0; i < accountEmails.size(); i++) {
                        String fieldName = accountEmails.get(i);
                        accountQuery += ',' + fieldName;
                        if(hasAccountEmail) {
                            accountClause += '(' + fieldName + '=\'' + emAtt.Email_vod__c + '\')';
                            if(i+1 != accountEmails.size()) {
                                accountClause += ' OR ';
                            }
                        }
                    }
                }

                accountQuery += ' FROM Account WHERE ' + accountClause;

                if(emAtt.First_Name_vod__c != null && emAtt.Last_Name_vod__c != null) {
                    if(hasAccountEmail) {
                        accountQuery += ' OR ';
                    }
                    hasAccountName = true;
                    accountQuery += '(FirstName = \'' + String.escapeSingleQuotes(emAtt.First_Name_vod__c) + '\' AND LastName = \'' + String.escapeSingleQuotes(emAtt.Last_Name_vod__c) + '\')';
                }

                if(!addressEmails.isEmpty()) {
                    List<sObject> matchAddresses = new List<sObject>();
                    String addressQuery = 'SELECT Account_vod__c FROM Address_vod__c WHERE';
                    if(attendeeLastName.length() <= 2) {
                        addressQuery += ' Account_vod__c IN (SELECT Id From Account WHERE LastName = \'' + String.escapeSingleQuotes(attendeeLastName) + '\') AND (';
                    } else {
                        addressQuery += ' Account_vod__c IN (SELECT Id From Account WHERE LastName LIKE \'' + String.escapeSingleQuotes(attendeeLastName.subString(0,3)) + '%\') AND (';
                    }

                    for(Integer i = 0; i < addressEmails.size(); i++) {
                        addressQuery += ' (' + addressEmails.get(i) + '=\'' + emAtt.Email_vod__c + '\')';
                        if(i+1 != addressEmails.size()) {
                            addressQuery += ' OR ';
                        }
                    }
                    addressQuery += ')';
                    matchAddresses = Database.query(addressQuery);
                    if(!matchAddresses.isEmpty()) {
                        hasAddressEmail = true;
                        String addressIds = '(';
                        for(Integer i = 0; i < matchAddresses.size(); i++) {
                            SObject match = matchAddresses.get(i);
                            addressIds += '\'' + match.get('Account_vod__c') + '\'';
                            if(i+1 != matchAddresses.size()) {
                                addressIds += ',';
                            }
                        }
                        addressIds += ')';

                        if(hasAccountName || hasAccountEmail) {
                            accountQuery += ' OR ';
                        }
                        accountQuery += '(Id IN ' + addressIds + ')';
                    }
                }

                if(hasAccountName || hasAccountEmail || hasAddressEmail) {
                    accountQuery += ')';
                    matchAccounts = DataBase.query(accountQuery);
                }

                List<sObject> accountEmailMatches = new List<sObject>();
                List<sObject> accountNameMatches = new List<sObject>();
                for(SObject match: matchAccounts) {
                    boolean emailFound = false;
                    for(String email : accountEmails) {
                        if(match.get(email) == emAtt.Email_vod__c) {
                            accountEmailMatches.add(match);
                            emailFound = true;
                            break;
                        }
                    }
                    if(!emailFound){
                        accountNameMatches.add(match);
                    }
                }

                //Find Matching Users
                List<sObject> matchUsers = new List<sObject>();
                List<String> userEmails = emailMap.get('User');
                boolean hasUserEmail = false;
                boolean hasUserName = false;
                String userQuery = 'SELECT Id, LastName, FirstName';
                String userClause = '';
                if(!userEmails.isEmpty()) {
                    if(emAtt.Email_vod__c != null) {
                        hasUserEmail = true;
                    }
                    for(Integer i = 0; i < userEmails.size(); i++) {
                        String fieldName = userEmails.get(i);
                        userQuery += ',' + fieldName;
                        if(hasUserEmail) {
                            userClause += ' (' + fieldName  + '=\'' + emAtt.Email_vod__c + '\')';
                            if(i+1 != userEmails.size()) {
                                userClause += ' OR';
                            }
                        }
                    }
                }

                userQuery += ' FROM User WHERE ' + userClause;
                if(emAtt.First_Name_vod__c != null && emAtt.Last_Name_vod__c != null) {
                    hasUserName = true;
                    if(hasUserEmail) {
                        userQuery += ' OR ';
                    }
                    userQuery += '(FirstName =\'' + String.escapeSingleQuotes(emAtt.First_Name_vod__c) + '\' AND LastName = \'' + String.escapeSingleQuotes(emAtt.Last_Name_vod__c) + '\')';
                }

                if(hasUserEmail || hasUserName) {
                    matchUsers = DataBase.query(userQuery);
                }

                List<sObject> userEmailMatches = new List<sObject>();
                List<sObject> userNameMatches = new List<sObject>();
                for(SObject match: matchUsers) {
                    boolean emailFound = false;
                    for(String email : userEmails) {
                        if(match.get(email) == emAtt.Email_vod__c) {
                            userEmailMatches.add(match);
                            emailFound = true;
                            break;
                        }
                    }
                    if(!emailFound){
                        userNameMatches.add(match);
                    }
                }

                sobject match = null;
                ID walkInId = null;

                //Associate match if strong
                if(accountEmailMatches.size() == 1 && userEmailMatches.isEmpty()) {
                    match = accountEmailMatches.get(0);
                    walkInId = (Id)match.get('Id');
                    existingWalkInAccounts.put(walkInId, (Account)match);
                    emAtt.Walk_In_Reference_ID_vod__c = walkInId;
                    
                    if(emAtt.Walk_In_Status_vod__c != null){
                        emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
                    } else if (emAtt.Online_Registration_Status_vod__c != null) {
                        emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
                    }
                } else if(userEmailMatches.size() == 1 && accountEmailMatches.isEmpty()) {
                    match = userEmailMatches.get(0);
                    emAtt.Walk_In_Reference_ID_vod__c = (Id)match.get('Id');
                    if(emAtt.Walk_In_Status_vod__c != null){
                        emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                    } else if (emAtt.Online_Registration_Status_vod__c != null) {
                        emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                    }
                } else if(accountNameMatches.size() == 1 && userNameMatches.isEmpty()) {
                    match = accountNameMatches.get(0);
                    walkInId = (Id)match.get('Id');
                    existingWalkInAccounts.put(walkInId, (Account)match);
                    emAtt.Walk_In_Reference_ID_vod__c = walkInId;
                    if(emAtt.Walk_In_Status_vod__c != null){
                        emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
                    } else if (emAtt.Online_Registration_Status_vod__c != null) {
                        emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_Account_vod';
                    }
                } else if(userNameMatches.size() == 1 && accountNameMatches.isEmpty()) {
                    match = userNameMatches.get(0);
                    emAtt.Walk_In_Reference_ID_vod__c = (Id)match.get('Id');
                    if(emAtt.Walk_In_Status_vod__c != null){
                        emAtt.Walk_In_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                    } else if (emAtt.Online_Registration_Status_vod__c != null) {
                        emAtt.Online_Registration_Status_vod__c = 'Reconciled_To_Existing_User_vod';
                    }
                } else {
                    if(emAtt.First_Name_vod__c != null) {
                        firstName = emAtt.First_Name_vod__c;
                    }
                    if(emAtt.Last_Name_vod__c != null) {
                        lastName = emAtt.Last_Name_vod__c;
                    }
                }

                if(match != null) {
                    if(match.get('LastName') != null) {
                        lastName = (String)match.get('LastName');
                    }
                    if(match.get('firstName') != null) {
                        firstName = (String)match.get('FirstName');
                    }
                }
            } else {
                if(emAtt.First_Name_vod__c != null) {
                    firstName = emAtt.First_Name_vod__c;
                }
                if(emAtt.Last_Name_vod__c != null) {
                    lastName = emAtt.Last_Name_vod__c;
                }
            }

            if(emAtt.Stub_Mobile_Id_vod__c == null) {
                emAtt.Stub_Mobile_Id_vod__c = GuidUtil.NewGuid();
            }

            if((emAtt.Walk_In_Status_vod__c == 'Reconciled_To_Existing_Account_vod' || emAtt.Walk_In_Status_vod__c == 'Reconciled_To_New_Account_vod' ||
                emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_Existing_Account_vod' || emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_New_Account_vod')
                && emAtt.Walk_In_Reference_ID_vod__c != null) {
                if (existingWalkInAccounts.get(emAtt.Walk_In_Reference_ID_vod__c) != null) {
                    //populate account lookup using walk in ref id, the account must be valid hence checking existingWalkInAccounts
                    emAtt.Account_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
                }
            } else if((emAtt.Walk_In_Status_vod__c == 'Reconciled_To_Existing_User_vod' || emAtt.Online_Registration_Status_vod__c == 'Reconciled_To_Existing_User_vod')  && emAtt.Walk_In_Reference_Id_vod__c != null) {
                emAtt.User_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
            } else if (emAtt.Walk_In_Status_vod__c == 'Needs_Reconciliation_vod' && (emAtt.Walk_In_Reference_Id_vod__c == null || emAtt.Walk_In_Reference_Id_vod__c == '')) {
                emAtt.User_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
                emAtt.Account_vod__c = emAtt.Walk_In_Reference_ID_vod__c;
            }

            if (String.isNotEmpty(emAtt.Walk_In_Reference_ID_vod__c)) { //always clear this field
                emAtt.Walk_In_Reference_ID_vod__c = null;
            }

            String name = lastName + ', ' + firstName;
            if(emAtt.Child_Account_vod__c != null) {
                Child_Account_vod__c childAccount = childAccounts.get(emAtt.Child_Account_vod__c);
                if(childAccount != null) {
                    Account child = accounts.get(childAccount.Child_Account_vod__c);
                    if (child != null) {
                        if (emAtt.Account_vod__c == null) {
                            emAtt.Account_vod__c = child.Id;
                        }
                        name = childAccount.Parent_Child_Name_vod__c;
                        emAtt.First_Name_vod__c = child.FirstName;
                        emAtt.Last_Name_vod__c = child.LastName;
                    }
                }
            }

            if(emAtt.Account_vod__c != null && emAtt.Child_Account_vod__c == null) { //Child Account field must be null
                Account account = accounts.get(emAtt.Account_vod__c);
                if(account != null) {
                    if(account.Formatted_Name_vod__c != null) {
                    name = account.Formatted_Name_vod__c;
                    } else if(account.FirstName != null && account.LastName != null) {
                        name = account.LastName + ', ' + account.FirstName;
                    } else {
                        name = account.Name;
                    }
                    if (Trigger.isInsert) {
                        emAtt.Title_vod__c = account.PersonTitle;
                        emAtt.Credentials_vod__c = account.Credentials_vod__c;
                    }
                    
                    if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                        if(account.Furigana_vod__c != null) {
                            emAtt.Furigana_vod__c = account.Furigana_vod__c;
                        }
                        emAtt.First_Name_vod__c = account.FirstName;
                        emAtt.Last_Name_vod__c = account.LastName;
                    }
                }
            }
            
            if(emAtt.Contact_vod__c != null) {
                Contact contact = contacts.get(emAtt.Contact_vod__c);
                if(contact != null) {
                    if(contact.FirstName != null && contact.LastName != null) {
                    name = contact.LastName + ', ' + contact.FirstName;
                    } else {
                        name = contact.Name;
                    }
                    if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                        emAtt.First_Name_vod__c = contact.FirstName;
                        emAtt.Last_Name_vod__c = contact.LastName;
                    }
                }        
            }            
            
            if(emAtt.User_vod__c != null) {
                User user = users.get(emAtt.User_vod__c);
                if(user != null) {
                    if(user.FirstName != null && user.LastName != null) {
                    name = user.LastName + ', ' + user.FirstName;
                    } else {
                        name = user.Name;
                    }
                    if (emAtt.Walk_In_Status_vod__c == null && emAtt.Online_Registration_Status_vod__c == null) {
                        emAtt.First_Name_vod__c = user.FirstName;
                        emAtt.Last_Name_vod__c = user.LastName;
                    }
                }
            }

            Integer lastNameMaxLen = SObjectType.EM_Attendee_vod__c.Fields.Last_Name_vod__c.Length;
            if (emAtt.Last_Name_vod__c != null && emAtt.Last_Name_vod__c.length() > lastNameMaxLen) {
                emAtt.Last_Name_vod__c = emAtt.Last_Name_vod__c.substring(0, lastNameMaxLen);
            }

            if(name != null) {
                Integer nameMaxLen = SObjectType.EM_Attendee_vod__c.Fields.Attendee_Name_vod__c.Length;
                if (name.length() > nameMaxLen) {
                    name = name.substring(0, nameMaxLen);
                }
                emAtt.Attendee_Name_vod__c = name;
            }
        }
    }

    private void vodEmAttendeeAfterInsertUpdate() {
        if (VOD_Utils.hasObject('EM_Attendee_vod__Share')) {
            SObjectType attendeeShareType = Schema.getGlobalDescribe().get('EM_Attendee_vod__Share');
            List<SObject> newShares = new List<SObject>();
            Set<Id> eventIds = new Set<Id>();
            for (EM_Attendee_vod__c attendee : newAttendees) {
                if(attendee.Event_vod__c != null) {
                    eventIds.add(attendee.Event_vod__c);
                }
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
                Map<Id, EM_Attendee_vod__c> attendeeMap = new Map<Id, EM_Attendee_vod__c>();
                for (EM_Attendee_vod__c attendee : newAttendees) {
                    if (attendee.Event_vod__c != oldAttendeesMap.get(attendee.Id).Event_vod__c) {
                        attendeeMap.put(attendee.Id, attendee);
                    }
                }
                if (!attendeeMap.isEmpty()) {
                    Set<Id> attendeeSet = attendeeMap.keySet();
                    List<SObject> attendeeShares = Database.query('SELECT Id FROM EM_Attendee_vod__Share WHERE ParentId IN : attendeeSet');
                    List<Database.DeleteResult> results = Database.delete(attendeeShares, false);
                    for (Database.DeleteResult result: results) {
                        if (!result.isSuccess()) {
                        system.debug('Insert error: ' + result.getErrors()[0]);
                    }
                    }
                }

                for (Id attendeeId : attendeeMap.keySet()) {
                    EM_Attendee_vod__c attendee = attendeeMap.get(attendeeId);
                    if (eventToMembers.get(attendee.Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(attendee.Event_vod__c)) {
                            SObject attendeeShare = attendeeShareType.newSObject();
                            attendeeShare.put('ParentId', attendeeId);
                            attendeeShare.put('UserOrGroupId', memberId);
                            attendeeShare.put('AccessLevel', 'edit');
                            attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(attendeeShare);
                        }
                    }
                }
            } else {
                for (EM_Attendee_vod__c attendee : newAttendees) {
                    if (eventToMembers.get(attendee.Event_vod__c) != null) {
                        for (Id memberId : eventToMembers.get(attendee.Event_vod__c)) {
                            SObject attendeeShare = attendeeShareType.newSObject();
                            attendeeShare.put('ParentId', attendee.Id);
                            attendeeShare.put('UserOrGroupId', memberId);
                            attendeeShare.put('AccessLevel', 'edit');
                            attendeeShare.put('RowCause', 'Event_Team_Member_vod__c');
                            newShares.add(attendeeShare);
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

    private void vodEmAttendeeAfterInsUpd() {
        if (!VOD_Utils.isTriggerEventAttendee()) {
            Map<String, String> statusMap = new Map<String, String>();
            statusMap.put('Invited_vod', 'Invited');
            statusMap.put('Accepted_vod', 'Accepted');
            statusMap.put('Rejected_vod', 'Rejected');
            statusMap.put('Attended_vod', 'Attended');

            Set<DescribeFieldResult> emFields = new Set<DescribeFieldResult>();
            Set<DescribeFieldResult> meFields = new Set<DescribeFieldResult>();
            String[] types = new String[]{'Event_Attendee_vod__c','EM_Attendee_vod__c'};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);

            for(Schema.DescribeSobjectResult res : results) {
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

            VOD_Utils.setTriggerEmAttendee(true);
            List<String> emEventIds = new List<String>();
            Map<String, EM_Attendee_vod__c> emAttMap = new Map<String, EM_Attendee_vod__c>();
            for (EM_Attendee_vod__c emAtt : newAttendees) {
                            if(emAtt.Event_vod__c != null) {
                        emEventIds.add(emAtt.Event_vod__c);
                            }
                emAttMap.put(emAtt.Id, emAtt);
            }


            Map<String,String> emEventsToMedEvents = new Map<String,String>();
            for (Medical_Event_vod__c eventStub : [SELECT Id, EM_Event_vod__c
                                                FROM Medical_Event_vod__c
                                                WHERE EM_Event_vod__c in :emEventIds]) {
                emEventsToMedEvents.put(eventStub.EM_Event_vod__c, eventStub.Id);
            }

            Map<String,Schema.RecordTypeInfo> eaRTMap = Event_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

            List<Event_Attendee_vod__c> attStubs = new List<Event_Attendee_vod__c>();
            if (Trigger.isInsert) {
                Map<ID,Schema.RecordTypeInfo> emRTMap = EM_Attendee_vod__c.sObjectType.getDescribe().getRecordTypeInfosById();
                for (EM_Attendee_vod__c emAtt : newAttendees) {
                    Event_Attendee_vod__c newStub = new Event_Attendee_vod__c(
                        Entity_Reference_Id_vod__c = emAtt.Entity_Reference_Id_vod__c,
                        Account_vod__c = emAtt.Account_vod__c,
                        Contact_vod__c = emAtt.Contact_vod__c,
                        User_vod__c = emAtt.User_vod__c,
                        Child_Account_vod__c = emAtt.Child_Account_vod__c,
                        Attendee_vod__c = emAtt.Attendee_Name_vod__c,
                        EM_Attendee_vod__c = emAtt.Id,
                        Meal_Opt_In_vod__c = emAtt.Meal_Opt_In_vod__c,
                        Mobile_Id_vod__c = emAtt.Stub_Mobile_Id_vod__c,
                        Medical_Event_vod__c = emEventsToMedEvents.get(emAtt.Event_vod__c),
                        Signature_vod__c = emAtt.Signature_vod__c,
                        Signature_Datetime_vod__c = emAtt.Signature_Datetime_vod__c,
                        Walk_In_Status_vod__c = emAtt.Walk_In_Status_vod__c,
                        Address_Line_1_vod__c = emAtt.Address_Line_1_vod__c,
                        Address_Line_2_vod__c = emAtt.Address_Line_2_vod__c,
                        City_vod__c = emAtt.City_vod__c,
                        Zip_vod__c = emAtt.Zip_vod__c,
                        Phone_vod__c = emAtt.Phone_vod__c,
                        Email_vod__c = emAtt.Email_vod__c,
                        Prescriber_vod__c = emAtt.Prescriber_vod__c,
                        First_Name_vod__c = emAtt.First_Name_vod__c,
                        Last_Name_vod__c = emAtt.Last_Name_vod__c,
                        Organization_vod__c = emAtt.Organization_vod__c,
                        Override_Lock_vod__c = true,
                        Walk_In_Type_vod__c = emAtt.Walk_In_Type_vod__c
                    );
                    RecordTypeInfo eaInfo;
                    if (emAtt.RecordTypeId != null && emRTMap.get(emAtt.RecordTypeId) != null) {
                        eaInfo = eaRTMap.get(emRTMap.get(emAtt.RecordTypeId).getDeveloperName());
                    }
                    
                    if(eaInfo != null && eaInfo.isAvailable()) {
                        newStub.RecordTypeId = eaInfo.getRecordTypeId();
                    }

                    if (statusMap.get(emAtt.Status_vod__c) != null) {
                        newStub.Status_vod__c = statusMap.get(emAtt.Status_vod__c);
                    } else {
                        newStub.Status_vod__c = emAtt.Status_vod__c;
                    }
                    for(String mfield: mappedFields) {
                        newStub.put(mfield, emAtt.get(mfield));
                    }
                    
                    attStubs.add(newStub);
                }
                if(attStubs.size() > 0) {
                    Database.Saveresult[] eventAttendeeResults = Database.insert(attStubs, false);
                    for (Integer i = 0; i < eventAttendeeResults.size(); i++) {
                    	Database.Saveresult saveResult = eventAttendeeResults[i];
                    	if(!saveResult.isSuccess()){
                            newAttendees.get(i).addError(saveResult.getErrors()[0].getMessage());
            			}
                    }
                }

                Map<String, String> idToStubMap = new Map<String,String>();

                for(Event_Attendee_vod__c stub: attStubs) {
                    for (EM_Attendee_vod__c emAtt : newAttendees) {
                        if(stub.EM_Attendee_vod__c == emAtt.Id) {
                            idtoStubMap.put(emAtt.Id, stub.Id);
                        }
                    }
                }

                VOD_EVENT_UTILS.updateAttendeeStub(idToStubMap);

            } else if (Trigger.isUpdate) {
                Set<Id> changedAttendeeIds = new Set<Id>();

                Set<String> changeFields = new Set<String>();
                changeFields.addAll(mappedFields);
                changeFields.add('Entity_Reference_Id_vod__c');
                changeFields.add('Account_vod__c');
                changeFields.add('Child_Account_vod__c');
                changeFields.add('Contact_vod__c');
                changeFields.add('Attendee_Name_vod__c');
                changeFields.add('Meal_Opt_In_vod__c');
                changeFields.add('Signature_vod__c');
                changeFields.add('Signature_Datetime_vod__c');
                changeFields.add('Walk_In_Status_vod__c');
                changeFields.add('Address_Line_1_vod__c');
                changeFields.add('Address_Line_2_vod__c');
                changeFields.add('City_vod__c');
                changeFields.add('Phone_vod__c');
                changeFields.add('Zip_vod__c');
                changeFields.add('Email_vod__c');
                changeFields.add('Prescriber_vod__c');
                changeFields.add('First_Name_vod__c');
                changeFields.add('Last_Name_vod__c');
                changeFields.add('Organization_vod__c');
                changeFields.add('RecordTypeId');
                changeFields.add('Status_vod__c');
                changeFields.add('Walk_In_Type_vod__c');

                for(EM_Attendee_vod__c oldAtt: oldAttendees) {
                    EM_Attendee_vod__c newAtt = newAttendeesMap.get(oldAtt.Id);
                    for(String field: changeFields){
                        if(newAtt.get(field) != oldAtt.get(field)) {
                            changedAttendeeIds.add(newAtt.Id);
                            break;
                        }
                    }
                }

                if(changedAttendeeIds.size() > 0) {
                    for (Event_Attendee_vod__c attStub : [SELECT Account_vod__c, Contact_vod__c, User_vod__c, Child_Account_vod__c, Attendee_vod__c,
                                                    Status_vod__c, EM_Attendee_vod__c, Meal_Opt_In_vod__c, Signature_vod__c,
                                                    Signature_Datetime_vod__c, Walk_In_Status_vod__c, Address_Line_1_vod__c,
                                                    Address_Line_2_vod__c, City_vod__c, Zip_vod__c, Phone_vod__c, Email_vod__c,
                                                    Prescriber_vod__c, First_Name_vod__c, Last_Name_vod__c, Entity_Reference_Id_vod__c,
                                                    Walk_In_Type_vod__c
                                                    FROM Event_Attendee_vod__c
                                                    WHERE EM_Attendee_vod__c IN :changedAttendeeIds]) {
                        EM_Attendee_vod__c emAtt = emAttMap.get(attStub.EM_Attendee_vod__c);
                        attStub.Entity_Reference_Id_vod__c = emAtt.Entity_Reference_Id_vod__c;
                        attStub.Account_vod__c = emAtt.Account_vod__c;
                        attStub.Contact_vod__c = emAtt.Contact_vod__c;
                        attStub.User_vod__c = emAtt.User_vod__c;
                        attStub.Child_Account_vod__c = emAtt.Child_Account_vod__c;
                        attStub.Attendee_vod__c = emAtt.Attendee_Name_vod__c;
                        attStub.EM_Attendee_vod__c = emAtt.Id;
                        attStub.Meal_Opt_In_vod__c = emAtt.Meal_Opt_In_vod__c;
                        attStub.Signature_vod__c = emAtt.Signature_vod__c;
                        attStub.Signature_Datetime_vod__c = emAtt.Signature_Datetime_vod__c;
                        attStub.Walk_In_Status_vod__c = emAtt.Walk_In_status_vod__c;
                        attStub.Address_Line_1_vod__c = emAtt.Address_Line_1_vod__c;
                        attStub.Address_Line_2_vod__c = emAtt.Address_Line_2_vod__c;
                        attStub.City_vod__c = emAtt.City_vod__c;
                        attStub.Phone_vod__c = emAtt.Phone_vod__c;
                        attStub.Zip_vod__c = emAtt.Zip_vod__c;
                        attStub.Email_vod__c = emAtt.Email_vod__c;
                        attStub.Prescriber_vod__c = emAtt.Prescriber_vod__c;
                        attStub.First_Name_vod__c = emAtt.First_Name_vod__c;
                        attStub.Last_Name_vod__c = emAtt.Last_Name_vod__c;
                        attStub.Organization_vod__c = emAtt.Organization_vod__c;
                        attStub.Override_Lock_vod__c = true;
                        attStub.Walk_In_Type_vod__c = emAtt.Walk_In_Type_vod__c;
                        if (emAtt.RecordType != null && eaRTMap.get(emAtt.RecordType.DeveloperName) != null) {
                            attStub.RecordTypeId = eaRTMap.get(emAtt.RecordType.DeveloperName).getRecordTypeId();
                        }
                        if (statusMap.get(emAtt.Status_vod__c) != null) {
                            attStub.Status_vod__c = statusMap.get(emAtt.Status_vod__c);
                        } else {
                            attStub.Status_vod__c = emAtt.Status_vod__c;
                        }
                        for(String mfield: mappedFields) {
                            attStub.put(mfield, emAtt.get(mfield));
                        }
                        attStubs.add(attStub);
                    }
                }

                if(attStubs.size() > 0) {
                    update attStubs;
                }
            }
        }
    }

    private void vodEmAttendeeCountRollupInsert() {
        Set<ID> eventIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: newAttendees) {
            if(attendee.Event_vod__c != null) {
                eventIds.add(attendee.Event_vod__c);
            }
        }

        List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);

        if(eventsToUpdate.size() > 0) {
            update eventsToUpdate;
        }
    }

    private void vodEmAttendeeCountRollupUpdate() {
        Set<ID> eventIds = new Set<ID>();
        for(EM_Attendee_vod__c attendee: newAttendees) {
            EM_Attendee_vod__C oldAttendee = oldAttendeesMap.get(attendee.Id);
            if(attendee.Meal_Opt_In_vod__c != oldAttendee.Meal_Opt_In_vod__c || attendee.Status_vod__c != oldAttendee.Status_vod__c) {
                            if(attendee.Event_vod__c != null) {
                                    eventIds.add(attendee.Event_vod__c);
                            }
            }
        }

        if(eventIds.size() > 0) {
            List<EM_Event_vod__c> eventsToUpdate = VOD_EVENT_UTILS.rollupCountsToEvent(eventIds);
            for(EM_Event_vod__c event: eventsToUpdate){
                if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue != null && VOD_EVENT_UTILS.eventsWithOverrideLockTrue.size() > 0 && VOD_EVENT_UTILS.eventsWithOverrideLockTrue.contains(event.Id)){
                    event.Override_Lock_vod__c = true;
                }
            }
            if(VOD_EVENT_UTILS.eventsWithOverrideLockTrue != null){
            VOD_EVENT_UTILS.eventsWithOverrideLockTrue.clear(); 
            }
            update eventsToUpdate;
        }
    }
}