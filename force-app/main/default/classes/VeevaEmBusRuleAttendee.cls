/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2021 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * VeevaEmBusRuleAttendee checks attendee rule violation by event attendee(or attendee to be added) and business rules.
 *
 * Per Event rule will verify current event attendee count by rule definition. 
 * Per Attendee rule will verify event attendance by a summarized query from the rule definition.
 */
@RestResource(urlMapping='/veeva/business-rule-attendees')
global without sharing class VeevaEmBusRuleAttendee {
    private static Map<Id, Schema.RecordTypeInfo> EVENT_RECORD_TYPE_MAP = Schema.SObjectType.EM_Event_vod__c.getRecordTypeInfosById();

    private static final String EVENT_RELATIONSHIP = 'Event_vod__r';

    @HttpPost
    global static AttendeeResult processAttendeeRules() {
        AttendeeResult attendeeResult = new AttendeeResult();
        RestResponse res = RestContext.response;
        if (RestContext.request.requestBody != null) {
            try{
                String requestBodyStr = RestContext.request.requestBody.toString();
                AttendeeRequest attendeeRequest = (AttendeeRequest) JSON.deserialize(requestBodyStr, AttendeeRequest.class);
                validateRequest(attendeeRequest);
                getEventAttendee(attendeeRequest);
                List<VeevaEmBusRuleModel.BusinessRule> businessRules = VeevaEmBusRuleModel.getBusinessRules(attendeeRequest.ruleIds, attendeeRequest.eventType, 
                    attendeeRequest.country, attendeeRequest.startTime);
                if (businessRules.isEmpty()) {
                    throw new VeevaEmBusRuleModel.BadDataException('Rule Id in request is not valid');
                }
                findRuleViolations(businessRules, attendeeRequest, attendeeResult);
                setResponse(attendeeResult, res, true, '', 200);
            } catch (VeevaEmBusRuleModel.BadDataException be) {
                setResponse(attendeeResult, res, false, be.getMessage(), 400);
            } catch (Exception e) {
                setResponse(attendeeResult, res, false, e.getMessage(), 500);
            }
        } else {
            setResponse(attendeeResult, res, false, 'Request body is null', 400);
        }
        return attendeeResult;
    }

    private class AttendeeRequest {
        private String eventId;
        private Set<String> ruleIds;
        private Set<String> accountIds;
        private Set<String> userIds;
        private Set<String> contactIds;
        private String eventAction;
        private String platform;
        private String eventType;
        private String country;
        private String topic;
        private String eventTopicName;
        private Datetime startTime;
        // Key by attendee Id derived from account/user/contact Id
        private Map<String, AttendeeField> attendeeFields;
        // Key by attendee Id derived from account/user/contact Id
        private Map<String, AttendeeAccountType> eventAttendeeKeys;
        private Set<String> speakerAccountIds;

        private boolean hasAttendee() {
            return (accountIds != null && !accountIds.isEmpty() || userIds != null && !userIds.isEmpty() || contactIds != null && !contactIds.isEmpty());
        }

        private Integer getAttendeeCount(Set<String> statusList, Set<String> accountTypeList) {
            Integer count = 0;
            if (attendeeFields != null) {
                for (AttendeeField attendeeField : attendeeFields.values()) {
                    String accountType = attendeeField.accountType;
                    String status = attendeeField.status;
                    boolean valid = ((statusList.isEmpty() || statusList.contains(status)) && (accountTypeList.isEmpty() || accountTypeList.contains(accountType)));
                    if (valid) {
                        count ++;
                    }
                }
            }
            return count;
        }
    }

    private class AttendeeField {
        private String attendeeId;
        private String status;
        private String accountType;
        private String name;
        private String firstName;
        private String lastName;

        private AttendeeField(String attendeeId) {
            this.attendeeId = attendeeId;
        }
    }

    private class AttendeeViolation {
        private String attendeeId;
        private Integer currentAttendance;
    }

    private class AttendeeAccountType {
        private String id;
        private String accountType;

        private AttendeeAccountType(String id, String accountType) {
            this.id = id;
            this.accountType = accountType;
        }
    }

    global class AttendeeResult{
        public boolean success;
        public String errorMessage;
        public String eventHistoryBatchId;
        public String eventTopicName;
        public Map<String, List<AttendeeViolation>> ruleViolations;
        public Map<String, VeevaEmBusRuleModel.RuleAttendee> ruleAttendees;
        public Map<String, AttendeeAccountType> eventAttendeeKeys;
    }

    private static void validateRequest(AttendeeRequest attendeeRequest) {
        if (String.isEmpty(attendeeRequest.eventId)) {
            throw new VeevaEmBusRuleModel.BadDataException('Event Id in request is not valid');
        }

        Set<String> ruleIds = attendeeRequest.ruleIds;
        if (ruleIds.isEmpty()) {
            throw new VeevaEmBusRuleModel.BadDataException('Rule Id list is empty in request');
        }

        if (ruleIds.size() > VeevaEmBusRuleUtils.RULE_COUNT_LIMIT) {
            throw new VeevaEmBusRuleModel.BadDataException('Running more than ' + VeevaEmBusRuleUtils.RULE_COUNT_LIMIT + ' rules is not supported');
        }
    }

    private static void setEventDetailToRequest(AttendeeRequest attendeeRequest) {
        EM_Event_vod__c event = [SELECT RecordTypeId, Country_vod__c, Start_Time_vod__c, Topic_vod__c, Topic_vod__r.Name_vod__c FROM EM_Event_vod__c WHERE Id = :attendeeRequest.eventId];
        attendeeRequest.startTime = event.Start_Time_vod__c;
        attendeeRequest.eventType = VeevaEmBusRuleUtils.getDeveloperName(EVENT_RECORD_TYPE_MAP, event.RecordTypeId);
        attendeeRequest.country = event.Country_vod__c;
        attendeeRequest.topic = event.Topic_vod__c;
        attendeeRequest.eventTopicName = event.Topic_vod__r.Name_vod__c;
    }

    private static void getEventAttendee(AttendeeRequest attendeeRequest) {
        attendeeRequest.attendeeFields = new Map<String, AttendeeField>();
        attendeeRequest.eventAttendeeKeys = new Map<String, AttendeeAccountType>();
        if (attendeeRequest.hasAttendee()) {
            setEventDetailToRequest(attendeeRequest);
        } else {
            List<EM_Attendee_vod__c> eventAttendees = [SELECT Id, Account_vod__c, User_vod__c, Contact_vod__c, Attendee_Account_Type_vod__c, Status_vod__c, 
                                                        Event_vod__r.RecordTypeId, Event_vod__r.Country_vod__c, Event_vod__r.Start_Time_vod__c, Event_vod__r.Topic_vod__c,
                                                        First_Name_vod__c, Last_Name_vod__c, Attendee_Name_vod__c, Event_vod__r.Topic_vod__r.Name_vod__c
                                                        FROM EM_Attendee_vod__c WHERE Event_vod__c = :attendeeRequest.eventId];
            if (eventAttendees.isEmpty()) {
                setEventDetailToRequest(attendeeRequest);
                return;
            }  

            attendeeRequest.accountIds = new Set<String>();
            attendeeRequest.userIds = new Set<String>();
            attendeeRequest.contactIds = new Set<String>();
            for (EM_Attendee_vod__c attendee : eventAttendees) {
                String attendeeId;
                if (attendee.Account_vod__c != null) {
                    attendeeId = attendee.Account_vod__c;
                    attendeeRequest.accountIds.add(attendeeId);
                }
                if (attendee.User_vod__c != null) {
                    attendeeId = attendee.User_vod__c;
                    attendeeRequest.userIds.add(attendeeId);
                }
                if (attendee.Contact_vod__c != null) {
                    attendeeId = attendee.Contact_vod__c;
                    attendeeRequest.contactIds.add(attendeeId);
                }
                if (String.isNotBlank(attendeeId)) {
                    attendeeRequest.eventAttendeeKeys.put(attendeeId, new AttendeeAccountType(attendee.Id, attendee.Attendee_Account_Type_vod__c));
                    AttendeeField attendeeField = new AttendeeField(attendeeId);
                    attendeeField.accountType = attendee.Attendee_Account_Type_vod__c;
                    attendeeField.status = attendee.Status_vod__c;
                    attendeeField.firstName = attendee.First_Name_vod__c;
                    attendeeField.lastName = attendee.Last_Name_vod__c;
                    attendeeField.name = attendee.Attendee_Name_vod__c;
                    attendeeRequest.attendeeFields.put(attendeeId, attendeeField);
                }
            }
            EM_Attendee_vod__c attendee = eventAttendees.get(0);
            attendeeRequest.startTime = attendee.Event_vod__r.Start_Time_vod__c;
            attendeeRequest.eventType = VeevaEmBusRuleUtils.getDeveloperName(EVENT_RECORD_TYPE_MAP, attendee.Event_vod__r.RecordTypeId);
            attendeeRequest.country = attendee.Event_vod__r.Country_vod__c;
            attendeeRequest.topic = attendee.Event_vod__r.Topic_vod__c;
            attendeeRequest.eventTopicName = attendee.Event_vod__r.Topic_vod__r.Name_vod__c;
        }
    }

    private static Integer getPerAttendeeRulesCount(List<VeevaEmBusRuleModel.BusinessRule> businessRules) {
        Integer count = 0;
        for (VeevaEmBusRuleModel.BusinessRule businessRule : businessRules) {
            if (!businessRule.isPerEventRule()) {
                count ++;
            }
        }
        return count;
    }

    private static void findRuleViolations(List<VeevaEmBusRuleModel.BusinessRule> businessRules, AttendeeRequest attendeeRequest, AttendeeResult attendeeResult) {
        Map<String, List<AttendeeViolation>> ruleViolations = new Map<String, List<AttendeeViolation>>();
        Map<String, VeevaEmBusRuleModel.RuleAttendee> ruleAttendees = new Map<String, VeevaEmBusRuleModel.RuleAttendee>();
        Map<String, VeevaEmBusRuleModel.BusinessRule> violatedRuleMap = new Map<String, VeevaEmBusRuleModel.BusinessRule>();

        Set<String> accountNameIds = new Set<String>();
        Set<String> emptyAccountNameIds = new Set<String>();
        List<String> idClauseBatch = new List<String>();
        boolean hasAttendee = attendeeRequest.hasAttendee();
        if (hasAttendee) {
            idClauseBatch = VeevaEmBusRuleUtils.composeIdCriteria(new List<String>(attendeeRequest.accountIds), new List<String>(attendeeRequest.userIds), new List<String>(attendeeRequest.contactIds));
            if (idClauseBatch.size() * getPerAttendeeRulesCount(businessRules) > VeevaEmBusRuleUtils.RULE_QUERY_LIMIT) {
                throw new VeevaEmBusRuleModel.BadDataException('Running more than ' + VeevaEmBusRuleUtils.RULE_QUERY_LIMIT + ' queries is not supported');
            }
        }
        for (VeevaEmBusRuleModel.BusinessRule businessRule : businessRules) {
            if (businessRule.isPerEventRule()) {
                Integer attendeeCount = attendeeRequest.getAttendeeCount(businessRule.getPerEventAttendeeStatus(), businessRule.getAccountTypes());
                Integer minQuantity = businessRule.minimumQuantity;
                Integer maxQuantity = businessRule.maximumQuantity;
                if (minQuantity != null && attendeeCount < minQuantity || maxQuantity != null && attendeeCount > maxQuantity ) {
                    ruleViolations.put(businessRule.id, new List<AttendeeViolation>());
                    violatedRuleMap.put(businessRule.id, businessRule);
                }
            } else if (hasAttendee) {
                List<AttendeeViolation> violations = new List<AttendeeViolation>();
                if (businessRule.isSpeakerAttendanceQualificationRule()) {
                    violations = getSpeakerAttendanceViolation(businessRule, attendeeRequest, ruleAttendees, accountNameIds, emptyAccountNameIds);
                } else { 
                    violations = getPerAttendeeRuleViolation(idClauseBatch, businessRule, attendeeRequest, ruleAttendees, accountNameIds);
                }
                if (!violations.isEmpty()) {
                    ruleViolations.put(businessRule.id, violations);
                    violatedRuleMap.put(businessRule.id, businessRule);
                }
            }
        }
        if (!emptyAccountNameIds.isEmpty() && !ruleAttendees.isEmpty()) {
            setDefaultAttendeeName(emptyAccountNameIds, ruleAttendees);
        }
        VeevaEmBusRuleModel.convertAttendeeName(accountNameIds, ruleAttendees);
        attendeeResult.ruleViolations = ruleViolations;
        attendeeResult.ruleAttendees = ruleAttendees;
        attendeeResult.eventAttendeeKeys = attendeeRequest.eventAttendeeKeys;
        attendeeResult.eventTopicName = attendeeRequest.eventTopicName;
        if (String.isNotBlank(attendeeRequest.eventAction) && !ruleViolations.isEmpty()) {
            filterOverrideRule(attendeeResult, businessRules);
            createEventHistory(attendeeRequest, attendeeResult, violatedRuleMap);
        }
    }

    private static List<AttendeeViolation> getSpeakerAttendanceViolation(VeevaEmBusRuleModel.BusinessRule businessRule, AttendeeRequest attendeeRequest, Map<String, VeevaEmBusRuleModel.RuleAttendee> ruleAttendees, Set<String> accountNameIds, Set<String> emptyAccountNameIds) {
        List<AttendeeViolation> violations = new List<AttendeeViolation>();
        if (attendeeRequest.accountIds == null || attendeeRequest.accountIds.isEmpty() || String.isEmpty(attendeeRequest.topic)) {
            return violations;
        }
        getSpeakerQualification(attendeeRequest);
        for (String accountId : attendeeRequest.speakerAccountIds) {
            AttendeeViolation violation = new AttendeeViolation();
            violation.attendeeId = accountId;
            accountNameIds.add(accountId);
            if (!ruleAttendees.containsKey(violation.attendeeId)) {
                VeevaEmBusRuleModel.RuleAttendee attendee = new VeevaEmBusRuleModel.RuleAttendee(accountId, null, null);
                AttendeeField attendeeField = attendeeRequest.attendeeFields.get(accountId);
                if (attendeeField != null) {
                    attendee.attendeeName = attendeeField.name;
                    attendee.attendeeFirstName = attendeeField.firstName;
                    attendee.attendeeLastName = attendeeField.lastName;
                } else {
                    emptyAccountNameIds.add(accountId);
                }
                ruleAttendees.put(violation.attendeeId, attendee);
            }
            violations.add(violation);
        }
        return violations;
    }

    private static void getSpeakerQualification(AttendeeRequest attendeeRequest) {
        if (attendeeRequest.speakerAccountIds == null) {
            Date dt = attendeeRequest.startTime.date();
            attendeeRequest.speakerAccountIds = new Set<String>();
            for (EM_Speaker_Qualification_vod__c qualification : [SELECT Id, Speaker_vod__r.Account_vod__c FROM EM_Speaker_Qualification_vod__c 
                WHERE Qualification_vod__c = :attendeeRequest.topic
                AND (Start_Date_vod__c = null OR Start_Date_vod__c <= :dt) AND (End_Date_vod__c = null Or End_Date_vod__c >= :dt) 
                AND Speaker_vod__r.Status_vod__c != 'Expired_vod' AND Speaker_vod__r.Account_vod__c IN : new List<String>(attendeeRequest.accountIds)]) {
                attendeeRequest.speakerAccountIds.add(qualification.Speaker_vod__r.Account_vod__c);
            }
        }
    }

    private static List<AttendeeViolation> getPerAttendeeRuleViolation(List<String> idClauseBatch, VeevaEmBusRuleModel.BusinessRule businessRule, AttendeeRequest attendeeRequest, Map<String, VeevaEmBusRuleModel.RuleAttendee> ruleAttendees, Set<String> accountNameIds) {
        List<AttendeeViolation> violations = new List<AttendeeViolation>();
        if (businessRule.perEventTopic && String.isEmpty(attendeeRequest.topic)) {
            return violations;
        }
        String ruleQuery = composeQuery(businessRule, attendeeRequest.startTime, attendeeRequest.eventId);
        for (String batch : idClauseBatch) {
            String query = composeBatchQuery(businessRule, ruleQuery, batch, attendeeRequest.topic);
            for (sObject queryRow : Database.query(query)) {
                AttendeeViolation violation = new AttendeeViolation();
                String accountId = (String)queryRow.get('Account_vod__c');
                String userId = (String)queryRow.get('User_vod__c');
                String contactId = (String)queryRow.get('Contact_vod__c');
                if (String.isNotBlank(accountId)) {
                    accountNameIds.add(accountId);
                }
                violation.attendeeId = VeevaEmBusRuleUtils.getAttendeeId(accountId, userId, contactId);
                violation.currentAttendance = (Integer)queryRow.get('Total');
                if (!ruleAttendees.containsKey(violation.attendeeId)) {
                    VeevaEmBusRuleModel.RuleAttendee attendee = new VeevaEmBusRuleModel.RuleAttendee(accountId, userId, contactId);
                    attendee.attendeeName = (String)queryRow.get('Attendee_Name_vod__c');
                    attendee.attendeeFirstName = (String)queryRow.get('First_Name_vod__c');
                    attendee.attendeeLastName = (String)queryRow.get('Last_Name_vod__c');
                    ruleAttendees.put(violation.attendeeId, attendee);
                }
                violations.add(violation);
            }
        }
        return violations;
    }

    private static String composeQuery(VeevaEmBusRuleModel.BusinessRule rule, Datetime startTime, String eventId) {
        String query = 'SELECT COUNT(' + EVENT_RELATIONSHIP + '.Id) Total, Account_vod__c, User_vod__c, Contact_vod__c, First_Name_vod__c, Last_Name_vod__c, Attendee_Name_vod__c';
        Datetime minDatetime; 
        Datetime maxDatetime;
        switch on rule.dateThresholdType {
            when 'Rolling_vod' {
                Integer rollingPeriod = rule.rollingPeriod;
                minDatetime = startTime.addDays(rollingPeriod * (-1));
                maxDatetime = startTime.addDays(rollingPeriod);
            } 
            when 'Calendar_Month_vod' {
                minDatetime = datetime.newInstance(startTime.year(), startTime.month(), 1, 0, 0, 0);
                maxDatetime = datetime.newInstance(startTime.year(), startTime.month(), 1, 0, 0, 0);
                maxDatetime = maxDatetime.addMonths(1);
            }
            when 'Calendar_Year_vod' {
                minDatetime = datetime.newInstance(startTime.year(), 1, 1, 0, 0, 0);
                maxDatetime = datetime.newInstance(startTime.year() + 1, 1, 1, 0, 0, 0);
            }
        }
        String datetimeFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
        String formattedMin = minDateTime.formatGmt(datetimeFormat);
        String formattedMax = maxDatetime.formatGmt(datetimeFormat);
        query += ' FROM EM_Attendee_vod__c WHERE ' + EVENT_RELATIONSHIP + '.Start_Time_vod__c >= ' + formattedMin + ' AND ' + EVENT_RELATIONSHIP + '.Start_Time_vod__c < ' + formattedMax;
        String status = composeAttendeeStatusCriteria(rule.getEventAttendeeStatus());
        if (String.isNotBlank(status)) {
            query += ' AND (' + status + ')';
        }
        String config = composeEventTypeCountryCriteria(rule.configs);
        if (String.isNotBlank(config)) {
            query += ' AND (' + config + ')';
        }
        Set<String> accountTypes = rule.getAccountTypes();
        if (!accountTypes.isEmpty()) {
            query += ' AND Attendee_Account_Type_vod__c IN ' + VeevaEmBusRuleUtils.toCommaSeparated(new List<String>(accountTypes));
        }
        if (rule.isMealOptInRule()) {
            query += ' AND Meal_Opt_In_vod__c = true';
        }
        query += ' AND ' + EVENT_RELATIONSHIP + '.Id !=\''+ eventId + '\'';
        return query;
    }

    private static String composeBatchQuery(VeevaEmBusRuleModel.BusinessRule rule, String ruleQuery, String batch, String topic) {
        String query = ruleQuery;
        query += ' AND (' + batch + ')';
        if (rule.perEventTopic) {
            query += ' AND ' + EVENT_RELATIONSHIP + '.Topic_vod__c = \'' + topic + '\'';
        }
        query += ' GROUP BY Account_vod__c, User_vod__c, Contact_vod__c, First_Name_vod__c, Last_Name_vod__c, Attendee_Name_vod__c';
        query += ' HAVING COUNT(' + EVENT_RELATIONSHIP + '.Id) > = ' + rule.limitQuantity;
        return query;
    }

    private static String composeAttendeeStatusCriteria(Map<String, Set<String>> statusPairs) {
        String query = '';
        Integer i = 0;
        for (String key : statusPairs.keySet()) {
            Set<String> values = statusPairs.get(key);
            if (!values.isEmpty()) {
                if (i > 0) {
                    query += ' OR ';
                }
                query += '(' + EVENT_RELATIONSHIP + '.Status_vod__c = \'' + key + '\' AND Status_vod__c IN '
                    + VeevaEmBusRuleUtils.toCommaSeparated(new List<String>(values)) + ')';
                i++;
            }
        }
        return query;
    }
 
    private static String composeEventTypeCountryCriteria(List<VeevaEmBusRuleModel.BusinessRuleConfig> configs) {
        String query = '';
        Integer i = 0;
        for (VeevaEmBusRuleModel.BusinessRuleConfig config : configs) {
            if (i > 0) {
                query += ' OR ';
            }
            // global rule
            if (String.isBlank(config.country)) {
                query += '(' + EVENT_RELATIONSHIP + '.RecordType.DeveloperName = \'' + config.eventType + '\')';
            } else {
                query += '(' + EVENT_RELATIONSHIP + '.RecordType.DeveloperName = \'' + config.eventType
                    + '\' AND ' + EVENT_RELATIONSHIP + '.Country_vod__c = \'' + config.country + '\')';
            }
            i++;
        }
        return query;
    }

    private static void createEventHistory(AttendeeRequest attendeeRequest, AttendeeResult attendeeResult, Map<String, VeevaEmBusRuleModel.BusinessRule> ruleMap) {
        List<EM_Event_History_vod__c> sObjects = new List<EM_Event_History_vod__c>();

        RecordTypeInfo recordType = Schema.SObjectType.EM_Event_History_vod__c.getRecordTypeInfosByDeveloperName().get('EM_Business_Rule_History_vod');
        if (recordType == null) {
            return;
        }
        String recordTypeId = recordType.getRecordTypeId();
        String eventId = attendeeRequest.eventId;
        String eventAction = attendeeRequest.eventAction;
        String platform = attendeeRequest.platform;
        Map<String, List<AttendeeViolation>> ruleViolations = attendeeResult.ruleViolations;
        Map<String, VeevaEmBusRuleModel.RuleAttendee> ruleAttendees = attendeeResult.ruleAttendees;
        Map<String, AttendeeAccountType> eventAttendeeKeys = attendeeRequest.eventAttendeeKeys;

        for (String ruleId : ruleViolations.keySet()) {
            VeevaEmBusRuleModel.BusinessRule rule = ruleMap.get(ruleId);
            List<AttendeeViolation> attendeeViolations = ruleViolations.get(ruleId);
            EM_Event_History_vod__c history = null;
            String configId = rule.getConfigurationId(attendeeRequest.eventType, attendeeRequest.country);
            // per event rule
            if (attendeeViolations.isEmpty()) {
                history = createEventHistoryObject(recordTypeId, eventId, configId, eventAction, platform, rule);
                history.Record_Violated_ID_vod__c = eventId;
                sObjects.add(history);
            }
            for (AttendeeViolation violation : attendeeViolations) {
                history = createEventHistoryObject(recordTypeId, eventId, configId, eventAction, platform, rule);
                String attendeeId = violation.attendeeId;
                VeevaEmBusRuleModel.RuleAttendee attendee = ruleAttendees.get(attendeeId);
                history.EM_Attendee_Account_vod__c = attendee.accountId;
                history.EM_Attendee_User_vod__c = attendee.userId;
                history.EM_Attendee_Contact_vod__c = attendee.contactId;
                history.Record_Violated_Name_vod__c = attendee.attendeeName;
                history.Record_Violated_ID_vod__c = eventAttendeeKeys.get(attendeeId).id;
                sObjects.add(history);
            }
        }
        
        if (!sObjects.isEmpty()) {
            VeevaEmBusRuleBatch ruleBatch = new VeevaEmBusRuleBatch(sObjects);
            String batchId = Database.executeBatch(ruleBatch);
            attendeeResult.eventHistoryBatchId = batchId;
        }
    }

    private static EM_Event_History_vod__c createEventHistoryObject(String recordTypeId, String eventId, String configId, String eventAction, String platform, VeevaEmBusRuleModel.BusinessRule rule) {
        EM_Event_History_vod__c history = new EM_Event_History_vod__c();
        history.RecordTypeId = recordTypeId;
        history.Action_Type_vod__c = 'EM_Business_Rule_Execution_vod';
        history.Action_Datetime_vod__c = DateTime.now();
        history.Platform_vod__c = platform;
        history.User_vod__c = UserInfo.getUserId();
        history.Run_Rule_Type__c = 'Run_Rule_on_Event_Action_vod';
        history.Event_vod__c = eventId;
        history.Event_Action_vod__c = eventAction;
        history.EM_Business_Rule_Id_vod__c = rule.businessRuleId;
        history.EM_Business_Rule_Configuration_Id_vod__c = configId;
        history.Warning_Type_vod__c = rule.warningType;
        history.EM_Business_Rule_Type_vod__c = rule.developerName;
        return history;
    }

    private static Map<String, VeevaEmBusRuleModel.BusinessRule> convertRuleMap(List<VeevaEmBusRuleModel.BusinessRule> businessRules) {
        Map<String, VeevaEmBusRuleModel.BusinessRule> ruleMap = new Map<String, VeevaEmBusRuleModel.BusinessRule>();
        for (VeevaEmBusRuleModel.BusinessRule rule : businessRules) {
            ruleMap.put(rule.id, rule);
        }
        return ruleMap;
    }

    private static void filterOverrideRule(AttendeeResult attendeeResult, List<VeevaEmBusRuleModel.BusinessRule> businessRules) {
        Map<String, List<AttendeeViolation>> ruleViolations = attendeeResult.ruleViolations;
        Map<String, AttendeeAccountType> eventAttendeeKeys = attendeeResult.eventAttendeeKeys;
        Map<String, VeevaEmBusRuleModel.BusinessRule> ruleMap = convertRuleMap(businessRules);
        Map<String, Set<String>> ruleKeyAccountTypeMap = groupRules(businessRules);
        Set<String> overrideRules = new Set<String>();
        if (ruleKeyAccountTypeMap.isEmpty()) {
            return;
        }
        for (String ruleId : ruleViolations.keySet()) {
            VeevaEmBusRuleModel.BusinessRule rule = ruleMap.get(ruleId);
            List<AttendeeViolation> violations = ruleViolations.get(ruleId);
            Set<String> groupAccountTypes = ruleKeyAccountTypeMap.get(rule.getRuleKey());
            // skip for per event rule, or per attendee rule with same key but not define the account types
            if (violations.isEmpty() || groupAccountTypes == null || groupAccountTypes.isEmpty()) {
                continue;
            }
            for (Integer i=0; i<violations.size(); i++) {
                AttendeeViolation violation = violations.get(i);
                if (!isValidAccountType(eventAttendeeKeys.get(violation.attendeeId).accountType, rule, groupAccountTypes)) {
                    violations.remove(i);
                    i--;
                    overrideRules.add(ruleId);
                }
            }
        }
        for (String ruleId : overrideRules) {
            if (ruleViolations.get(ruleId).size() == 0) {
                ruleViolations.remove(ruleId);
            }
        }
    }

    private static Map<String, Set<String>> groupRules(List<VeevaEmBusRuleModel.BusinessRule> businessRules) {
        Map<String, Set<String>> ruleKeyAccountTypes = new Map<String, Set<String>>();
        for (VeevaEmBusRuleModel.BusinessRule rule : businessRules) {
            if (rule.isPerEventRule() || rule.getAccountTypes().isEmpty()) {
                continue;
            }
            String ruleKey = rule.getRuleKey();
            Set<String> accountTypes = rule.getAccountTypes();
            Set<String> groupAccountTypes = ruleKeyAccountTypes.get(ruleKey);
            if (groupAccountTypes == null) {
                groupAccountTypes = new Set<String>();
                ruleKeyAccountTypes.put(ruleKey, groupAccountTypes);
            }
            groupAccountTypes.addAll(accountTypes);
        }
        return ruleKeyAccountTypes;
    }

    private static boolean isValidAccountType(String accountType, VeevaEmBusRuleModel.BusinessRule rule, Set<String> groupAccountTypes) {
        boolean validAccountType = true;
        Set<String> ruleAccountTypes = rule.getAccountTypes();

        if (String.isBlank(accountType)) {
            return ruleAccountTypes.isEmpty();
        }
        if (ruleAccountTypes.isEmpty()) {
            // invalid if other rules with the same key and contains the attendee account type
            validAccountType = !groupAccountTypes.contains(accountType);
        } else {
            validAccountType = ruleAccountTypes.contains(accountType);
        }
        return validAccountType;
    }

    private static void setResponse(AttendeeResult attendeeResult, RestResponse res, boolean success, String errorMessage, Integer statusCode) {
        attendeeResult.success = success;
        attendeeResult.errorMessage = errorMessage;
        res.statusCode = statusCode;
    }

    private static void setDefaultAttendeeName(Set<String> emptyAccountNameIds, Map<String, VeevaEmBusRuleModel.RuleAttendee> ruleAttendees) {
        List<Account> accounts = [SELECT Id, Formatted_Name_vod__c, FirstName, LastName, Name FROM Account WHERE Id IN :emptyAccountNameIds];
        for (Account account : accounts) {
            String id = account.Id;
            if (ruleAttendees.containsKey(id)) {
                VeevaEmBusRuleModel.RuleAttendee ruleAttendee = ruleAttendees.get(id);
                String name = '';
                if (String.isNotBlank(account.Formatted_Name_vod__c)) {
                    name = account.Formatted_Name_vod__c;
                } else if (String.isNotBlank(account.FirstName) && String.isNotBlank(account.LastName)) {
                    name = account.LastName + ', ' + account.FirstName;
                } else {
                    name = account.Name;
                }
                ruleAttendee.attendeeName = name;
                ruleAttendee.attendeeFirstName = account.FirstName;
                ruleAttendee.attendeeLastName = account.LastName;
            }
        }
    }
}