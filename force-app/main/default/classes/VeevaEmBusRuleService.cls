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
 * VeevaEmBusRuleService provides common properties and functions for event business rules .
 */
public abstract class VeevaEmBusRuleService {
    private static Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
    public static final String HARD_WARNING = 'Hard_Warning_vod';
    public static final String SOFT_WARNING = 'Soft_Warning_vod';

    protected RestResponse res = RestContext.response;

    protected void validateRequest(String eventId, Set<String> ruleIds) {
        if (String.isEmpty(eventId)) {
            throw new VeevaEmBusRuleModel.BadDataException('Event Id in request is not valid');
        }
        if (ruleIds.isEmpty()) {
            throw new VeevaEmBusRuleModel.BadDataException('Rule Id list is empty in request');
        }
        if (ruleIds.size() > VeevaEmBusRuleUtils.RULE_COUNT_LIMIT) {
            throw new VeevaEmBusRuleModel.BadDataException('Running more than ' + VeevaEmBusRuleUtils.RULE_COUNT_LIMIT + ' rules is not supported');
        }
    }

    protected EM_Event_History_vod__c createEventHistoryObject(String recordTypeId, String eventId, String configId, String eventAction, String platform, VeevaEmBusRuleModel.BusinessRule rule) {
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

    protected String executeEventHistoryBatch(List<EM_Event_History_vod__c> sObjects) {
        String batchId = '';
        if (!sObjects.isEmpty()) {
            VeevaEmBusRuleBatch ruleBatch = new VeevaEmBusRuleBatch(sObjects);
            batchId = Database.executeBatch(ruleBatch);
        }
        return batchId;
    }

    protected Schema.DescribeSObjectResult getDescribeResult(String objectName)
    {
        Schema.DescribeSObjectResult toReturn = null;
        Schema.SObjectType objectType = GLOBAL_DESCRIBE.get(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult describe = objectType.getDescribe();
            if (describe.isAccessible()) {
                toReturn = describe;
            }
        }
        return toReturn;
    }

    protected void addWarningTypeRules(VeevaEmBusRuleModel.BusinessRule businessRule, Map<String, List<String>> warningTypeRules) {
        String warningType = businessRule.warningType;
        List<String> violatedRuleIds = warningTypeRules.get(warningType);
        if (violatedRuleIds == null) {
            violatedRuleIds = new List<String>();
            warningTypeRules.put(warningType, violatedRuleIds);
        }
        violatedRuleIds.add(businessRule.id);
    }
}