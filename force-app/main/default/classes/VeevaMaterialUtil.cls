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
global without sharing class VeevaMaterialUtil {

    public static List<EM_Event_Material_vod__c> getNewTopicMaterial(List<EM_Topic_Material_vod__c> topicMaterials, EM_Event_vod__c event, Set<String> materials) {        
        List<EM_Event_Material_vod__c> eventMaterials = new List<EM_Event_Material_vod__c>();
        Map<String,Schema.RecordTypeInfo> materialRTByDeveloperName = EM_Event_Material_vod__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        for (EM_Topic_Material_vod__c topicMaterial : topicMaterials) {
            Boolean hasValidTopic = topicMaterial.Topic_vod__c == event.Topic_vod__c;
            
            if (hasValidTopic) {
                if (topicMaterial.Material_vod__c != null && !materials.contains(topicMaterial.Material_vod__c)) {
                    EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                        Material_vod__c = topicMaterial.Material_vod__c,
                        Event_vod__c = event.Id
                    );
                    if (materialRTByDeveloperName.get(topicMaterial.Material_vod__r.RecordType.DeveloperName) != null) {
                        eventMaterial.RecordTypeId = materialRTByDeveloperName.get(topicMaterial.Material_vod__r.RecordType.DeveloperName).getRecordTypeId();
                    }
                    materials.add(topicMaterial.Material_vod__c);
                    eventMaterials.add(eventMaterial);
                } else if (topicMaterial.Email_Template_vod__c != null && !materials.contains(topicMaterial.Email_Template_vod__c)) {
                    EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                        Email_Template_vod__c = topicMaterial.Email_Template_vod__c,
                        Event_vod__c = event.Id
                    );
                    Schema.RecordTypeInfo templateRecordType = materialRTByDeveloperName.get('Email_Template_vod');
                    if (templateRecordType != null) {
                        eventMaterial.RecordTypeId = templateRecordType.getRecordTypeId();
                    }
                    materials.add(topicMaterial.Email_Template_vod__c);
                    eventMaterials.add(eventMaterial);
                }
                else if (topicMaterial.CLM_Presentation_vod__c != null && !materials.contains(topicMaterial.CLM_Presentation_vod__c)) {
                    EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                        CLM_Presentation_vod__c = topicMaterial.CLM_Presentation_vod__c,
                        Event_vod__c = event.Id
                    );
                    Schema.RecordTypeInfo templateRecordType = materialRTByDeveloperName.get('CLM_Presentation_vod');
                    if (templateRecordType != null) {
                        eventMaterial.RecordTypeId = templateRecordType.getRecordTypeId();
                    }
                    materials.add(topicMaterial.CLM_Presentation_vod__c);
                    eventMaterials.add(eventMaterial);
                }
            }
        }
        return eventMaterials;
    }

    public static List<EM_Event_Material_vod__c> getNewRulesMaterial(List<EM_Event_Rule_vod__c> eventRules, EM_Event_vod__c event, Set<String> materials) {
        List<EM_Event_Material_vod__c> eventMaterials = new List<EM_Event_Material_vod__c>();
        Map<String,Schema.RecordTypeInfo> materialRTByDeveloperName = EM_Event_Material_vod__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        for (EM_Event_Rule_vod__c eventRule : eventRules) {
            Boolean hasValidEventConfiguration = eventRule.Event_Configuration_vod__c == event.Event_Configuration_vod__c;
            Boolean hasValidCountryOverride = eventRule.Country_Override_vod__c == null || eventRule.Country_Override_vod__r.Country_vod__c == event.Country_vod__c;
            
            if(hasValidEventConfiguration && hasValidCountryOverride) {
                if (eventRule.Material_vod__c != null && !materials.contains(eventRule.Material_vod__c)) {
                    EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                        Material_vod__c = eventRule.Material_vod__c,
                        Event_vod__c = event.Id
                    );
                    if (materialRTByDeveloperName.get(eventRule.Material_vod__r.RecordType.DeveloperName) != null) {
                        eventMaterial.RecordTypeId = materialRTByDeveloperName.get(eventRule.Material_vod__r.RecordType.DeveloperName).getRecordTypeId();
                    }
                    materials.add(eventRule.Material_vod__c);
                    eventMaterials.add(eventMaterial);
                }
                else if (eventRule.Email_Template_vod__c != null && !materials.contains(eventRule.Email_Template_vod__c)) {
                    EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                        Email_Template_vod__c = eventRule.Email_Template_vod__c,
                        Event_vod__c = event.Id
                    );
                    Schema.RecordTypeInfo templateRecordType = materialRTByDeveloperName.get('Email_Template_vod');
                    if (templateRecordType != null) {
                        eventMaterial.RecordTypeId = templateRecordType.getRecordTypeId();
                    }
                    materials.add(eventRule.Email_Template_vod__c);
                    eventMaterials.add(eventMaterial);
                }
                else if (eventRule.CLM_Presentation_vod__c != null && !materials.contains(eventRule.CLM_Presentation_vod__c)) {
                    EM_Event_Material_vod__c eventMaterial = new EM_Event_Material_vod__c(
                        CLM_Presentation_vod__c = eventRule.CLM_Presentation_vod__c,
                        Event_vod__c = event.Id
                    );
                    Schema.RecordTypeInfo templateRecordType = materialRTByDeveloperName.get('CLM_Presentation_vod');
                    if(templateRecordType != null) {
                        eventMaterial.RecordTypeId = templateRecordType.getRecordTypeId();
                    }
                    materials.add(eventRule.CLM_Presentation_vod__c);
                    eventMaterials.add(eventMaterial);
                }
            }
        }
        return eventMaterials;
    }
}