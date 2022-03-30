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
 * Copyright (c) 2020 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * VeevaEmBusRuleConfigTriggerHandler validates the business rule configuration field values and checks configuration duplicate before insert/update the record. 
 */
public without sharing class VeevaEmBusRuleConfigTriggerHandler extends VeevaTriggerHandler {
    private static final String DUPLICATE_MESSAGE = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_RULE_ERROR', 'EVENT_MANAGEMENT', 'These changes were not applied because they resulted in duplicate rules or rule configurations: {0}');
    private static final String INVALID_DATA_MESSAGE = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('INVALID_DATA_INPUT', 'EVENT_MANAGEMENT', '{0} is invalid.');
    private static final String FIELD_SEPARATOR = '|';

    private static Map<String, Schema.RecordTypeInfo> EVENT_RECORD_TYPE_MAP = Schema.SObjectType.EM_Event_vod__c.getRecordTypeInfosByDeveloperName();
    private static Map<Id, Schema.RecordTypeInfo> RULE_RECORD_TYPE_MAP = Schema.SObjectType.EM_Business_Rule_vod__c.getRecordTypeInfosById();
    private static Map<String, Schema.SObjectField> CONFIG_FIELD_MAP = Schema.SObjectType.EM_Business_Rule_Configuration_vod__c.fields.getMap();
    
    private static final String RT_EE_MEAL = 'Expense_Estimate_Meal_Rule_vod';
    private static final String RT_EE_SPEAKER_TRAVEL = 'Expense_Estimate_Speaker_Travel_Rule_vod';
    private static final String RT_EE_SPEAKER_LODGING = 'Expense_Estimate_Speaker_Lodging_Rule_vod';
    private static final String RT_EE_AV_EQUIPMENT = 'Expense_Estimate_AV_Equipment_Rule_vod';
    private static final String RT_EE_FLAT_FEE = 'Expense_Estimate_Flat_Fee_Rule_vod';
    private static final String RT_ATTENDEE_ATTENDANCE = 'EM_Per_Attendee_Attendance_Limit_Rule_vod';
    private static final String RT_ATTENDEE_CROSS_EVENT_ATTENDANCE = 'EM_Cross_Event_Per_Attendee_Attendance_Limit_Rule_vod';
    private static final String RT_ATTENDEE_MEAL = 'EM_Meal_Opt_In_Attendance_Limit_Rule_vod';
    private static final String RT_ATTENDEE_CROSS_EVENT_MEAL = 'EM_Cross_Event_Meal_Opt_In_Attendance_Limit_Rule_vod';
    private static final String RT_ATTENDEE_EVENT = 'EM_Per_Event_Attendance_Limit_Rule_vod';
    private static final String RT_EXPENSE_LIMIT_PER_EVENT = 'EM_Per_Event_Expense_Limit_Rule_vod';
    private static final String RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE = 'EM_Per_Event_Attendee_Expense_Limit_Rule_vod';
    private static final String RT_EXPENSE_LIMIT_ATTENDEE_CAP = 'EM_Attendee_Expense_Cap_Rule_vod';
    private static final String RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER = 'EM_Per_Event_Speaker_Expense_Limit_Rule_vod';
    private static final String PT_SPEAKER_ENGAGEMENT_LIMIT = 'EM_Per_Speaker_Engagement_Limit_Rule_vod';
    private static final String RT_SPEAKER_RATIO_PER_EVENT = 'EM_Per_Event_Speaker_Ratio_Rule_vod';
    private static final String RT_SPEAKER_LIMIT_PER_EVENT = 'EM_Per_Event_Speaker_Limit_Rule_vod';

    private static final List<String> EE_COST_FIELD = new List<String>{'Cost_vod__c'};
    private static final List<String> LIMIT_QUANTITY_FIELD = new List<String>{'Limit_Quantity_vod__c'};
    private static final List<String> ATTENDEE_EVENT_FIELDS = new List<String>{'Minimum_Quantity_vod__c','Maximum_Quantity_vod__c'};
    private static final List<String> EXPENSE_LIMIT_FIELDS = new List<String>{'Minimum_Spend_Limit_vod__c','Maximum_Spend_Limit_vod__c'};

    private static final Map<String, List<String>> CONFIG_ID_FIELD_MAP = new Map<String, List<String>> {
        RT_EE_MEAL => EE_COST_FIELD,
        RT_EE_SPEAKER_TRAVEL => EE_COST_FIELD,
        RT_EE_SPEAKER_LODGING => EE_COST_FIELD,
        RT_EE_AV_EQUIPMENT => EE_COST_FIELD,
        RT_EE_FLAT_FEE => EE_COST_FIELD,
        RT_ATTENDEE_ATTENDANCE => LIMIT_QUANTITY_FIELD,
        RT_ATTENDEE_MEAL => LIMIT_QUANTITY_FIELD,
        RT_ATTENDEE_EVENT => ATTENDEE_EVENT_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT => EXPENSE_LIMIT_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE => EXPENSE_LIMIT_FIELDS,
        RT_EXPENSE_LIMIT_ATTENDEE_CAP => EXPENSE_LIMIT_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER => EXPENSE_LIMIT_FIELDS,
        PT_SPEAKER_ENGAGEMENT_LIMIT => LIMIT_QUANTITY_FIELD,
        RT_SPEAKER_RATIO_PER_EVENT => LIMIT_QUANTITY_FIELD,
        RT_SPEAKER_LIMIT_PER_EVENT => ATTENDEE_EVENT_FIELDS
    };

    private List<String> buttonNames = new List<String>();

    private List<EM_Business_Rule_Configuration_vod__c> newRuleConfigs = new List<EM_Business_Rule_Configuration_vod__c>();
    private List<EM_Business_Rule_Configuration_vod__c> oldRuleConfigs = new List<EM_Business_Rule_Configuration_vod__c>();
    private Map<ID, EM_Business_Rule_Configuration_vod__c> newRuleConfigsMap = new Map<ID, EM_Business_Rule_Configuration_vod__c>();
    private Map<ID, EM_Business_Rule_Configuration_vod__c> oldRuleConfigsMap = new Map<ID, EM_Business_Rule_Configuration_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newRuleConfigs = (List<EM_Business_Rule_Configuration_vod__c>) triggerNew;
        this.oldRuleConfigs = (List<EM_Business_Rule_Configuration_vod__c>) triggerOld;
        this.newRuleConfigsMap = (Map<ID, EM_Business_Rule_Configuration_vod__c>) triggerNewMap;
        this.oldRuleConfigsMap = (Map<ID, EM_Business_Rule_Configuration_vod__c>) triggerOldMap;
    }
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'EM_Business_Rule_Configuration_vod__c';
    }

    protected override void beforeInsert() {
        vodEmRuleConfigBeforeInsertUpdate();
    }
    
    protected override void beforeUpdate() {
        vodEmRuleConfigBeforeInsertUpdate();
    }

    private void vodEmRuleConfigBeforeInsertUpdate() {
        Set<String> ruleIds = new Set<String>();
        String ruleId;
        for (EM_Business_Rule_Configuration_vod__c config: newRuleConfigs) {
            ruleIds.add(config.Event_Business_Rule_vod__c);
        }
       
        // Get business rules and existing rule configurations
        Map<Id, EM_Business_Rule_vod__c> rules = new Map<Id, EM_Business_Rule_vod__c>();
        List<EM_Business_Rule_Configuration_vod__c> existingConfigs = new List<EM_Business_Rule_Configuration_vod__c>();
        if (ruleIds.size() > 0) {
            rules = new Map<Id, EM_Business_Rule_vod__c>([SELECT Id, Name, RecordTypeId, EM_Business_Rule_Id_vod__c
                FROM EM_Business_Rule_vod__c WHERE Id IN :ruleIds]);
            existingConfigs = [SELECT Event_Business_Rule_vod__c, Id, Name, Event_Type_vod__c, Country_vod__c, 
                Rule_Start_Date_vod__c, Rule_End_Date_vod__c
                FROM EM_Business_Rule_Configuration_vod__c WHERE Event_Business_Rule_vod__c IN :ruleIds];    
        }

        for (EM_Business_Rule_Configuration_vod__c config: newRuleConfigs) {
            // Set rule config Id
            ruleId = config.Event_Business_Rule_vod__c;
            if (ruleId != null && rules != null && rules.get(ruleId) != null) { 
                config.EM_Business_Rule_Configuration_Id_vod__c = getRuleConfigId(rules.get(ruleId).RecordTypeId, config);
            }
            
            if (!validateField(config)) {
                continue;
            }
           
            if (existingConfigs != null && !existingConfigs.isEmpty()){
                checkDuplicate(config, existingConfigs);
            } else {
                existingConfigs = new List<EM_Business_Rule_Configuration_vod__c>();
            }
            // Add new config to existing configs to check duplicate within new objects as well. 
            existingConfigs.add(config);
        }
    }

    @TestVisible private string getRuleConfigId(String ruleRecordTypeId, EM_Business_Rule_Configuration_vod__c config) {
        String developerName = '';
        Schema.RecordTypeInfo recordTypeInfo = RULE_RECORD_TYPE_MAP.get(ruleRecordTypeId);
        if (recordTypeInfo != null) {
            developerName = recordTypeInfo.getDeveloperName();
        }
        String configId = config.Event_Business_Rule_vod__c + FIELD_SEPARATOR + config.Event_Type_vod__c + FIELD_SEPARATOR + config.Country_vod__c;
        List<String> configFields = CONFIG_ID_FIELD_MAP.get(developerName);
        if (configFields != null && configFields.size() > 0) {
            for (String fieldName : configFields) {
                configId = configId + FIELD_SEPARATOR + config.get(fieldName);
            }
        }
        Date startDate = config.Rule_Start_Date_vod__c;
        Datetime startDatetime = datetime.newInstance(startDate.year(), startDate.month(),startDate.day());
    
        configId = configId + FIELD_SEPARATOR + startDatetime.format('yyyy-MM-dd');
        return configId;
    }

    private String getInvalidDataMessage(String fieldName) {
        return String.format(INVALID_DATA_MESSAGE, new string[]{CONFIG_FIELD_MAP.get(fieldName).getDescribe().getLabel()});
    }

    @TestVisible private boolean validateField(EM_Business_Rule_Configuration_vod__c config) {
        String eventType = config.Event_Type_vod__c;
        if (eventType == null || EVENT_RECORD_TYPE_MAP.get(eventType) == null || !EVENT_RECORD_TYPE_MAP.get(eventType).isActive()) {
            config.Event_Type_vod__c.addError(getInvalidDataMessage('Event_Type_vod__c'));
            return false;
        }
        return true;
    }

    @TestVisible private void checkDuplicate(EM_Business_Rule_Configuration_vod__c config, List<EM_Business_Rule_Configuration_vod__c> existingConfigs) {
        for (EM_Business_Rule_Configuration_vod__c existingConfig : existingConfigs) {
            if (isUniqueFieldMatch(config, existingConfig)) {
                config.addError(String.format(DUPLICATE_MESSAGE, new string[]{String.Valueof(existingConfig.Name)}));
                return;
            }
        }   
    }

    private boolean isUniqueFieldMatch (EM_Business_Rule_Configuration_vod__c config, EM_Business_Rule_Configuration_vod__c existingConfig) {
        // Existing config Id is null when it comes from new business rule configuration.
        return ((config.Id == null || existingConfig.Id == null || config.Id <> existingConfig.Id)
            && (config.Event_Business_Rule_vod__c == existingConfig.Event_Business_Rule_vod__c)
            && (config.Event_Type_vod__c == existingConfig.Event_Type_vod__c)
            && (config.Country_vod__c == existingConfig.Country_vod__c)
            && (config.Rule_Start_Date_vod__c >= existingConfig.Rule_Start_Date_vod__c
                && config.Rule_Start_Date_vod__c <= existingConfig.Rule_End_Date_vod__c
                || existingConfig.Rule_Start_Date_vod__c >= config.Rule_Start_Date_vod__c
                && existingConfig.Rule_Start_Date_vod__c <= config.Rule_End_Date_vod__c));
    }
    
}