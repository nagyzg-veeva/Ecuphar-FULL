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

@RestResource(urlMapping='/veeva/events-management/event/materials/approved-documents')
global without sharing class VeevaApproveDocMaterial extends VeevaMaterial {

    private static final Id EMAIL_TEMPLATE_RECORD_TYPE = Schema.SObjectType.EM_Event_Material_vod__c
        .getRecordTypeInfosByDeveloperName().get('Email_Template_vod').getRecordTypeId();
    private static final String STATUS_FAILURE = 'FAILURE';

    @HttpPost
    global static MaterialResultResponse processMaterial() {
        MaterialResultResponse materialResultResponse;
        RestResponse res = RestContext.response;
        if (RestContext.request.requestBody != null) {
            try{
                String requestBodyStr = RestContext.request.requestBody.toString();
                MaterialRequest materialRequest = (MaterialRequest) JSON.deserialize(requestBodyStr, MaterialRequest.class);
                EM_Event_vod__c event;
                try {
                    event = [SELECT Id, Country_vod__c, Event_Configuration_vod__c, Topic_vod__c
                             FROM EM_Event_vod__c WHERE Id =:materialRequest.eventId];
                } catch (QueryException e) {
                    materialResultResponse = new MaterialResultResponse(STATUS_FAILURE, 'Event not found');
                    res.statusCode = 404;
                    return materialResultResponse;
                }

                List<EM_Event_Material_vod__c> existingMaterials = fetchMaterials(event.Id);
                Set<String> templateIdSet = new Set<String>();
                for (EM_Event_Material_vod__c material: existingMaterials) {
                    templateIdSet.add(material.Email_Template_vod__c);
                }

                List<EM_Event_Material_vod__c> newMaterials = new List<EM_Event_Material_vod__c>();

                if (event.Event_Configuration_vod__c != null) {
                    List<EM_Event_Rule_vod__c> eventRules = fetchRules(event.Event_Configuration_vod__c, event.Country_vod__c);
                    // getNewRulesMaterial() will update templateIdSet with any templates that are added to avoid duplicates
                    newMaterials.addAll(VeevaMaterialUtil.getNewRulesMaterial(eventRules, event, templateIdSet));
                }

                if (event.Topic_vod__c != null) {
                    List<EM_Topic_Material_vod__c> eventTopicMaterial = fetchTopicMaterials(event.Topic_vod__c);
                    // getNewTopicMaterial() will update templateIdSet with any templates that are added to avoid duplicates
                    newMaterials.addAll(VeevaMaterialUtil.getNewTopicMaterial(eventTopicMaterial, event, templateIdSet));
                }

                materialResultResponse = createMissingMaterial(newMaterials);

                List<EM_Event_Material_vod__c> materialsToReturn;
                if (newMaterials.isEmpty()) {
                    materialsToReturn = existingMaterials;
                } else {
                    materialsToReturn = fetchMaterials(event.Id);
                }

                materialResultResponse.data = new MaterialResult(materialsToReturn);

                res.statusCode = 200;

            } catch (Exception e) {
                materialResultResponse = new MaterialResultResponse(STATUS_FAILURE, e.getMessage());
                res.statusCode = 500;
            }
        } else {
            materialResultResponse = new MaterialResultResponse(STATUS_FAILURE, 'Request body is null');
            res.statusCode = 400;
        }
        return materialResultResponse;
    }

    private static List<EM_Event_Material_vod__c> fetchMaterials(String eventId) {
        return [SELECT Current_Material_Status_vod__c, Email_Template_vod__c, Subtype_vod__c
                FROM EM_Event_Material_vod__c
                WHERE RecordTypeId =:EMAIL_TEMPLATE_RECORD_TYPE AND Event_vod__c =:eventId
                AND Email_Template_vod__c != null];
    }

    private static List<EM_Event_Rule_vod__c> fetchRules(String eventConfigurationId, String countryId) {
        // although Material_vod__c and CLM_Presentation_vod__c will always be null here due to validation rules on Event Rule,
        // we must select these fields as they are used in getNewRulesMaterial()
        return [SELECT Event_Configuration_vod__c, Country_Override_vod__c, Country_Override_vod__r.Country_vod__c,
                Material_vod__c, Material_vod__r.RecordType.DeveloperName, Email_Template_vod__c, CLM_Presentation_vod__c
                FROM EM_Event_Rule_vod__c
                WHERE (Email_Template_vod__c != null AND Email_Template_vod__r.Status_vod__c IN ('Approved_vod', 'Staged_vod'))
                AND Event_Configuration_vod__c =:eventConfigurationId
                AND (Country_Override_vod__c = null OR Country_Override_vod__r.Country_vod__c =:countryId)];
    }

    private static List<EM_Topic_Material_vod__c> fetchTopicMaterials(String topicId) {
        // although Material_vod__c and CLM_Presentation_vod__c will always be null here due to validation rules on Topic Material,
        // we must select these fields as they are used in getNewTopicMaterial()
        return [SELECT Material_vod__c, Material_vod__r.RecordType.DeveloperName, Topic_vod__c, Email_Template_vod__c,
                CLM_Presentation_vod__c
                FROM EM_Topic_Material_vod__c
                WHERE (Email_Template_vod__c != null AND Email_Template_vod__r.Status_vod__c IN ('Approved_vod', 'Staged_vod'))
                AND Topic_vod__c =:topicId];
    }

    @TestVisible private class MaterialRequest {
        @TestVisible private String eventId;
    }

}