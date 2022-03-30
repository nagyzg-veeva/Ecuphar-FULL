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
 * VeevaEmBusRuleSpeakerService checks speaker rule violation by event speaker(or speaker to be added) and business rules.
 */
global without sharing class VeevaEmBusRuleSpeakerService extends VeevaEmBusRuleService {
    private static Map<Id, Schema.RecordTypeInfo> EVENT_RECORD_TYPE_MAP = Schema.SObjectType.EM_Event_vod__c.getRecordTypeInfosById();
    private static final String SPEAKER_FIELD = 'Speaker_vod__c';
    private static final String EVENT_RELATIONSHIP = 'Event_vod__r';

    private SpeakerRequest speakerRequest;
    private SpeakerResult speakerResult;
    private List<VeevaEmBusRuleModel.BusinessRule> businessRules;
    private List<SpeakerCap> speakerCaps;
    private Map<String, String> speakerNameMap;
    private Map<String, List<String>> perEventWarningTypeRules = new Map<String, List<String>>();

    public SpeakerResult processSpeakerRules(SpeakerRequest request) {
        speakerResult = new SpeakerResult();
        try {
            speakerRequest = request;
            validateRequest(speakerRequest.eventId, speakerRequest.ruleIds);
            initSpeakerRequest();
            businessRules = VeevaEmBusRuleModel.getBusinessRules(speakerRequest.ruleIds, speakerRequest.eventType, 
                speakerRequest.country, speakerRequest.startTime);
            if (businessRules.isEmpty()) {
                throw new VeevaEmBusRuleModel.BadDataException('Rule Id in request is not valid');
            }
            findRuleViolations();
            setResponse(speakerResult, res, true, '', 200);
        } catch (VeevaEmBusRuleModel.BadDataException be) {
            setResponse(speakerResult, res, false, be.getMessage(), 400);
        } catch (Exception e) {
            setResponse(speakerResult, res, false, e.getMessage(), 500);
        }
        return speakerResult;
    }

    public class SpeakerRequest {
        public String eventId;
        public Set<String> ruleIds;
        public Set<String> speakerIds;
        public String eventAction;
        private String platform;
        private String eventType;
        private String country;
        private String topic;
        private Datetime startTime;
        private List<AttendeeField> attendeeFields;
        private List<SpeakerField> speakerFields;

        // Key speaker Id, value event speaker Id
        public Map<String, String> eventSpeakerKeys;

        private boolean hasSpeakers() {
            return (speakerIds != null && !speakerIds.isEmpty());
        }
    }

    global class SpeakerResult{
        public boolean success;
        public String errorMessage;
        public String eventHistoryBatchId;
        // Key rule Id
        public Map<String, List<SpeakerViolation>> ruleViolations;
        // Key speaker Id, value speaker name
        public Map<String, String> ruleSpeakers;
        // Key speaker Id, value event speaker Id
        public Map<String, String> eventSpeakerKeys;
    }

    private class AttendeeField {
        private String attendeeId;
        private String status;
        private String accountType;

        private AttendeeField(String attendeeId, String accountType, String status) {
            this.attendeeId = attendeeId;
            this.accountType = accountType;
            this.status = status;
        }
    }

    private class SpeakerField {
        private String speakerId;
        private String status;
        private String speakerName;
    }

    private class SpeakerViolation {
        private String speakerId;
        private String violatedId;
        private Integer currentAttendance;
    }

    private class SpeakerCap {
        private String speakerId;
        private String name;
        private Decimal annualCap;
        private Decimal remainingCap;

        private SpeakerCap(String speakerId, String name, Decimal annualCap, Decimal remainingCap) {
            this.speakerId = speakerId;
            this.name = name;
            this.annualCap = annualCap;
            this.remainingCap = remainingCap;
        }
    }

    private class SpeakerRatioRule {
        private String ruleId;
        private Set<String> accountTypes;
        private Set<String> speakerStatuses;

        private SpeakerRatioRule(String ruleId, Set<String> accountTypes, Set<String> speakerStatuses) {
            this.ruleId = ruleId;
            this.accountTypes = accountTypes;
            this.speakerStatuses = speakerStatuses;
        }
    }

    private void initSpeakerRequest() {
        EM_Event_vod__c event = [SELECT RecordTypeId, Country_vod__c, Start_Time_vod__c, Topic_vod__c,
            (SELECT Id, Account_vod__c, User_vod__c, Contact_vod__c, Attendee_Account_Type_vod__c, Status_vod__c FROM EM_Attendee_Event_vod__r),
            (SELECT Id, Speaker_vod__c, Status_vod__c, Speaker_Name_vod__c FROM EM_Event_Speaker_vod__r) 
            FROM EM_Event_vod__c WHERE Id = :speakerRequest.eventId];

        speakerRequest.startTime = event.Start_Time_vod__c;
        speakerRequest.eventType = VeevaEmBusRuleUtils.getDeveloperName(EVENT_RECORD_TYPE_MAP, event.RecordTypeId);
        speakerRequest.country = event.Country_vod__c;
        speakerRequest.topic = event.Topic_vod__c;

        speakerRequest.attendeeFields = new List<AttendeeField>();
        speakerNameMap = new Map<String, String>();
        speakerRequest.speakerFields  = new List<SpeakerField>();
        speakerRequest.eventSpeakerKeys = new Map<String, String>();
        List<SObject> eventAttendees = event.getSObjects('EM_Attendee_Event_vod__r');
        if (VeevaEmBusRuleUtils.isNotEmpty(eventAttendees)) {
            for (SObject attendee : eventAttendees) {
                String accountId = (String)attendee.get('Account_vod__c');
                String userId = (String)attendee.get('User_vod__c');
                String contactId = (String)attendee.get('Contact_vod__c');
                String attendeeId = VeevaEmBusRuleUtils.getAttendeeId(accountId, userId, contactId);
                if (String.isNotBlank(attendeeId)) {
                    AttendeeField attendeeField = new AttendeeField(attendeeId, (String)attendee.get('Attendee_Account_Type_vod__c'), (String)attendee.get('Status_vod__c'));
                    speakerRequest.attendeeFields.add(attendeeField);
                }
            }
        }
        if (String.isNotBlank(speakerRequest.eventAction)) {
            List<SObject> eventSpeakers = event.getSObjects('EM_Event_Speaker_vod__r');
            if (VeevaEmBusRuleUtils.isNotEmpty(eventSpeakers)) {
                speakerRequest.speakerIds = new Set<String>();
                for (SObject speaker : eventSpeakers) {
                    String speakerId = (String)speaker.get(SPEAKER_FIELD);
                    if (String.isNotBlank(speakerId)) {
                        speakerRequest.speakerIds.add(speakerId);
                        SpeakerField speakerField = new SpeakerField();
                        speakerField.speakerId = speakerId;
                        speakerField.status = (String)speaker.get('Status_vod__c');
                        speakerRequest.speakerFields.add(speakerField);
                        speakerRequest.eventSpeakerKeys.put(speakerId, (String)speaker.get('Id'));
                        speakerNameMap.put(speakerId, (String)speaker.get('Speaker_Name_vod__c'));
                    }
                }
            }
        } else if (speakerRequest.hasSpeakers()) {
            for (EM_Speaker_vod__c speaker : [SELECT Id, Name FROM EM_Speaker_vod__c WHERE Id IN : speakerRequest.speakerIds]) {
                speakerNameMap.put(speaker.Id, speaker.Name);
            }
        }
    }

    private void findRuleViolations() {
        Map<String, List<SpeakerViolation>> ruleViolations = new Map<String, List<SpeakerViolation>>();
        Map<String, String> ruleSpeakers = new Map<String, String>();
        Map<String, VeevaEmBusRuleModel.BusinessRule> violatedRuleMap = new Map<String, VeevaEmBusRuleModel.BusinessRule>();

        List<String> idClauseBatch = new List<String>();
        if (speakerRequest.hasSpeakers()) {
            idClauseBatch = VeevaEmBusRuleUtils.composeIdClause(new List<String>(speakerRequest.speakerIds), SPEAKER_FIELD);
        }
        for (VeevaEmBusRuleModel.BusinessRule businessRule : businessRules) {
            List<SpeakerViolation> violations;
            switch on businessRule.developerName {
                when 'EM_Per_Speaker_Engagement_Limit_Rule_vod', 'EM_Cross_Event_Per_Speaker_Engagement_Limit_Rule_vod' {
                    violations = getPerSpeakerRuleViolation(idClauseBatch, businessRule, ruleSpeakers);
                }
                when 'EM_Speaker_Attendance_Expense_Cap_Rule_vod' {
                    violations = getSpeakerExpenseCapViolation(businessRule, ruleSpeakers);
                }
                when 'EM_Per_Event_Speaker_Ratio_Rule_vod' {
                    violations = getPerEventSpeakerRatioViolation(businessRule);
                }
                when 'EM_Per_Event_Speaker_Limit_Rule_vod' {
                    violations = getPerEventSpeakerLimitViolation(businessRule);
                } 
                when else {
                    violations = new List<SpeakerViolation>();
                }
            }
            if (!violations.isEmpty()) {
                ruleViolations.put(businessRule.id, violations);
                violatedRuleMap.put(businessRule.id, businessRule);
            }
        }
        speakerResult.ruleViolations = ruleViolations;
        speakerResult.ruleSpeakers = ruleSpeakers;
        speakerResult.eventSpeakerKeys = speakerRequest.eventSpeakerKeys;
        if (String.isNotBlank(speakerRequest.eventAction) && !ruleViolations.isEmpty()) {
            filterSoftWarningRules(perEventWarningTypeRules);
            createEventHistory(violatedRuleMap);
        }
    }

    private List<SpeakerViolation> getSpeakerExpenseCapViolation(VeevaEmBusRuleModel.BusinessRule businessRule, Map<String, String> ruleSpeakers) {
        List<SpeakerViolation> violations = new List<SpeakerViolation>();
        if (speakerRequest.hasSpeakers()) {
            getSpeakerCap();
            for (SpeakerCap cap : speakerCaps) {
                if (cap.annualCap != null && cap.annualCap >= 0 && cap.remainingCap != null && 
                    cap.remainingCap < cap.annualCap * businessRule.percentThreshold / 100) {
                    SpeakerViolation violation = new SpeakerViolation();
                    String speakerId = cap.speakerId;
                    violation.speakerId = speakerId;
                    // set event speaker Id as violated Id, could be null for potential warning
                    violation.violatedId = speakerRequest.eventSpeakerKeys.get(speakerId);
                    violations.add(violation);
                    if (!ruleSpeakers.containsKey(speakerId)) {
                        ruleSpeakers.put(speakerId, speakerNameMap.get(speakerId));
                    }
                }
            }
        }
        return violations;
    }

    private void getSpeakerCap() {
        if (speakerCaps == null) {
            speakerCaps = new List<SpeakerCap>();
            for (EM_Speaker_vod__c speaker : [SELECT Id, Name, Annual_Cap_vod__c, Cap_Remaining_Committed_vod__c FROM EM_Speaker_vod__c WHERE Id IN : new List<String>(speakerRequest.speakerIds)]) {
                SpeakerCap speakerCap = new SpeakerCap(speaker.Id, speaker.Name, speaker.Annual_Cap_vod__c, speaker.Cap_Remaining_Committed_vod__c);
                speakerCaps.add(speakerCap);
            }
        }
    }

    private List<SpeakerViolation> getPerEventSpeakerRatioViolation(VeevaEmBusRuleModel.BusinessRule businessRule) {
        List<SpeakerViolation> violations = new List<SpeakerViolation>();
        if (speakerRequest.hasSpeakers()) {
            Integer speakerCount = getSpeakerCount(businessRule.getPerEventSpeakerStatus());
            Integer attendeeCount = getAttendeeCount(businessRule.getPerEventAttendeeStatus(), businessRule.getAccountTypes());
            if (attendeeCount < businessRule.limitQuantity * speakerCount) {
                SpeakerViolation violation = new SpeakerViolation();
                violation.violatedId = speakerRequest.eventId;
                violations.add(violation);
                addWarningTypeRules(businessRule, perEventWarningTypeRules);
            }
        }
        return violations;
    }
    
    private Integer getAttendeeCount(Set<String> statusList, Set<String> accountTypeList) {
        Integer count = 0;
        if (speakerRequest.attendeeFields != null) {
            for (AttendeeField attendeeField : speakerRequest.attendeeFields) {
                if ((statusList.isEmpty() || statusList.contains(attendeeField.status)) && (accountTypeList.isEmpty() || accountTypeList.contains(attendeeField.accountType))) {
                    count ++;
                }
            }
        }
        return count;
    }

    private Integer getSpeakerCount(Set<String> statusList) {
        Integer count = 0;
        if (speakerRequest.speakerFields != null) {
            for (SpeakerField speakerField : speakerRequest.speakerFields) {
                if (statusList.isEmpty() || statusList.contains(speakerField.status)) {
                    count ++;
                }
            }
        }
        return count;
    }

    private List<SpeakerViolation> getPerEventSpeakerLimitViolation(VeevaEmBusRuleModel.BusinessRule businessRule) {
        List<SpeakerViolation> violations = new List<SpeakerViolation>();
        Integer speakerCount = 0;
        if (speakerRequest.hasSpeakers()) {
            speakerCount = getSpeakerCount(businessRule.getPerEventSpeakerStatus());
        }
        Integer minQuantity = businessRule.minimumQuantity;
        Integer maxQuantity = businessRule.maximumQuantity;
        if (minQuantity != null && speakerCount < minQuantity || maxQuantity != null && speakerCount > maxQuantity ) {
            SpeakerViolation violation = new SpeakerViolation();
            violation.violatedId = speakerRequest.eventId;
            violations.add(violation);
            addWarningTypeRules(businessRule, perEventWarningTypeRules);
        }
        return violations;
    }

    private List<SpeakerViolation> getPerSpeakerRuleViolation(List<String> idClauseBatch, VeevaEmBusRuleModel.BusinessRule businessRule, Map<String, String> ruleSpeakers) {
        List<SpeakerViolation> violations = new List<SpeakerViolation>();
        if (businessRule.perEventTopic && String.isEmpty(speakerRequest.topic)) {
            return violations;
        }
        String ruleQuery = composeQuery(businessRule, speakerRequest.startTime, speakerRequest.eventId);
        for (String batch : idClauseBatch) {
            String query = composeBatchQuery(businessRule, ruleQuery, batch, speakerRequest.topic);
            for (sObject queryRow : Database.query(query)) {
                SpeakerViolation violation = new SpeakerViolation();
                String speakerId = (String)queryRow.get('Speaker_vod__c');
                violation.speakerId = speakerId;
                violation.currentAttendance = (Integer)queryRow.get('Total');
                // set event speaker Id as violated Id, could be null for potential warning
                violation.violatedId = speakerRequest.eventSpeakerKeys.get(speakerId);
                if (!ruleSpeakers.containsKey(speakerId)) {
                    ruleSpeakers.put(speakerId, speakerNameMap.get(speakerId));
                }
                violations.add(violation);
            }
        }
        return violations;
    }

    private String composeSelectCriteria(VeevaEmBusRuleModel.BusinessRule rule, Datetime startTime, String selectFields, String objectName) {
        String query = 'SELECT COUNT(' + EVENT_RELATIONSHIP + '.Id) Total, ' + selectFields;
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
            when else { // 'Calendar_Year_vod'
                minDatetime = datetime.newInstance(startTime.year(), 1, 1, 0, 0, 0);
                maxDatetime = datetime.newInstance(startTime.year() + 1, 1, 1, 0, 0, 0);
            }
        }
        String datetimeFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
        String formattedMin = minDateTime.formatGmt(datetimeFormat);
        String formattedMax = maxDatetime.formatGmt(datetimeFormat);
        query += ' FROM ' + objectName + ' WHERE ' + EVENT_RELATIONSHIP + '.Start_Time_vod__c >= ' + formattedMin + ' AND ' + EVENT_RELATIONSHIP + '.Start_Time_vod__c < ' + formattedMax;
        return query;
    }

    private String composeQuery(VeevaEmBusRuleModel.BusinessRule rule, Datetime startTime, String eventId) {
        String query = composeSelectCriteria(rule, startTime, SPEAKER_FIELD, 'EM_Event_Speaker_vod__c');
        String status = composeStatusCriteria(rule.getEventSpeakerStatus());
        if (String.isNotBlank(status)) {
            query += ' AND (' + status + ')';
        }
        String config = composeEventTypeCountryCriteria(rule.configs);
        if (String.isNotBlank(config)) {
            query += ' AND (' + config + ')';
        }
        query += ' AND ' + EVENT_RELATIONSHIP + '.Id !=\''+ eventId + '\'';
        return query;
    }

    private String composeBatchQuery(VeevaEmBusRuleModel.BusinessRule rule, String ruleQuery, String batch, String topic) {
        String query = ruleQuery;
        query += ' AND (' + batch + ')';
        if (rule.perEventTopic) {
            query += ' AND ' + EVENT_RELATIONSHIP + '.Topic_vod__c = \'' + topic + '\'';
        }
        query += ' GROUP BY ' + SPEAKER_FIELD;
        query += ' HAVING COUNT(' + EVENT_RELATIONSHIP + '.Id) > = ' + rule.limitQuantity;
        return query;
    }

    private String composeStatusCriteria(Map<String, Set<String>> statusPairs) {
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
 
    private String composeEventTypeCountryCriteria(List<VeevaEmBusRuleModel.BusinessRuleConfig> configs) {
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

    private void createEventHistory(Map<String, VeevaEmBusRuleModel.BusinessRule> ruleMap) {
        List<EM_Event_History_vod__c> sObjects = new List<EM_Event_History_vod__c>();

        RecordTypeInfo recordType = Schema.SObjectType.EM_Event_History_vod__c.getRecordTypeInfosByDeveloperName().get('EM_Business_Rule_History_vod');
        if (recordType == null) {
            return;
        }
        String recordTypeId = recordType.getRecordTypeId();
        Map<String, List<SpeakerViolation>> ruleViolations = speakerResult.ruleViolations;
        Map<String, String> ruleSpeakeres = speakerResult.ruleSpeakers;
        Map<String, String> eventSpeakerKeys = speakerRequest.eventSpeakerKeys;

        for (String ruleId : ruleViolations.keySet()) {
            VeevaEmBusRuleModel.BusinessRule rule = ruleMap.get(ruleId);
            List<SpeakerViolation> speakerViolations = ruleViolations.get(ruleId);
            EM_Event_History_vod__c history = null;
            String configId = rule.getConfigurationId(speakerRequest.eventType, speakerRequest.country);
            for (SpeakerViolation violation : speakerViolations) {
                history = createEventHistoryObject(recordTypeId, speakerRequest.eventId, configId, speakerRequest.eventAction, speakerRequest.platform, rule);
                history.Record_Violated_ID_vod__c = violation.violatedId;
                if (String.isNotBlank(violation.speakerId)) {
                    history.EM_Event_Speaker_vod__c = violation.violatedId;
                    history.Record_Violated_Name_vod__c = ruleSpeakeres.get(violation.speakerId);
                }
                sObjects.add(history);
            }
        }
        speakerResult.eventHistoryBatchId = executeEventHistoryBatch(sObjects);
    }

    public static void setResponse(SpeakerResult result, RestResponse response, Boolean success, String errorMessage, Integer statusCode) {
        result.success = success;
        result.errorMessage = errorMessage;
        response.statusCode = statusCode;
    }

    private void filterSoftWarningRules(Map<String, List<String>> warningTypeRules) {
        if (!warningTypeRules.isEmpty()) {
            List<String> hardWarningRules = warningTypeRules.get(HARD_WARNING);
            List<String> softWarningRules = warningTypeRules.get(SOFT_WARNING);
            if (VeevaEmBusRuleUtils.isNotEmpty(hardWarningRules) && VeevaEmBusRuleUtils.isNotEmpty(softWarningRules)) {
                for (String ruleId : softWarningRules) {
                    speakerResult.ruleViolations.remove(ruleId);
                }
            }
        }
    }
}