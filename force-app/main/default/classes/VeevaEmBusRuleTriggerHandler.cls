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
 * VeevaEmBusRuleTriggerHandler validates the business rule field values and checks rule duplicate before insert/update the record. 
 */
public without sharing class VeevaEmBusRuleTriggerHandler extends VeevaTriggerHandler {

    private static final String DUPLICATE_MESSAGE = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('DUPLICATE_RULE_ERROR', 'EVENT_MANAGEMENT', 'These changes were not applied because they resulted in duplicate rules or rule configurations: {0}');
    private static final String DISABLE_EDIT_MESSAGE = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('EM_BUSINESS_RULE_EDIT_ERROR', 'EVENT_MANAGEMENT', '{0} cannot be edited.');
    private static final String INVALID_DATA_MESSAGE = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('INVALID_DATA_INPUT', 'EVENT_MANAGEMENT', '{0} is invalid.');
    private static final String EXPENSE_ESTIMATE_EXPENSE_TYPE_MESSAGE = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('EM_EXPENSE_ESTIMATE_RULE_EXPENSE_TYPE', 'EVENT_MANAGEMENT', 'The Expense Type cannot have a Parent Expense Type. Please select a valid expense type to save.');
    private static final String EXPENSE_LIMIT_EXPENSE_TYPE_MESSAGE = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('EM_EXPENSE_LIMIT_RULE_EXPENSE_TYPE', 'EVENT_MANAGEMENT', 'The Expense Type cannot have a Parent Expense Type. Please select a valid expense type to save.');

    private static final String FIELD_SEPARATOR = '|';

    private static Map<Id, Schema.RecordTypeInfo> RULE_RECORD_TYPE_MAP = Schema.SObjectType.EM_Business_Rule_vod__c.getRecordTypeInfosById();
    private static Map<String, Schema.SObjectField> RULE_FIELD_MAP = Schema.SObjectType.EM_Business_Rule_vod__c.fields.getMap();
    private static List<Schema.PicklistEntry> EVENT_STATUS_PICKLIST_VALUES = EM_Event_vod__c.Status_vod__c.getDescribe().getPicklistValues();
    private static List<Schema.PicklistEntry> ATTENDEE_STATUS_PICKLIST_VALUES = EM_Attendee_vod__c.Status_vod__c.getDescribe().getPicklistValues();
    private static List<Schema.PicklistEntry> SPEAKER_STATUS_PICKLIST_VALUES = EM_Event_Speaker_vod__c.Status_vod__c.getDescribe().getPicklistValues();

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
    private static final String RT_EXPENSE_LIMIT_CROSS_EVENT_ATTENDEE_CAP = 'EM_Cross_Event_Attendee_Expense_Cap_Rule_vod';
    private static final String RT_EXPENSE_LIMIT_ACTUAL_VS_ESTIMATE_THRESHOLD = 'EM_Actual_Versus_Estimate_Expense_Threshold_Rule_vod';
    private static final String RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER = 'EM_Per_Event_Speaker_Expense_Limit_Rule_vod';
    private static final String PT_SPEAKER_ENGAGEMENT_LIMIT = 'EM_Per_Speaker_Engagement_Limit_Rule_vod';
    private static final String RT_SPEAKER_CROSS_EVENT_ENGAGEMENT_LIMIT = 'EM_Cross_Event_Per_Speaker_Engagement_Limit_Rule_vod';
    private static final String RT_SPEAKER_ATTENDANCE_EXPENSE_CAP = 'EM_Speaker_Attendance_Expense_Cap_Rule_vod';
    private static final String RT_SPEAKER_RATIO_PER_EVENT = 'EM_Per_Event_Speaker_Ratio_Rule_vod';
    private static final String RT_SPEAKER_LIMIT_PER_EVENT = 'EM_Per_Event_Speaker_Limit_Rule_vod';
    private static final String RT_SPEAKER_ATTENDEE_QUALIFICATION = 'EM_Speaker_Attendance_Qualification_Rule_vod';
    private static final String RT_REQUIRED_MATERIAL = 'EM_Required_Event_Material_Rule_vod';

    private static final List<String> EE_MEAL_FIELDS = new List<String>{'Meal_Type_vod__c'};
    private static final List<String> EE_SPEAKER_TRAVEL_FIELDS = new List<String>{'Speaker_Transportation_Method_vod__c'};
    private static final List<String> EE_SPEAKER_LODGING_FIELDS = new List<String>{'Speaker_Lodging_Type_vod__c'};
    private static final List<String> EE_AV_EQUIPMENT_FIELDS = new List<String>{'AV_Equipment_vod__c'};
    private static final List<String> EE_FLAT_FEE_FIELDS = new List<String>{'Flat_Fee_Expense_vod__c'};
    private static final List<String> UNMODIFIED_RULE_FIELDS = new List<String>{'Global_Rule_vod__c'};
    private static final List<String> UNMODIFIED_MATERIAL_RULE_FIELDS = new List<String>{'Global_Rule_vod__c','EM_Event_Material_vod__c'};
    private static final List<String> ATTENDEE_ATTENDANCE_FIELDS = new List<String>{'Attendee_Account_Type_vod__c','Per_Event_Topic_vod__c','Date_Threshold_Type_vod__c','Warning_Type_vod__c'};
    private static final List<String> ATTENDEE_MEAL_FIELDS = ATTENDEE_ATTENDANCE_FIELDS;
    private static final List<String> ATTENDEE_EVENT_FIELDS = new List<String>{'Attendee_Account_Type_vod__c','Warning_Type_vod__c'};
    private static final List<String> EXPENSE_LIMIT_PER_EVENT_FIELDS = new List<String>{'Expense_Type_vod__c','Expense_Category_vod__c','Event_Status_vod__c','Warning_Type_vod__c'};
    private static final List<String> EXPENSE_LIMIT_PER_EVENT_ATTENDEE_FIELDS = new List<String>{'Attendee_Account_Type_vod__c','Expense_Type_vod__c','Expense_Category_vod__c','Event_Status_vod__c','Warning_Type_vod__c'};
    private static final List<String> EXPENSE_LIMIT_ATTENDEE_CAP_FIELDS = new List<String>{'Attendee_Account_Type_vod__c','Expense_Type_vod__c','Date_Threshold_Type_vod__c','Warning_Type_vod__c'};
    private static final List<String> EXPENSE_LIMIT_ACTUAL_VS_ESTIMATE_FIELDS = new List<String>{'Expense_Type_vod__c','Warning_Type_vod__c'};
    private static final List<String> SPEAKER_LIMIT_FIELDS = new List<String>{'Per_Event_Topic_vod__c','Date_Threshold_Type_vod__c','Warning_Type_vod__c'};
    private static final List<String> SPEAKER_EXPENSE_CAP_FIELDS = new List<String>{'Warning_Type_vod__c'};
    private static final List<String> SPEAKER_RATIO_FIELDS = new List<String>{'Attendee_Account_Type_vod__c','Speaker_Status_vod__c','Warning_Type_vod__c'};
    private static final List<String> SPEAKER_LIMIT_PER_EVENT_FIELDS = new List<String>{'Speaker_Status_vod__c','Warning_Type_vod__c'};
    private static final List<String> REQUIRED_MATERIAL_FIELDS = new List<String>{'EM_Event_Material_vod__c','Warning_Type_vod__c'};

    private static final List<String> ATTENDEE_ATTENDANCE_EXCLUDE_MULTI_VALUE_FIELDS = new List<String>{'Run_Rule_Event_Action_vod__c','Per_Event_Topic_vod__c','Date_Threshold_Type_vod__c','Warning_Type_vod__c'};
    private static final List<String> EXCLUDE_MULTI_VALUE_FIELDS = new List<String>{'Run_Rule_Event_Action_vod__c','Warning_Type_vod__c'};
    private static final List<String> ATTENDEE_MEAL_EXCLUDE_MULTI_VALUE_FIELDS = ATTENDEE_ATTENDANCE_EXCLUDE_MULTI_VALUE_FIELDS;
    private static final List<String> EXPENSE_LIMIT_PER_EVENT_EXCLUDE_MULTI_VALUE_FIELDS = new List<String>{'Run_Rule_Event_Action_vod__c','Expense_Type_vod__c','Expense_Category_vod__c','Warning_Type_vod__c'};
    private static final List<String> EXPENSE_LIMIT_ATTENDEE_CAP_EXCLUDE_MULTI_VALUE_FIELDS = new List<String>{'Run_Rule_Event_Action_vod__c','Expense_Type_vod__c','Date_Threshold_Type_vod__c','Warning_Type_vod__c'};

    private static final Set<String> BUS_RULE_ATTENDEE_RECORD_TYPES = new Set<String>{RT_ATTENDEE_ATTENDANCE, RT_ATTENDEE_CROSS_EVENT_ATTENDANCE, RT_ATTENDEE_MEAL, RT_ATTENDEE_CROSS_EVENT_MEAL, RT_ATTENDEE_EVENT};
    private static final Set<String> BUS_RULE_ATTENDEE_STATUS_RECORD_TYPES = new Set<String>{RT_ATTENDEE_ATTENDANCE, RT_ATTENDEE_CROSS_EVENT_ATTENDANCE, RT_ATTENDEE_MEAL, RT_ATTENDEE_CROSS_EVENT_MEAL, 
        RT_ATTENDEE_EVENT, RT_EXPENSE_LIMIT_ATTENDEE_CAP, RT_EXPENSE_LIMIT_CROSS_EVENT_ATTENDEE_CAP, RT_SPEAKER_RATIO_PER_EVENT};
    // Used for duplicate logic for record types have fields with mutiple values and the fields are part of the business rule ID.
    private static final Set<String> BUS_RULE_MULTI_VALUE_RECORD_TYPES = new Set<String>{RT_ATTENDEE_ATTENDANCE, RT_ATTENDEE_CROSS_EVENT_ATTENDANCE, RT_ATTENDEE_MEAL, RT_ATTENDEE_CROSS_EVENT_MEAL, 
        RT_ATTENDEE_EVENT, RT_EXPENSE_LIMIT_PER_EVENT, RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE, RT_EXPENSE_LIMIT_ATTENDEE_CAP, 
        RT_EXPENSE_LIMIT_CROSS_EVENT_ATTENDEE_CAP, RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER, RT_SPEAKER_RATIO_PER_EVENT, RT_SPEAKER_LIMIT_PER_EVENT};
    private static final Set<String> BUS_RULE_EXPENSE_ESTIMATE_RECORD_TYPES = new Set<String>{RT_EE_MEAL, RT_EE_SPEAKER_TRAVEL, RT_EE_SPEAKER_LODGING, RT_EE_AV_EQUIPMENT, RT_EE_FLAT_FEE};
    private static final Set<String> BUS_RULE_EXPENSE_TYPE_RECORD_TYPES = new Set<String>{RT_EXPENSE_LIMIT_PER_EVENT, RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE, RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER};
    private static final Set<String> BUS_RULE_SPEAKER_STATUS_RECORD_TYPES = new Set<String>{PT_SPEAKER_ENGAGEMENT_LIMIT, RT_SPEAKER_CROSS_EVENT_ENGAGEMENT_LIMIT, RT_SPEAKER_RATIO_PER_EVENT, RT_SPEAKER_LIMIT_PER_EVENT};

    private static final Map<String, List<String>> UNIQUE_FIELD_MAP = new Map<String, List<String>> {
        RT_EE_MEAL => EE_MEAL_FIELDS,
        RT_EE_SPEAKER_TRAVEL => EE_SPEAKER_TRAVEL_FIELDS,
        RT_EE_SPEAKER_LODGING => EE_SPEAKER_LODGING_FIELDS,
        RT_EE_AV_EQUIPMENT => EE_AV_EQUIPMENT_FIELDS,
        RT_EE_FLAT_FEE => EE_FLAT_FEE_FIELDS,
        RT_ATTENDEE_ATTENDANCE => ATTENDEE_ATTENDANCE_FIELDS,
        RT_ATTENDEE_CROSS_EVENT_ATTENDANCE => ATTENDEE_ATTENDANCE_FIELDS,
        RT_ATTENDEE_MEAL => ATTENDEE_MEAL_FIELDS,
        RT_ATTENDEE_CROSS_EVENT_MEAL => ATTENDEE_MEAL_FIELDS,
        RT_ATTENDEE_EVENT => ATTENDEE_EVENT_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT => EXPENSE_LIMIT_PER_EVENT_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE => EXPENSE_LIMIT_PER_EVENT_ATTENDEE_FIELDS,
        RT_EXPENSE_LIMIT_ATTENDEE_CAP => EXPENSE_LIMIT_ATTENDEE_CAP_FIELDS,
        RT_EXPENSE_LIMIT_CROSS_EVENT_ATTENDEE_CAP => EXPENSE_LIMIT_ATTENDEE_CAP_FIELDS,
        RT_EXPENSE_LIMIT_ACTUAL_VS_ESTIMATE_THRESHOLD => EXPENSE_LIMIT_ACTUAL_VS_ESTIMATE_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER => EXPENSE_LIMIT_PER_EVENT_FIELDS,
        PT_SPEAKER_ENGAGEMENT_LIMIT => SPEAKER_LIMIT_FIELDS,
        RT_SPEAKER_CROSS_EVENT_ENGAGEMENT_LIMIT => SPEAKER_LIMIT_FIELDS,
        RT_SPEAKER_ATTENDANCE_EXPENSE_CAP => SPEAKER_EXPENSE_CAP_FIELDS,
        RT_SPEAKER_RATIO_PER_EVENT => SPEAKER_RATIO_FIELDS,
        RT_SPEAKER_LIMIT_PER_EVENT => SPEAKER_LIMIT_PER_EVENT_FIELDS,
        RT_SPEAKER_ATTENDEE_QUALIFICATION => SPEAKER_EXPENSE_CAP_FIELDS,
        RT_REQUIRED_MATERIAL => REQUIRED_MATERIAL_FIELDS
    };

    private static final Map<String, List<String>> UNMODIFIED_FIELD_MAP = new Map<String, List<String>> {
        RT_EE_MEAL => EE_MEAL_FIELDS,
        RT_EE_SPEAKER_TRAVEL => EE_SPEAKER_TRAVEL_FIELDS,
        RT_EE_SPEAKER_LODGING => EE_SPEAKER_LODGING_FIELDS,
        RT_EE_AV_EQUIPMENT => EE_AV_EQUIPMENT_FIELDS,
        RT_EE_FLAT_FEE => EE_FLAT_FEE_FIELDS,
        RT_ATTENDEE_ATTENDANCE => UNMODIFIED_RULE_FIELDS,
        RT_ATTENDEE_CROSS_EVENT_ATTENDANCE => UNMODIFIED_RULE_FIELDS,
        RT_ATTENDEE_MEAL => UNMODIFIED_RULE_FIELDS,
        RT_ATTENDEE_CROSS_EVENT_MEAL => UNMODIFIED_RULE_FIELDS,
        RT_ATTENDEE_EVENT => UNMODIFIED_RULE_FIELDS,
        RT_EXPENSE_LIMIT_ACTUAL_VS_ESTIMATE_THRESHOLD => UNMODIFIED_RULE_FIELDS,
        PT_SPEAKER_ENGAGEMENT_LIMIT => UNMODIFIED_RULE_FIELDS,
        RT_SPEAKER_CROSS_EVENT_ENGAGEMENT_LIMIT => UNMODIFIED_RULE_FIELDS,
        RT_SPEAKER_ATTENDANCE_EXPENSE_CAP => UNMODIFIED_RULE_FIELDS,
        RT_SPEAKER_RATIO_PER_EVENT => UNMODIFIED_RULE_FIELDS,
        RT_SPEAKER_LIMIT_PER_EVENT => UNMODIFIED_RULE_FIELDS,
        RT_SPEAKER_ATTENDEE_QUALIFICATION => UNMODIFIED_RULE_FIELDS,
        RT_REQUIRED_MATERIAL => UNMODIFIED_MATERIAL_RULE_FIELDS
    };

    private static final Map<String, List<String>> EXCLUDE_MULTI_VALUE_FIELD_MAP = new Map<String, List<String>> {
        RT_ATTENDEE_ATTENDANCE => ATTENDEE_ATTENDANCE_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_ATTENDEE_CROSS_EVENT_ATTENDANCE => ATTENDEE_ATTENDANCE_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_ATTENDEE_MEAL => ATTENDEE_MEAL_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_ATTENDEE_CROSS_EVENT_MEAL => ATTENDEE_MEAL_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_ATTENDEE_EVENT => EXCLUDE_MULTI_VALUE_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT => EXPENSE_LIMIT_PER_EVENT_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE => EXPENSE_LIMIT_PER_EVENT_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_EXPENSE_LIMIT_ATTENDEE_CAP => EXPENSE_LIMIT_ATTENDEE_CAP_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_EXPENSE_LIMIT_CROSS_EVENT_ATTENDEE_CAP => EXPENSE_LIMIT_ATTENDEE_CAP_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER => EXPENSE_LIMIT_PER_EVENT_EXCLUDE_MULTI_VALUE_FIELDS,
        RT_SPEAKER_RATIO_PER_EVENT => EXCLUDE_MULTI_VALUE_FIELDS,
        RT_SPEAKER_LIMIT_PER_EVENT => EXCLUDE_MULTI_VALUE_FIELDS
    };

    private List<String> buttonNames;

    private List<EM_Business_Rule_vod__c> newBusinessRules = new List<EM_Business_Rule_vod__c>();
    private List<EM_Business_Rule_vod__c> oldBusinessRules = new List<EM_Business_Rule_vod__c>();
    private Map<ID, EM_Business_Rule_vod__c> newBusinessRulesMap = new Map<ID, EM_Business_Rule_vod__c>();
    private Map<ID, EM_Business_Rule_vod__c> oldBusinessRulesMap = new Map<ID, EM_Business_Rule_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newBusinessRules = (List<EM_Business_Rule_vod__c>) triggerNew;
        this.oldBusinessRules = (List<EM_Business_Rule_vod__c>) triggerOld;
        this.newBusinessRulesMap = (Map<ID, EM_Business_Rule_vod__c>) triggerNewMap;
        this.oldBusinessRulesMap = (Map<ID, EM_Business_Rule_vod__c>) triggerOldMap;
    }
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'EM_Business_Rule_vod__c';
    }

    protected override void beforeInsert() {
        vodEmBusinessRuleBeforeInsertUpdate();
    }
    
    protected override void beforeUpdate() {
        vodEmBusinessRuleBeforeInsertUpdate();
    }

    private void vodEmBusinessRuleBeforeInsertUpdate() {
        Set<String> recordTypeIds = new Set<String>();
        Set<Id> expenseTypeIds = new Set<Id>();
        for (EM_Business_Rule_vod__c rule: newBusinessRules) {
            rule.EM_Business_Rule_Id_vod__c = getBusinessRuleId(rule);
            recordTypeIds.add(rule.RecordTypeId);
            if (rule.Expense_Type_vod__c != null) {
                expenseTypeIds.add(rule.Expense_Type_vod__c);
            }
        }

        Map<String, List<EM_Business_Rule_vod__c>> businessRuleMap = new Map<String, List<EM_Business_Rule_vod__c>>();
        List<EM_Business_Rule_vod__c> rules = [SELECT Id, Name, RecordTypeId, EM_Business_Rule_Id_vod__c,
            Run_Rule_Event_Action_vod__c, Meal_Type_vod__c, Speaker_Transportation_Method_vod__c,
            Speaker_Lodging_Type_vod__c, AV_Equipment_vod__c, Flat_Fee_Expense_vod__c,
            Global_Rule_vod__c, Attendee_Account_Type_vod__c, Per_Event_Topic_vod__c, Warning_Type_vod__c,
            Expense_Type_vod__c, Expense_Category_vod__c, Event_Status_vod__c, Speaker_Status_vod__c, 
            Date_Threshold_Type_vod__c, EM_Event_Material_vod__c
            FROM EM_Business_Rule_vod__c WHERE RecordTypeId IN :recordTypeIds];
        
        for (EM_Business_Rule_vod__c rule : rules) {
            String recordTypeId = rule.RecordTypeId;
            List<EM_Business_Rule_vod__c> recordTypeRules = businessRuleMap.get(recordTypeId);
            if (recordTypeRules == null) {
                recordTypeRules = new List<EM_Business_Rule_vod__c>();
                businessRuleMap.put(recordTypeId, recordTypeRules);
            }
            recordTypeRules.add(rule);
        }

        Map<Id, Expense_Type_vod__c> expenseTypes;
        if (!expenseTypeIds.isEmpty()) {
            expenseTypes = new Map<Id, Expense_Type_vod__c>([SELECT Id, Parent_Expense_Type_vod__c FROM Expense_Type_vod__c WHERE Active_vod__c = true AND Id IN :expenseTypeIds]);
        }

        for (EM_Business_Rule_vod__c rule: newBusinessRules){
            String recordTypeId = rule.RecordTypeId;
            String developerName = getDeveloperName(RULE_RECORD_TYPE_MAP, recordTypeId);
            if (!validateField(developerName, rule, oldBusinessRulesMap, expenseTypes)) {
                continue;
            }
            List<EM_Business_Rule_vod__c> existingRules = businessRuleMap.get(recordTypeId);
            if (existingRules != null && !existingRules.isEmpty()){
                checkDuplicate(developerName, rule, existingRules);
            } else {
                existingRules = new List<EM_Business_Rule_vod__c>();
                businessRuleMap.put(recordTypeId, existingRules);
            }
            // Add new business rule to existing rules to check duplicate within new objects as well. 
            existingRules.add(rule);
        }
    }

    private String getDeveloperName(Map<Id, Schema.RecordTypeInfo> recordTypeMap, String recordTypeId) {
        String developerName = '';
        Schema.RecordTypeInfo recordTypeInfo = recordTypeMap.get(recordTypeId);
        if (recordTypeInfo != null) {
            developerName = recordTypeInfo.getDeveloperName();
        }
        return developerName;
    }

    @TestVisible private String getBusinessRuleId(EM_Business_Rule_vod__c rule) {
        String developerName = getDeveloperName(RULE_RECORD_TYPE_MAP, rule.RecordTypeId);
        String ruleId = developerName + FIELD_SEPARATOR + rule.Run_Rule_Event_Action_vod__c;
        List<String> ruleFields = UNIQUE_FIELD_MAP.get(developerName);
        if (ruleFields != null && ruleFields.size() > 0) {
            for (String fieldName : ruleFields) {
                DescribeFieldResult field = RULE_FIELD_MAP.get(fieldName).getDescribe();
                Schema.DisplayType fieldType = field.getType();
                if (fieldType == Schema.DisplayType.STRING 
                    || fieldType == Schema.DisplayType.PICKLIST
                    || fieldType == Schema.DisplayType.TEXTAREA) {
                    String fieldValue = (String)rule.get(fieldName);    
                    if (String.isNotBlank(fieldValue) && fieldValue.contains(';;')) {
                        ruleId = ruleId + FIELD_SEPARATOR + fieldValue.replace(';;', ',');
                    } else {
                        ruleId = ruleId + FIELD_SEPARATOR + fieldValue;
                    }
                } else {
                    ruleId = ruleId + FIELD_SEPARATOR + rule.get(fieldName);
                }
            }
        }
        return ruleId;
    }

    @TestVisible private void checkDuplicate(String developerName, EM_Business_Rule_vod__c rule, List<EM_Business_Rule_vod__c> existingRules) {
        for (EM_Business_Rule_vod__c existingRule : existingRules) {
            if (isUniqueFieldMatch(developerName, rule, existingRule)) {
                rule.addError(String.format(DUPLICATE_MESSAGE, new string[]{String.Valueof(existingRule.Name)}));
                return;
            }
        }
    }

    private boolean isUniqueFieldMatch (String developerName, EM_Business_Rule_vod__c rule, EM_Business_Rule_vod__c existingRule) {
        // Existing rule Id is null when it comes from new business rule.
        return ((rule.Id == null || existingRule.Id == null || rule.Id <> existingRule.Id)
            && (rule.EM_Business_Rule_Id_vod__c == getBusinessRuleId(existingRule)
                || isMultiValueFieldOverlap(developerName, rule, existingRule)));
    }

    private boolean isAttendeeRule(String developerName) {
        return BUS_RULE_ATTENDEE_RECORD_TYPES.contains(developerName);
    }

    private boolean isAttendeeAccountTypeRule(String developerName) {
        return isAttendeeRule(developerName) || 
            RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE == developerName || 
            RT_EXPENSE_LIMIT_ATTENDEE_CAP == developerName || 
            RT_EXPENSE_LIMIT_CROSS_EVENT_ATTENDEE_CAP == developerName ||
            RT_SPEAKER_RATIO_PER_EVENT == developerName;
    }

    private boolean isExpenseEstimateRule(String developerName) {
        return BUS_RULE_EXPENSE_ESTIMATE_RECORD_TYPES.contains(developerName);
    }

    private boolean isExpenseTypeRule(String developerName) {
        return isExpenseEstimateRule(developerName) || BUS_RULE_EXPENSE_TYPE_RECORD_TYPES.contains(developerName);
    }

    private boolean isEventStatusRule(String developerName) {
        return RT_EXPENSE_LIMIT_PER_EVENT == developerName || 
            RT_EXPENSE_LIMIT_PER_EVENT_ATTENDEE == developerName || 
            RT_EXPENSE_LIMIT_PER_EVENT_SPEAKER == developerName;
    }

    private boolean isSpeakerStatusRule(String developerName) {
        return RT_SPEAKER_RATIO_PER_EVENT == developerName || RT_SPEAKER_LIMIT_PER_EVENT == developerName;
    }

    private String getConcatField(String developerName, EM_Business_Rule_vod__c rule) {
        List<String> concatFields = EXCLUDE_MULTI_VALUE_FIELD_MAP.get(developerName);
        String val = '';
        if (concatFields != null && concatFields.size() > 0) {
            for (String fieldName : concatFields) {
                val = val + '_' + rule.get(fieldName);
            }
        }
        return val;
    }

    private boolean isValueOverlap(String newValue, String existingValue) {
        if (String.isBlank(newValue) && String.isBlank(existingValue)) {
            return true;
        }
        if (String.isNotBlank(newValue) && String.isNotBlank(existingValue)) {
            List<String> types = getSplitValues(newValue, ';;');
            List<String> existingTypes = getSplitValues(existingValue, ';;');
            for (String type : types) {
                if (String.isNotBlank(type) && existingTypes.contains(type)) {
                    return true;
                }
            }
        }
        return false;
    }

    @TestVisible private boolean isMultiValueFieldOverlap(String developerName, EM_Business_Rule_vod__c rule, EM_Business_Rule_vod__c existingRule) {
        if (!BUS_RULE_MULTI_VALUE_RECORD_TYPES.contains(developerName) || getConcatField(developerName, rule) != getConcatField(developerName, existingRule)) {
            return false;
        }
        boolean acctTypeOverlap = false;
        boolean eventStatusOverlap = false;
        boolean speakerStatusOverlap = false;
        boolean checkAcctType = isAttendeeAccountTypeRule(developerName);
        boolean checkEventStatus = isEventStatusRule(developerName);
        boolean checkSpeakerStatus = isSpeakerStatusRule(developerName);
        
        acctTypeOverlap = checkAcctType ? isValueOverlap(rule.Attendee_Account_Type_vod__c, existingRule.Attendee_Account_Type_vod__c) : true;        
        eventStatusOverlap = checkEventStatus ? isValueOverlap(rule.Event_Status_vod__c, existingRule.Event_Status_vod__c) : true;
        speakerStatusOverlap = checkSpeakerStatus ? isValueOverlap(rule.Speaker_Status_vod__c, existingRule.Speaker_Status_vod__c) : true;
        // Check on all fields when rule has several multi value fields.
        return acctTypeOverlap && eventStatusOverlap && speakerStatusOverlap;
    }

    @TestVisible private boolean validateField(String developerName, EM_Business_Rule_vod__c rule, Map<Id, EM_Business_Rule_vod__c> oldRuleMap, Map<Id, Expense_Type_vod__c> expenseTypes) {
        boolean flag = true;
        if (!validateButtonName('EM_Event_vod__c', rule)) {
            return false;
        }
        if (String.isNotBlank(rule.Id) && oldRuleMap != null && oldRuleMap.get(rule.Id) != null) {
            List<String> fields = new List<String>();
            List<String> ruleFields = UNMODIFIED_FIELD_MAP.get(developerName);
            if (ruleFields != null && ruleFields.size() > 0) {
                fields.addAll(ruleFields);
            }
            flag = validateNotEditableField(fields, rule, oldRuleMap.get(rule.Id));
        }
        if (flag) {
            flag = validateAttendeeStatus(developerName, rule);
        }
        if (flag) {
            flag = validateExpenseType(developerName, rule, expenseTypes);
        }
        if (flag) {
            flag = validateEventStatus(developerName, rule);
        }
        if (flag) {
            flag = validateSpeakerStatus(developerName, rule);
        }
        return flag;
    }

    private String getInvalidDataMessage(String fieldName) {
        return String.format(INVALID_DATA_MESSAGE, new string[]{RULE_FIELD_MAP.get(fieldName).getDescribe().getLabel()});
    }
    
    @TestVisible private boolean validateButtonName(String objectName, EM_Business_Rule_vod__c rule) {
        List<String> objectButtonNames = initializeButtonList(objectName);
        String buttonName = rule.Run_Rule_Event_Action_vod__c;
        if (buttonName != null && !objectButtonNames.contains(buttonName)) {
            rule.Run_Rule_Event_Action_vod__c.addError(getInvalidDataMessage('Run_Rule_Event_Action_vod__c'));
            return false;
        }
        return true;
    }

    private List<String> initializeButtonList(String objectName) {
        if (this.buttonNames == null) {
            this.buttonNames = new List<String>();
            Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Metadata_Definition_vod__c.getRecordTypeInfosByDeveloperName();
            Schema.RecordTypeInfo recordTypeInfo = recordTypeMap.get('Weblink_vod');
            if (recordTypeInfo != null && recordTypeInfo.isActive()) {
                List<Metadata_Definition_vod__c> metadataButtons = [SELECT Object_Name_vod__c 
                    FROM Metadata_Definition_vod__c WHERE RecordTypeId = :recordTypeInfo.getRecordTypeId() ORDER BY Object_Name_vod__c];
                for (Metadata_Definition_vod__c button : metadataButtons) {
                    String[] split = button.Object_Name_vod__c.split('\\.');
                    if (split.size() == 2) {
                        if (objectName.equals(split[0])) {
                            this.buttonNames.add(split[1]);
                        }
                    }
                }
            }
        }
        return this.buttonNames;
    }
    
    private boolean validateNotEditableField(List<String> fields, EM_Business_Rule_vod__c rule, EM_Business_Rule_vod__c oldRule) {
        for (String fieldName : fields) {
            if (oldRule != null && oldRule.get(fieldName) != rule.get(fieldName)) {
                rule.addError(String.format(DISABLE_EDIT_MESSAGE, new string[]{RULE_FIELD_MAP.get(fieldName).getDescribe().getLabel()}));
                return false;
            }
        }
        return true; 
    }

    @TestVisible private boolean validateAttendeeStatus(String developerName, EM_Business_Rule_vod__c rule) {
        boolean eventStatusFlag = false;
        boolean attendeeStatusFlag = false;
        boolean ret = true;
        if (!BUS_RULE_ATTENDEE_STATUS_RECORD_TYPES.contains(developerName)) {
            return true;
        }
        String attendeeStatus = rule.Attendee_Status_vod__c;
        if (String.isBlank(attendeeStatus)) {
            if (isAttendeeRule(developerName)) { // Attendee rule blank attendee status error message is handled by validation rule.
                return false;
            } else { // Expense limit rule, speaker rule allows blank attendee status.
                return true;
            }
        }
        List<String> eventStatusList = new List<String>();
        List<String> attendeeStatusList = new List<String>();
        addStatusList(attendeeStatus, eventStatusList, attendeeStatusList);
        // Event status can be blank.
        eventStatusFlag = (eventStatusList.size() == 0) ? true : validatePickListValue(EVENT_STATUS_PICKLIST_VALUES, eventStatusList);
        attendeeStatusFlag = validatePickListValue(ATTENDEE_STATUS_PICKLIST_VALUES, attendeeStatusList);
        if (!eventStatusFlag || !attendeeStatusFlag) {
            rule.Attendee_Status_vod__c.addError(getInvalidDataMessage('Attendee_Status_vod__c'));
            ret = false;
        }
        return ret;
    }

    private void addStatusList(String status,  List<String> eventStatusList, List<String> objectStatusList) {
        List<String> statusPair = getSplitValues(status, ';;');
        for (String pair : statusPair) {
            if (String.isNotBlank(pair)) {
                String[] statusArray = getSplitValues(pair, ':');
                if (statusArray.size() == 1) {
                    objectStatusList.addAll(getSplitValues(statusArray[0], ','));
                } else if (statusArray.size() == 2) {
                    eventStatusList.add(statusArray[0]);
                    objectStatusList.addAll(getSplitValues(statusArray[1], ','));
                }
            }
        }
    }

    @TestVisible private boolean validateSpeakerStatus(String developerName, EM_Business_Rule_vod__c rule) {
        boolean eventStatusFlag = false;
        boolean speakerStatusFlag = false;
        boolean ret = true;
        if (!BUS_RULE_SPEAKER_STATUS_RECORD_TYPES.contains(developerName)) {
            return true;
        }
        String speakerStatus = rule.Speaker_Status_vod__c;
        if (String.isBlank(speakerStatus)) { // Speaker rule blank speaker status error message is handled by validation rule.
            return false;
        }
        List<String> eventStatusList = new List<String>();
        List<String> speakerStatusList = new List<String>();
        addStatusList(speakerStatus, eventStatusList, speakerStatusList);
        // Event status can be blank.
        eventStatusFlag = (eventStatusList.size() == 0) ? true : validatePickListValue(EVENT_STATUS_PICKLIST_VALUES, eventStatusList);
        speakerStatusFlag = validatePickListValue(SPEAKER_STATUS_PICKLIST_VALUES, speakerStatusList);
        if (!eventStatusFlag || !speakerStatusFlag) {
            rule.Speaker_Status_vod__c.addError(getInvalidDataMessage('Speaker_Status_vod__c'));
            ret = false;
        }
        return ret;
    }

    @TestVisible private boolean validateExpenseType(String developerName, EM_Business_Rule_vod__c rule, Map<Id, Expense_Type_vod__c> expenseTypes) {
        if (!isExpenseTypeRule(developerName)) {
            return true;
        }
        String expenseTypeId = rule.Expense_Type_vod__c;
        boolean expenseEstimateRule = isExpenseEstimateRule(developerName);
        if (String.isBlank(expenseTypeId)) {
            if (expenseEstimateRule) { // Expense estimate rule blank expense type error message is handled by validation rule.
                return false;
            } else { // Expense limit rule allows blank expense type.
                return true;
            }
        }
        Expense_Type_vod__c expenseType = (expenseTypes != null) ? expenseTypes.get(expenseTypeId) : null;
        if (expenseType == null) {
            rule.Expense_Type_vod__c.addError(getInvalidDataMessage('Expense_Type_vod__c'));
            return false;
        }
        String parentExpenseType = expenseType.Parent_Expense_Type_vod__c;
        if (expenseEstimateRule && String.isNotBlank(parentExpenseType)) {
            rule.Expense_Type_vod__c.addError(EXPENSE_ESTIMATE_EXPENSE_TYPE_MESSAGE);
            return false;
        }
        if (!expenseEstimateRule && rule.Expense_Category_vod__c == 'Estimate_vod' && String.isNotBlank(parentExpenseType)) {
            rule.Expense_Type_vod__c.addError(EXPENSE_LIMIT_EXPENSE_TYPE_MESSAGE);
            return false;
        }
        return true;
    }

    private boolean validateEventStatus(String developerName, EM_Business_Rule_vod__c rule) {
        if (!isEventStatusRule(developerName)) {
            return true;
        }
        String eventStatus = rule.Event_Status_vod__c;
        if (String.isBlank(eventStatus)) {
            return true;
        }
        List<String> eventStatusList = getSplitValues(eventStatus, ';;');
        boolean eventStatusFlag = (eventStatusList.size() == 0) ? true : validatePickListValue(EVENT_STATUS_PICKLIST_VALUES, eventStatusList);
        if (!eventStatusFlag) {
            rule.Event_Status_vod__c.addError(getInvalidDataMessage('Event_Status_vod__c'));
        }
        return eventStatusFlag;
    }

    private List<String> getSplitValues(String inputValue, String separator) {
        List<String> values = new List<String>();
        if (String.isNotBlank(inputValue)) {
            values = inputValue.split(separator);
        }
        return values;
    }

    private boolean validatePickListValue(List<Schema.PicklistEntry> picklistValues, List<String> values) {
        if (picklistValues.isEmpty() || values.isEmpty()) {
            return false;
        }
        List<String> validValues = new List<String>();
        for (Schema.PicklistEntry pv : picklistValues) {
            validValues.add(pv.getValue());
        }
        for (String val : values) {
            if (String.isNotBlank(val) && !validValues.contains(val)) {
                return false;
            }
        }
        return true;
    }
    
}