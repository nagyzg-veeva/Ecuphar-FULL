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
 * VeevaEmBusRuleMaterialService checks required event material rule violation by event materials and business rules.
 */
global without sharing class VeevaEmBusRuleMaterialService extends VeevaEmBusRuleService {
    private static Map<Id, Schema.RecordTypeInfo> EVENT_RECORD_TYPE_MAP = Schema.SObjectType.EM_Event_vod__c.getRecordTypeInfosById();
    private static final String NO_ATTACHMENT = 'No_vod';

    private List<VeevaEmBusRuleModel.BusinessRule> businessRules;
    private MaterialDetail materialDetail;
    private MaterialResult materialResult;
    private String eventMaterialRecordTypeId = '';
    private String eventMaterialPermission;
    private Map<String, List<String>> materialWarningTypeRules = new Map<String, List<String>>();

    public MaterialResult processMaterialRules(MaterialRequest request) {
        materialResult = new MaterialResult();
        try {
            String eventId = request.eventId;
            Set<String> ruleIds = request.ruleIds;
            validateRequest(eventId, ruleIds);
            initMaterialDetail(eventId, request.eventAction, request.platform);
            businessRules = VeevaEmBusRuleModel.getBusinessRules(ruleIds, materialDetail.eventType, 
                materialDetail.country, materialDetail.startTime);
            if (businessRules.isEmpty()) {
                throw new VeevaEmBusRuleModel.BadDataException('Rule Id in request is not valid');
            }
            findRuleViolations();
            setResponse(materialResult, res, true, '', 200);
        } catch (VeevaEmBusRuleModel.BadDataException be) {
            setResponse(materialResult, res, false, be.getMessage(), 400);
        } catch (Exception e) {
            setResponse(materialResult, res, false, e.getMessage(), 500);
        }
        return materialResult;
    }

    public class MaterialRequest {
        public String eventId;
        public Set<String> ruleIds;
        public String eventAction;
        private String platform;
    }

    global class MaterialResult {
        public boolean success;
        public String errorMessage;
        public String eventHistoryBatchId;
        // Key rule Id
        public Map<String, MaterialViolation> ruleViolations;
        // Existing event material Ids created by required event material rules
        private List<String> eventMaterialIds;
        // Violated material Ids used for user permission error checking, not include new material Ids created in the process
        private List<String> violatedEventMaterialIds;
    }

    public class MaterialDetail {
        private String eventId;
        private String eventAction;
        private String platform;
        private String eventType;
        private String country;
        private Datetime startTime;
        // Key by combination of event action, material name and attachment requirement
        private Map<String, MaterialField> materialFields;
        private List<EM_Event_Material_vod__c> missingEventMaterials;
        private Map<String, VeevaEmBusRuleModel.BusinessRule> missingEventMaterialRules;
        private List<String> eventMaterialIds;
        private Map<String, String> violatedRuleEventMaterialIds;

        private MaterialDetail(String eventId, String eventAction, String platform) {
            this.eventId = eventId;
            this.eventAction = eventAction;
            this.platform = platform;
        }
    }

    private class MaterialField {
        private String eventMaterialId;
        private String name;
        private String requiredEventAction;
        private String attachmentRequirement;
        private String hasAttachment;

        private String getKey() {
            return requiredEventAction + name + attachmentRequirement;
        }
    }

    private class MaterialViolation {
        private String eventMaterialId;
        private String name;

        private MaterialViolation(String eventMaterialId, String name) {
            this.eventMaterialId = eventMaterialId;
            this.name = name;
        }
    }

    private void initMaterialDetail(String eventId, String eventAction, String platform) {
        materialDetail = new MaterialDetail(eventId, eventAction, platform);
        RecordTypeInfo recordType = Schema.SObjectType.EM_Event_Material_vod__c.getRecordTypeInfosByDeveloperName().get('Required_Attachment_vod');
        if (recordType != null) {
            eventMaterialRecordTypeId = recordType.getRecordTypeId();
        }
        EM_Event_vod__c event = [SELECT RecordTypeId, Country_vod__c, Start_Time_vod__c, 
            (SELECT Id, Name_vod__c, Required_Event_Action_vod__c, Attachment_Requirement_vod__c, Has_Attachment_vod__c FROM Event_Materials__r WHERE RecordTypeId = :eventMaterialRecordTypeId)
            FROM EM_Event_vod__c WHERE Id = :eventId];
        materialDetail.startTime = event.Start_Time_vod__c;
        materialDetail.eventType = VeevaEmBusRuleUtils.getDeveloperName(EVENT_RECORD_TYPE_MAP, event.RecordTypeId);
        materialDetail.country = event.Country_vod__c;
        materialDetail.materialFields = new Map<String, MaterialField>();
        materialDetail.eventMaterialIds = new List<String>();
        List<SObject> eventMaterials = event.getSObjects('Event_Materials__r');
        if (VeevaEmBusRuleUtils.isNotEmpty(eventMaterials)) {
            for (SObject eventMaterial : eventMaterials) {
                String id = (String)eventMaterial.get('Id');
                MaterialField materialField = new MaterialField();
                materialField.eventMaterialId = id;
                materialField.name = (String)eventMaterial.get('Name_vod__c');
                materialField.requiredEventAction = (String)eventMaterial.get('Required_Event_Action_vod__c');
                materialField.attachmentRequirement = (String)eventMaterial.get('Attachment_Requirement_vod__c');
                materialField.hasAttachment = (String)eventMaterial.get('Has_Attachment_vod__c');
                materialDetail.materialFields.put(materialField.getKey(), materialField);
                materialDetail.eventMaterialIds.add(id);
            }
        }
    }

    private void findRuleViolations() {
        Map<String, MaterialViolation> ruleViolations = new Map<String, MaterialViolation>();
        Map<String, VeevaEmBusRuleModel.BusinessRule> violatedRuleMap = new Map<String, VeevaEmBusRuleModel.BusinessRule>();
        materialDetail.missingEventMaterials = new List<EM_Event_Material_vod__c>();
        materialDetail.missingEventMaterialRules = new Map<String, VeevaEmBusRuleModel.BusinessRule>();
        materialDetail.violatedRuleEventMaterialIds = new Map<String, String>();
        for (VeevaEmBusRuleModel.BusinessRule businessRule : businessRules) {
            MaterialViolation violation = getRequiredEventMaterialViolation(businessRule);
            if (violation != null) {
                ruleViolations.put(businessRule.id, violation);
                violatedRuleMap.put(businessRule.id, businessRule);
                addWarningTypeRules(businessRule, materialWarningTypeRules);
                if (!String.isBlank(violation.eventMaterialId)) {
                    materialDetail.violatedRuleEventMaterialIds.put(businessRule.id, violation.eventMaterialId);
                }
            }
        }
        materialResult.ruleViolations = ruleViolations;
        materialResult.eventMaterialIds = materialDetail.eventMaterialIds;
        if (VeevaEmBusRuleUtils.isNotEmpty(materialDetail.missingEventMaterials)) {
            List<Database.Saveresult> results = Database.insert(materialDetail.missingEventMaterials, VeevaEmBusRuleUtils.OPT_ALL_OR_NONE);
            for (Integer i=0; i<results.size(); i++) {
                Database.Saveresult sr = results.get(i);
                if (sr.isSuccess()) {
                    populateViolationId(sr.getId(), materialDetail.missingEventMaterials.get(i));
                }
            }
        }
        if (String.isNotBlank(materialDetail.eventAction) && !violatedRuleMap.isEmpty()) {
            filterSoftWarningRules(materialWarningTypeRules);
            createEventHistory(violatedRuleMap);
        }
        materialResult.violatedEventMaterialIds = materialDetail.violatedRuleEventMaterialIds.values();
    }

    private MaterialViolation getRequiredEventMaterialViolation(VeevaEmBusRuleModel.BusinessRule businessRule) {
        MaterialViolation violation = null;
        MaterialField materialField = materialDetail.materialFields.get(businessRule.getEventMaterialKey());
        if (materialField == null) {
            violation = new MaterialViolation(null, businessRule.eventMaterial);
            materialDetail.missingEventMaterialRules.put(businessRule.getEventMaterialKey(), businessRule);
            // Create missing event materials when user has proper permission
            if (!String.isBlank(eventMaterialRecordTypeId) && checkEventMaterialPermission()) {
                EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c();
                eventMaterial.Event_vod__c = materialDetail.eventId;
                eventMaterial.RecordTypeId = eventMaterialRecordTypeId;
                eventMaterial.Required_Event_Action_vod__c = businessRule.runRuleEventAction;
                eventMaterial.Name_vod__c = businessRule.eventMaterial;
                if (HARD_WARNING.equals(businessRule.warningType)) {
                    eventMaterial.Attachment_Requirement_vod__c = 'Required_vod';
                } else {
                    eventMaterial.Attachment_Requirement_vod__c = 'Optional_vod';
                }
                eventMaterial.Has_Attachment_vod__c = NO_ATTACHMENT;
                materialDetail.missingEventMaterials.add(eventMaterial);
            }
        } else if (NO_ATTACHMENT.equals(materialField.hasAttachment)) {
            violation = new MaterialViolation(materialField.eventMaterialId, materialField.name);
        }
        return violation;
    }

    private void populateViolationId(String eventMaterialId, EM_Event_Material_vod__c material) {
        VeevaEmBusRuleModel.BusinessRule businessRule = materialDetail.missingEventMaterialRules.get(material.Required_Event_Action_vod__c + material.Name_vod__c + material.Attachment_Requirement_vod__c);
        if (businessRule != null) {
            // update violation with event material Id
            materialResult.ruleViolations.put(businessRule.id, new MaterialViolation(eventMaterialId, businessRule.eventMaterial));
        }
    }

    private void createEventHistory(Map<String, VeevaEmBusRuleModel.BusinessRule> ruleMap) {
        List<EM_Event_History_vod__c> sObjects = new List<EM_Event_History_vod__c>();
        RecordTypeInfo recordType = Schema.SObjectType.EM_Event_History_vod__c.getRecordTypeInfosByDeveloperName().get('EM_Business_Rule_History_vod');
        if (recordType == null) {
            return;
        }
        String recordTypeId = recordType.getRecordTypeId();
        Map<String, MaterialViolation> ruleViolations = materialResult.ruleViolations;
        for (String ruleId : ruleViolations.keySet()) {
            VeevaEmBusRuleModel.BusinessRule rule = ruleMap.get(ruleId);
            MaterialViolation violation = ruleViolations.get(ruleId);
            String configId = rule.getConfigurationId(materialDetail.eventType, materialDetail.country);
            EM_Event_History_vod__c history = createEventHistoryObject(recordTypeId, materialDetail.eventId, configId, materialDetail.eventAction, materialDetail.platform, rule);
            history.EM_Event_Material_vod__c = violation.eventMaterialId;
            history.Record_Violated_ID_vod__c = violation.eventMaterialId;
            history.Record_Violated_Name_vod__c = violation.name;
            sObjects.add(history);
        }
        materialResult.eventHistoryBatchId = executeEventHistoryBatch(sObjects);
    }

    public static void setResponse(MaterialResult result, RestResponse response, Boolean success, String errorMessage, Integer statusCode) {
        result.success = success;
        result.errorMessage = errorMessage;
        response.statusCode = statusCode;
    }

    private boolean checkEventMaterialPermission() {
        if (String.isBlank(eventMaterialPermission)) {
            eventMaterialPermission = 'true';
            Schema.DescribeSObjectResult describeObject = getDescribeResult('EM_Event_Material_vod__c');
            if (describeObject == null || !describeObject.isCreateable()) {
                eventMaterialPermission = 'false';
            } else {
                List<String> fieldNames = new List<String>{'Required_Event_Action_vod__c','Name_vod__c','Attachment_Requirement_vod__c','Has_Attachment_vod__c','Event_vod__c'};
                Map<String, Schema.SObjectField> fieldMap = describeObject.fields.getMap();
                for (String fieldName : fieldNames) {
                    Schema.SObjectField field = fieldMap.get(fieldName);
                    if (field == null || !field.getDescribe().isCreateable()) {
                        eventMaterialPermission = 'false';
                        break;
                    }  
                }
            }
        }
        return Boolean.valueOf(eventMaterialPermission);
    }

    private void filterSoftWarningRules(Map<String, List<String>> warningTypeRules) {
        if (!warningTypeRules.isEmpty()) {
            List<String> hardWarningRules = warningTypeRules.get(HARD_WARNING);
            List<String> softWarningRules = warningTypeRules.get(SOFT_WARNING);
            if (VeevaEmBusRuleUtils.isNotEmpty(hardWarningRules) && VeevaEmBusRuleUtils.isNotEmpty(softWarningRules)) {
                for (String ruleId : softWarningRules) {
                    materialResult.ruleViolations.remove(ruleId);
                    materialDetail.violatedRuleEventMaterialIds.remove(ruleId);
                }
            }
        }
    }
}