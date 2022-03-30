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
 * VeevaEmBusRuleModel constructs the event business rule object and provides common model related functions.
 */
public inherited sharing class VeevaEmBusRuleModel {
    private static Map<Id, Schema.RecordTypeInfo> RULE_RECORD_TYPE_MAP = Schema.SObjectType.EM_Business_Rule_vod__c.getRecordTypeInfosById();
    private static final Set<String> BUS_RULE_CROSS_EVENT_RECORD_TYPES = new Set<String>{'EM_Cross_Event_Per_Attendee_Attendance_Limit_Rule_vod', 'EM_Cross_Event_Meal_Opt_In_Attendance_Limit_Rule_vod', 'EM_Cross_Event_Attendee_Expense_Cap_Rule_vod', 'EM_Cross_Event_Per_Speaker_Engagement_Limit_Rule_vod'};
    private static final Set<String> BUS_RULE_PER_EVENT_EXPENSE_TYPES = new Set<String>{'EM_Per_Event_Expense_Limit_Rule_vod', 'EM_Per_Event_Attendee_Expense_Limit_Rule_vod', 'EM_Actual_Versus_Estimate_Expense_Threshold_Rule_vod'};
    private static final Set<String> PER_EVENT_RULE_RECORD_TYPES = new Set<String>{'EM_Per_Event_Attendance_Limit_Rule_vod', 'EM_Per_Event_Speaker_Limit_Rule_vod'};

    private static final String SEPARATOR = ';;';

    public class BusinessRule {
        public String id;
        public String recordTypeId;
        public String developerName;
        public String warningType;
        public String businessRuleId;
        public String attendeeAccountType;
        public String attendeeStatus;
        public String eventStatus;
        public String expenseCategory;
        public String expenseType;
        public String dateThresholdType;
        public boolean perEventTopic;
        public Integer rollingPeriod;
        public Integer limitQuantity;
        public Integer minimumQuantity;
        public Integer maximumQuantity;
        public String currencyIsoCode;
        public double minimumSpendLimit;
        public double maximumSpendLimit;
        public double percentThreshold;
        public String speakerStatus;
        public String runRuleEventAction;
        public String eventMaterial;

        public List<BusinessRuleConfig> configs;

        public void addConfig(BusinessRuleConfig config) {
            if (configs == null) {
                configs = new List<BusinessRuleConfig>();
            }
            configs.add(config);
        }

        public boolean isPerEventRule() {
            return PER_EVENT_RULE_RECORD_TYPES.contains(developerName);
        }

        public boolean isMealOptInRule() {
            return 'EM_Meal_Opt_In_Attendance_Limit_Rule_vod'.equals(developerName) || 'EM_Cross_Event_Meal_Opt_In_Attendance_Limit_Rule_vod'.equals(developerName);
        }
        
        public boolean isPerEventExpenseRule() {
            return BUS_RULE_PER_EVENT_EXPENSE_TYPES.contains(developerName);
        }

        public boolean isCrossEventRule() {
            return BUS_RULE_CROSS_EVENT_RECORD_TYPES.contains(developerName);
        }

        public boolean isSpeakerAttendanceQualificationRule() {
            return 'EM_Speaker_Attendance_Qualification_Rule_vod'.equals(developerName);
        }

        public Map<String, Set<String>> getEventAttendeeStatus() {
            return getEventAndObjectStatus(attendeeStatus);
        }

        public Map<String, Set<String>> getEventSpeakerStatus() {
            return getEventAndObjectStatus(speakerStatus);
        }

        private Map<String, Set<String>> getEventAndObjectStatus(String status) {
            Map<String, Set<String>> eventObjectStatus = new Map<String, Set<String>>();
            if (String.isNotBlank(status)) {
                String[] statusPair = getSplitValues(status, SEPARATOR);
                for (String pair : statusPair) {
                    Set<String> objectStatusSet = new Set<String>();
                    String[] statusArray = getSplitValues(pair, ':');
                    if (statusArray.size() == 2) {
                        objectStatusSet.addAll(getSplitValues(statusArray[1], ','));
                        eventObjectStatus.put(statusArray[0], objectStatusSet);
                    }
                }
            }
            return eventObjectStatus;
        }

        public Set<String> getPerEventAttendeeStatus() {
            return getPerEventObjectStatus(attendeeStatus);
        }
    
        public Set<String> getPerEventSpeakerStatus() {
            return getPerEventObjectStatus(speakerStatus);
        }

        private Set<String> getPerEventObjectStatus(String status) {
            Set<String> statusSet = new Set<String>();
            if (String.isNotBlank(status)) {
                statusSet.addAll(getSplitValues(status, SEPARATOR));
            }
            return statusSet;
        }

        public Set<String> getAccountTypes() {
            Set<String> accountTypes = new Set<String>();
            if (String.isNotBlank(attendeeAccountType)) {
                accountTypes.addAll(getSplitValues(attendeeAccountType, SEPARATOR));
            }
            return accountTypes;
        }
        
        public Set<String> getEventStatus() {
            Set<String> eventStatusSet = new Set<String>();
            if (String.isNotBlank(eventStatus)) {
                eventStatusSet.addAll(getSplitValues(eventStatus, SEPARATOR));
            }
            return eventStatusSet;
        }

        public String getConfigurationId(String eventType, String eventCountry) {
            String configurationId = '';
            for (BusinessRuleConfig config : configs) {
                if ((config.eventType.equals(eventType)) && (config.country == null || config.country.equals(eventCountry))) {
                    configurationId = config.configurationId;
                    break;
                }
            }
            return configurationId;
        }

        public String getRuleKey() {
            String key = developerName + runRuleEventAction + warningType;
            switch on developerName {
                when 'EM_Per_Attendee_Attendance_Limit_Rule_vod', 'EM_Cross_Event_Per_Attendee_Attendance_Limit_Rule_vod', 'EM_Meal_Opt_In_Attendance_Limit_Rule_vod', 'EM_Cross_Event_Meal_Opt_In_Attendance_Limit_Rule_vod' {
                    key +=  perEventTopic + dateThresholdType;
                }
                when 'EM_Per_Event_Attendee_Expense_Limit_Rule_vod', 'EM_Per_Event_Expense_Limit_Rule_vod' {
                    key +=  expenseType + expenseCategory;
                }
                when 'EM_Attendee_Expense_Cap_Rule_vod', 'EM_Cross_Event_Attendee_Expense_Cap_Rule_vod' {
                    key +=  expenseType + dateThresholdType;
                }
                when else {
                    // do nothing for 'EM_Per_Event_Attendance_Limit_Rule_vod', 'EM_Per_Event_Speaker_Ratio_Rule_vod'
                }
            }
            return key;
        }

        public String getEventMaterialKey() {
            String requiredAttachment = 'Optional_vod';
            if ('Hard_Warning_vod'.equals(warningType)) {
                requiredAttachment = 'Required_vod';
            }
            return runRuleEventAction + eventMaterial + requiredAttachment;
        }
    }

    public class BusinessRuleConfig{
        public String id;
        public String eventType;
        public String country;
        public String configurationId;

        public BusinessRuleConfig(String id, String eventType, String country, String configurationId) {
            this.id = id;
            this.eventType = eventType;
            this.country = country;
            this.configurationId = configurationId;
        }
    }

    public class BadDataException extends Exception {}

    public class RuleAttendee {
        public String accountId;
        public String userId;
        public String contactId;
        public String attendeeName;
        public String attendeeFirstName;
        public String attendeeLastName;

        public RuleAttendee(String accountId, String userId, String contactId) {
            this.accountId = accountId;
            this.userId = userId;
            this.contactId = contactId;
        }
    }

    private static List<String> getSplitValues(String inputValue, String separator) {
        List<String> values = new List<String>();
        if (String.isNotBlank(inputValue)) {
            values = inputValue.split(separator);
        }
        return values;
    }

    public static List<BusinessRule> getBusinessRules(Set<String> ruleIds, String eventType, String eventCountry, Datetime startTime) {
        Date dt = startTime.date();
        String querySql = 'SELECT Id, Event_Type_vod__c, Country_vod__c, Limit_Quantity_vod__c, Minimum_Quantity_vod__c, Event_Business_Rule_vod__r.EM_Business_Rule_Id_vod__c,'
            +'Maximum_Quantity_vod__c, Event_Business_Rule_vod__r.Id, Event_Business_Rule_vod__r.RecordTypeId, Event_Business_Rule_vod__r.Global_Rule_vod__c,'
            + 'Event_Business_Rule_vod__r.Attendee_Account_Type_vod__c, Event_Business_Rule_vod__r.Per_Event_Topic_vod__c, Event_Business_Rule_vod__r.Attendee_Status_vod__c,'
            + 'Event_Business_Rule_vod__r.Limit_Quantity_vod__c, Event_Business_Rule_vod__r.Date_Threshold_Type_vod__c, Event_Business_Rule_vod__r.Rolling_Period_vod__c,'
            + 'Rule_Start_Date_vod__c, Rule_End_Date_vod__c, Event_Business_Rule_vod__r.Warning_Type_vod__c, EM_Business_Rule_Configuration_Id_vod__c,'
            + 'Event_Business_Rule_vod__r.Expense_Category_vod__c,Event_Business_Rule_vod__r.Event_Status_vod__c,Event_Business_Rule_vod__r.Expense_Type_vod__c,'
            + 'Minimum_Spend_Limit_vod__c,Maximum_Spend_Limit_vod__c,Event_Business_Rule_vod__r.Percent_Threshold_vod__c,Event_Business_Rule_vod__r.Run_Rule_Event_Action_vod__c,'
            + 'Event_Business_Rule_vod__r.Minimum_Spend_Limit_vod__c,Event_Business_Rule_vod__r.Maximum_Spend_Limit_vod__c, Event_Business_Rule_vod__r.Speaker_Status_vod__c,'
            + 'Event_Business_Rule_vod__r.EM_Event_Material_vod__c';
            
        if(MultiCurrencyUtil.isMultiCurrencyOrg()){
            querySql += ' , CurrencyIsoCode, Event_Business_Rule_vod__r.CurrencyIsoCode';
        }
        querySql += ' FROM EM_Business_Rule_Configuration_vod__c WHERE Event_Business_Rule_vod__c IN ' 
            + VeevaEmBusRuleUtils.toCommaSeparated(new List<String>(ruleIds)) +' AND Rule_Start_Date_vod__c <= ' + String.valueOf(dt) +' AND Rule_End_Date_vod__c >= ' + String.valueOf(dt);
        querySql += ' ORDER BY Event_Business_Rule_vod__r.Warning_Type_vod__c ASC';
        List<EM_Business_Rule_Configuration_vod__c> configs = Database.query(querySql);
        Map<String, BusinessRule> businessRuleMap = new Map<String, BusinessRule>();
        Map<Id, Schema.RecordTypeInfo> ruleRecordTypeMap = Schema.SObjectType.EM_Business_Rule_vod__c.getRecordTypeInfosById();
        for (EM_Business_Rule_Configuration_vod__c config : configs) {
            EM_Business_Rule_vod__c rule = config.Event_Business_Rule_vod__r;
            BusinessRule businessRule = businessRuleMap.get(rule.Id);
            if (businessRule == null) {
                businessRule = new BusinessRule();
            } 
            businessRule.id = rule.Id;
            businessRule.warningType = rule.Warning_Type_vod__c;
            businessRule.businessRuleId = rule.EM_Business_Rule_Id_vod__c;
            businessRule.recordTypeId = rule.RecordTypeId;
            businessRule.developerName = VeevaEmBusRuleUtils.getDeveloperName(ruleRecordTypeMap, businessRule.recordTypeId);
            businessRule.eventStatus = rule.Event_Status_vod__c;
            businessRule.expenseCategory = rule.Expense_Category_vod__c;
            businessRule.expenseType = rule.Expense_Type_vod__c;
            businessRule.percentThreshold = rule.Percent_Threshold_vod__c;
            businessRule.speakerStatus = rule.Speaker_Status_vod__c;
            businessRule.eventMaterial = rule.EM_Event_Material_vod__c;
            if (businessRule.isCrossEventRule()) {
                if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                    businessRule.currencyIsoCode = (String)rule.get('CurrencyIsoCode');
                }
                businessRule.minimumSpendLimit = rule.Minimum_Spend_Limit_vod__c;
                businessRule.maximumSpendLimit = rule.Maximum_Spend_Limit_vod__c;
                businessRule.limitQuantity = Integer.valueOf(rule.Limit_Quantity_vod__c);
            } else {
                if (!matchEventField(config.Event_Type_vod__c, config.Country_vod__c, eventType, eventCountry)) {
                    continue;
                }
                if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                    businessRule.currencyIsoCode = (String)config.get('CurrencyIsoCode');
                }
                businessRule.minimumSpendLimit = config.Minimum_Spend_Limit_vod__c;
                businessRule.maximumSpendLimit = config.Maximum_Spend_Limit_vod__c;
                businessRule.limitQuantity = Integer.valueOf(config.Limit_Quantity_vod__c);
            }
            if (businessRule.isPerEventRule()) {
                businessRule.minimumQuantity = Integer.valueOf(config.Minimum_Quantity_vod__c);
                businessRule.maximumQuantity = Integer.valueOf(config.Maximum_Quantity_vod__c);
            }
            businessRule.attendeeAccountType = rule.Attendee_Account_Type_vod__c;
            businessRule.attendeeStatus = rule.Attendee_Status_vod__c;
            businessRule.perEventTopic = Boolean.valueOf(rule.Per_Event_Topic_vod__c);
            businessRule.dateThresholdType = rule.Date_Threshold_Type_vod__c;
            businessRule.rollingPeriod = Integer.valueOf(rule.Rolling_Period_vod__c);
            businessRule.runRuleEventAction = rule.Run_Rule_Event_Action_vod__c;
            
            BusinessRuleConfig businessRuleConfig = new BusinessRuleConfig(config.Id, config.Event_Type_vod__c, config.Country_vod__c, config.EM_Business_Rule_Configuration_Id_vod__c);
            businessRule.addConfig(businessRuleConfig);
            businessRuleMap.put(businessRule.id, businessRule);
        }

        List<String> rulesToRemove = new List<String>();
        for (String ruleId : businessRuleMap.keySet()) {
            BusinessRule businessRule = businessRuleMap.get(ruleId);
            if (!businessRule.isCrossEventRule()) {
                continue;
            }
            boolean match = false;
            for (BusinessRuleConfig config : businessRule.configs) {
                if (matchEventField(config.eventType, config.country, eventType, eventCountry)) {
                    match = true;
                    break;
                }
            }
            if (!match) {
                rulesToRemove.add(ruleId);
            }
        }
        for (String ruleId : rulesToRemove) {
            businessRuleMap.remove(ruleId);
        }
        
        return businessRuleMap.isEmpty() ? new List<BusinessRule>() : businessRuleMap.values();
    }

    private static boolean matchEventField(String ruleEventType, String ruleCountry, String eventType, String eventCountry) {
        boolean match = ruleEventType.equals(eventType);
        if (match) {
            match = String.isBlank(ruleCountry) ? true : ruleCountry.equals(eventCountry); 
        }
        return match;
    }

    public static void convertAttendeeName(Set<String> accountNameIds, Map<String, RuleAttendee> ruleAttendees) {
        if (VeevaSettings.isEnableAccountParentDisplay() && !accountNameIds.isEmpty() && !ruleAttendees.isEmpty()) {
            List<Account> accounts = [SELECT Id, Formatted_Name_vod__c, Primary_Parent_vod__r.Formatted_Name_vod__c FROM Account WHERE Id IN :accountNameIds];
            for (Account account : accounts) {
                String id = account.Id;
                if (ruleAttendees.containsKey(id)) {
                    String name = account.Formatted_Name_vod__c;
                    if (account.Primary_Parent_vod__r != null) {
                        name += ' @ ' + account.Primary_Parent_vod__r.Formatted_Name_vod__c;
                    }
                    RuleAttendee ruleAttendee = ruleAttendees.get(id);
                    ruleAttendee.attendeeName = name;
                }
            }
        }
    }
    
}