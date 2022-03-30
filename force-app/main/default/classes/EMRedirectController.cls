public with sharing class EMRedirectController {
    boolean isStub = false;
    boolean isEMUser = false;
    ApexPages.StandardController controller;
    String attendeeStubId;
    String eventStubId;
    String startTime;
    String endTime;
    String timezoneValue;
    String country;
    String retURL;
    String parentId;
    String recordTypeId;
	String childEventRuleRecordTypeId;

    public EMRedirectController(ApexPages.StandardController controller) {
        this.controller = controller;
        isEmUser = Schema.SObjectType.Preferences_vod__c.fields.Event_Management_User_vod__c.isAccessible();
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        recordTypeId= ApexPages.currentPage().getParameters().get('RecordType');
        if(isEMUser) {
            sObject record = controller.getRecord();
        	if(isAttendee()) {
                if(record.get('EM_Attendee_vod__c') != null) {
                    isStub = true;
                    attendeeStubId = (String)record.get('EM_Attendee_vod__c');
                } else if (record.get('EM_Event_Speaker_vod__c') != null) {
                    isStub = true;
                    attendeeStubId = (String)record.get('EM_Event_Speaker_vod__c');
                }
            } else if (isMedicalEvent()) {
                if(record.get('EM_Event_vod__c') != null) {
                    isStub = true;
                    eventStubId = (String)record.get('EM_Event_vod__c');
                }
            } else if(isEMEvent()) {
                assignChildEventFields(record);
            }
        }
    }

    public String getStartTime() {
        return this.startTime;
    }

    public String getEndTime() {
        return this.endTime;
    }

    public String getTimezone() {
        return this.timezoneValue;
    }

    private boolean isAttendee() {
        return controller.getRecord().getSObjectType().getDescribe().getName() == 'Event_Attendee_vod__c';
    }

    private boolean isMedicalEvent() {
    	return controller.getRecord().getSObjectType().getDescribe().getName() == 'Medical_Event_vod__c';
    }

    private boolean isEMEvent() {
        return controller.getRecord().getSObjectType().getDescribe().getName() == 'EM_Event_vod__c';
    }

    public PageReference redirectEdit() {
        String objectId = controller.getId();
        retURL=EncodingUtil.urlEncode(retURL, 'UTF-8');

        if(objectId == null) {
            Schema.DescribeSObjectResult describe = controller.getRecord().getSObjectType().getDescribe();
            objectId = describe.getKeyPrefix();
        }

        if(!isEMUser) {
            if(recordTypeId != null) {
            	return new PageReference('/' + objectId + '/e?retURL=' + retURL +'&nooverride=1&RecordType=' + recordTypeId);
            } else {
                return new PageReference('/' + objectId + '/e?retURL=' + retURL +'&nooverride=1');
            }
        }

        if(isStub) {
            if(isAttendee()) {
                return new PageReference('/' + attendeeStubId + '/e?retURL=' + retURL);
            } else if (isMedicalEvent()) {
                return new PageReference('/' + eventStubId + '/e?retURL=' + retURL);
            }
        }

        if(recordTypeId != null) {
            return new PageReference('/' + objectId + '/e?retURL=' + retURL +'&nooverride=1&RecordType=' + recordTypeId);
        } else {
            return new PageReference('/' + objectId + '/e?retURL=' + retURL +'&nooverride=1');
        }
    }

    public PageReference redirectView() {
        if(!isEMUser) {
            new PageReference('/' + controller.getId() + '?retURL=' + retURL + '&nooverride=1');
        }
        if(isStub) {
            if(isAttendee()) {
                return new PageReference('/' + attendeeStubId);
            } else if (isMedicalEvent()) {
                return new PageReference('/' + eventStubId);
            }
        }
        return new PageReference('/' + controller.getId() + '?retURL=' + retURL + '&nooverride=1');
    }

    public void assignChildEventFields(sObject record) {
        DateTime recordStartDateTime;
        DateTime recordEndDateTime;
        Date recordStartDate;
        Time recordStartTimeLocal;
        Date recordEndDate;
        Time recordEndTimeLocal;
        String recordTimezone;
        String recordId;
        String recordCountry;
        
        Map<String, Schema.SObjectField> parentFields = record.getSobjectType().getDescribe().fields.getMap();
        List<String> localDateTimeFields = new List<String>{'start_date_vod__c', 'start_time_local_vod__c', 'end_date_vod__c', 'end_time_local_vod__c', 'time_zone_vod__c'};
        Boolean localDateTimeFLS = true;
        for(String field : localDateTimeFields) {
            localDateTimeFLS = localDateTimeFLS && parentFields.get(field).getDescribe().isAccessible();
        }
        recordStartDateTime = (DateTime)record.get('Start_Time_vod__c');
        recordEndDateTime = (DateTime)record.get('End_Time_vod__c');
        
        if(localDateTimeFLS) {
            recordStartDate = (Date)record.get('Start_Date_vod__c');
            recordStartTimeLocal = (Time)record.get('Start_Time_Local_vod__c');
            recordEndDate = (Date)record.get('End_Date_vod__c');
        	recordEndTimeLocal = (Time)record.get('End_Time_Local_vod__c');
            recordTimezone = (String)record.get('Time_Zone_vod__c');
        }
        
        recordId = (String)record.get('Id');
        recordCountry = (String)record.get('Country_vod__c');

        if( (recordStartTimeLocal != null) 
            && (recordStartDate != null)
            && (recordEndTimeLocal != null)
            && (recordEndDate != null)) {

            startTime = DateTime.newInstance(recordStartDate, recordStartTimeLocal).format();
            endTime = DateTime.newInstance(recordEndDate, recordEndTimeLocal).format();
        }
        else {
            if(recordStartDateTime != null) {
                startTime = recordStartDateTime.format();
            }
            if(recordEndDateTime != null) {
                endTime = recordEndDateTime.format();
            }   
        }
        if(recordId != null) {
            parentId = recordId;
        }
        timezoneValue = assignTimezone(recordTimezone);
        if(recordCountry != null) {
            country = recordCountry;
        }
    }

    public String assignTimezone(String recordTimezone) {
        String returnTimezone;
        if(recordTimezone != null) {
            returnTimezone = recordTimezone;
        }
        else {
            List<Preferences_vod__c> preferences = [Select Time_Zone_vod__c FROM Preferences_vod__c WHERE User_vod__c =: UserInfo.getUserId() LIMIT 1];
            if(preferences.size() == 1 && (preferences.get(0).get('Time_Zone_vod__c') != null)) {
                returnTimezone = (String)preferences.get(0).get('Time_Zone_vod__c');
            }
            else {
                returnTimezone = UserInfo.getTimeZone().getID();
            }
        }
        return returnTimezone;
    }

    public PageReference redirectNewEventChild() {
        String eventObjectId = VOD_RedirectUtil.getObjectDurableId('EM_Event_vod');
        String childPageUrl = '/setup/ui/recordtypeselect.jsp?ent=' + EncodingUtil.urlEncode(eventObjectId.substring(0,15), 'UTF-8');
        boolean skipRTSelector = false;

        //--EM Child Event Settings Rule--
        try {
            if (childEventRuleRecordTypeId == null) childEventRuleRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType ='EM_Event_Rule_vod__c' AND DeveloperName='Child_Event_Settings_vod'].Id;

            //find the event rule that is in the event configuration associated with the parent event,
            //is the child event rule record type, and the country_override.country is equal the to parent event's country
            EM_Event_vod__c parentEMConfig = [SELECT Event_Configuration_vod__c FROM EM_Event_vod__c WHERE Id = :parentId];
        	EM_Event_Configuration_Country_vod__c parentEventConfigCountry = [SELECT Country_vod__c FROM EM_Event_Configuration_Country_vod__c WHERE EM_Event_Configuration_Country_vod__c.Country_vod__c =: country AND EM_Event_Configuration_Country_vod__c.Event_Configuration_vod__c = :parentEMConfig.Event_Configuration_vod__c];

            List<EM_Event_Rule_vod__c> childEventRuleWithCOList = [SELECT Child_Event_Record_Type_vod__c
                                                        FROM EM_Event_Rule_vod__c
                                                        WHERE Event_Configuration_vod__c = :parentEMConfig.Event_Configuration_vod__c
                                                        	AND EM_Event_Rule_vod__c.RecordTypeId = :childEventRuleRecordTypeId
                                                         	AND EM_Event_Rule_vod__c.Country_Override_vod__c = :parentEventConfigCountry.Id];
            if (childEventRuleWithCOList.size() > 0) {
                //this should only ever have 1 record, since we use the unique key of event config and country override, unless the trigger is bugged and allows duplicate event rules
                EM_Event_Rule_vod__c childEventRuleWithCO = childEventRuleWithCOList.get(0);
                if (childEventRuleWithCO.Child_Event_Record_Type_vod__c != null) {
                    childPageUrl = '/apex/EM_Event_New_vod?RecordType='+ [SELECT Id FROM RecordType WHERE sObjectType = 'EM_Event_vod__c' and DeveloperName = :childEventRuleWithCO.Child_Event_Record_Type_vod__c].Id;
                    skipRTSelector = true;
                }
            } else {
                //finds the event rule that is in the event configuration associated with the parent event,
                //is the child event rule record type, and country_override field is blank
                //if the below query returns 0 results, thats fine, we catch the exception and carry on since no rule will be applied
                EM_Event_Rule_vod__c childEventRuleWithoutCO = [SELECT Child_Event_Record_Type_vod__c
                                                            FROM EM_Event_Rule_vod__c
                                                            WHERE Event_Configuration_vod__c = :parentEMConfig.Event_Configuration_vod__c
                                                                AND EM_Event_Rule_vod__c.RecordTypeId = :childEventRuleRecordTypeId
                                                                AND EM_Event_Rule_vod__c.Country_Override_vod__c = null ];

                if (childEventRuleWithoutCO.Child_Event_Record_Type_vod__c != null ) {
                    childPageUrl = '/apex/EM_Event_New_vod?RecordType='+ [SELECT Id FROM RecordType WHERE sObjectType = 'EM_Event_vod__c' and DeveloperName = :childEventRuleWithoutCO.Child_Event_Record_Type_vod__c].Id;
                	skipRTSelector = true;
                }
            }
        } catch (Exception e) {
            //catch the 0 records exception
        }

        String eventKeyPrefix = controller.getRecord().getSObjectType().getDescribe().getKeyPrefix();
        childPageUrl += '&retURL=' + EncodingUtil.urlEncode('/' + controller.getId(), 'UTF-8');
        childPageUrl += '&save_new_url=' + EncodingUtil.urlEncode('/apex/EM_Event_New_vod' + '?retURL=' + EncodingUtil.urlEncode('/' + controller.getId(), 'UTF-8'), 'UTF-8');

        if(startTime != null) {
            childPageUrl += '&Start_Time_vod__c=' + startTime;
        }
        if(parentId != null) {
            childPageUrl += '&Parent_Event_vod__c=' + parentId;
        }
        if(timezoneValue != null) {
            childPageUrl += '&Time_Zone_vod__c=' + timezoneValue;
        }
        if(country != null) {
            Country_vod__c countryObj = [SELECT Country_Name_vod__c FROM Country_vod__c WHERE Id =: country];

            childPageUrl += '&parentCountry=' + countryObj.Country_Name_vod__c;
        }
        if(endTime != null) {
            childPageUrl += '&End_Time_vod__c=' + endTime;
        }
        if (skipRTSelector) {
            childPageUrl += '#/event-wizard';
        }

        System.debug(childPageUrl);
        PageReference newChildPage = new PageReference(childPageUrl);
        newChildPage.setRedirect(true);
        return newChildPage;
    }

    public PageReference redirectNewEvent() {
        String eventObjectId = VOD_RedirectUtil.getObjectDurableId('EM_Event_vod');
        String newEventPageUrl = '/setup/ui/recordtypeselect.jsp?ent=' +
            EncodingUtil.urlEncode(eventObjectId.substring(0,15), 'UTF-8') +
            '&retURL=/' + retUrl +
            '&save_new_url=/apex/EM_Event_New_vod?retURL=/' +
            retUrl +
            '#/event-wizard';
        PageReference newEventPage = new PageReference(newEventPageUrl);
        newEventPage.setRedirect(true);
        return newEventPage;
    }
}