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


@RestResource(urlMapping='/veeva/events-management/event/materials/catalogs')
global without sharing class VeevaCatalogMaterial extends VeevaMaterial{
    private static List<String> materialQueryFields = new List<String>{'Id', 'Name_vod__c', 'Material_Type_vod__c', 'Email_Template_vod__c', 'Description_vod__c', 'Material_vod__c', 'Current_Material_Status_vod__c'};
    private static final String CATALOG_PREVIEW = 'Catalog_Preview.jpg';
    private static final String STATUS_FAILURE = 'FAILURE';

    @HttpPost
    global static MaterialResultResponse processMaterial() {
        MaterialResultResponse materialResultResponse;
        RestResponse res = RestContext.response;
        if (RestContext.request.requestBody != null) {
            try{
                String requestBodyStr = RestContext.request.requestBody.toString();
                MaterialRequest materialRequest = (MaterialRequest) JSON.deserialize(requestBodyStr, MaterialRequest.class);
                
                String eventId = materialRequest.eventId;
                EM_Event_vod__c event;
                try {
                    event = [SELECT Id, Country_vod__c, Event_Configuration_vod__c, Topic_vod__c
                             FROM EM_Event_vod__c WHERE Id =:materialRequest.eventId];
                } catch (QueryException e) {
                    materialResultResponse = new MaterialResultResponse(STATUS_FAILURE, 'Event not found');
                    res.statusCode = 404;
                    return materialResultResponse;
                }
                List<EM_Event_Material_vod__c> existingMaterials = [SELECT Id, Material_vod__c
                                                                    FROM EM_Event_Material_vod__c
                                                                    WHERE Event_vod__c =:eventId];
                Set<String> materialIdSet = extractMaterialId(existingMaterials);
                
                List<EM_Event_Material_vod__c> eventMaterials = new List<EM_Event_Material_vod__c>();
                if (event.Event_Configuration_vod__c != null) {
                    List<EM_Event_Rule_vod__c> eventRules = fetchRules(event.Event_Configuration_vod__c, event.Country_vod__c);
                    eventMaterials.addAll(VeevaMaterialUtil.getNewRulesMaterial(eventRules, event, materialIdSet));
                }
                if (event.Topic_vod__c != null) {
                    List<EM_Topic_Material_vod__c> eventTopicMaterial = fetchTopicMaterials(event.Topic_vod__c);
                    eventMaterials.addAll(VeevaMaterialUtil.getNewTopicMaterial(eventTopicMaterial, event, materialIdSet));
                }
                
                materialResultResponse = createMissingMaterial(eventMaterials);
  
                List<EM_Event_Material_vod__c> materialsToReturn = fetchMaterials(materialRequest);
                Map<String, String> lastModifiedMap = fetchLastModifiedDates(materialsToReturn);
                materialResultResponse.data = new MaterialResult(materialsToReturn, lastModifiedMap);
                
                res.statusCode = 200;
            }  catch (Exception e) {
                materialResultResponse = new MaterialResultResponse(STATUS_FAILURE, e.getMessage());
                res.statusCode = 500;
            }
        } else {
            materialResultResponse = new MaterialResultResponse(STATUS_FAILURE, 'Request body is null');
            res.statusCode = 400;
        }
        return materialResultResponse;
    }
    


    private static List<EM_Event_Material_vod__c> fetchMaterials(MaterialRequest materialRequest) {
        String materialQuery = composeQuery(materialQueryFields, 'EM_Event_Material_vod__c', materialRequest);
        System.debug('fetch: ' + materialQuery);
        return Database.query(materialQuery);
    }

    private static List<EM_Event_Rule_vod__c> fetchRules(String eventConfigurationId, String countryId) {
        return [SELECT Event_Configuration_vod__c, Country_Override_vod__c, Country_Override_vod__r.Country_vod__c,
                Material_vod__c, Material_vod__r.RecordType.DeveloperName, Email_Template_vod__c, CLM_Presentation_vod__c
                FROM EM_Event_Rule_vod__c
                WHERE (Material_vod__c != null AND Material_vod__r.Status_vod__c = 'Approved_vod')
                AND Event_Configuration_vod__c =:eventConfigurationId
                AND (Country_Override_vod__c = null OR Country_Override_vod__r.Country_vod__c =:countryId)];
    }

    private static List<EM_Topic_Material_vod__c> fetchTopicMaterials(String topicId) {
        return [SELECT Material_vod__c, Material_vod__r.RecordType.DeveloperName, Topic_vod__c, Email_Template_vod__c,
                CLM_Presentation_vod__c
                FROM EM_Topic_Material_vod__c
                WHERE (Material_vod__c != null AND Material_vod__r.Status_vod__c = 'Approved_vod')
                AND Topic_vod__c =:topicId];
    }
    
    private static String composeQuery(List<String> queryFields, String queryObject, MaterialRequest materialRequest) {
        String query = 'SELECT ';
        query += String.join(queryFields, ', ');
        query += ' FROM ' + queryObject;
        List<String> whereClause = new List<String>();
        if(String.isNotBlank(materialRequest.eventId)) {
       		whereClause.add('Event_vod__c=\'' + String.escapeSingleQuotes(materialRequest.eventId) + '\'');
        }
        if(String.isNotBlank(materialRequest.recordTypeId)) {
       		whereClause.add('RecordTypeId=\'' + String.escapeSingleQuotes(materialRequest.recordTypeId) + '\'');
        }
        if(String.isNotBlank(materialRequest.currentMaterialStatus)) {
       		whereClause.add('Current_Material_Status_vod__c=\'' + String.escapeSingleQuotes(materialRequest.currentMaterialStatus) + '\'');
        }
        if(!whereClause.isEmpty()) {
            query += ' WHERE ' + String.join(whereClause, ' AND ');
        }
        return query;
    }

    private static Set<String> extractMaterialId(List<EM_Event_Material_vod__c> existingMaterials) {
        Set<String> materials = new Set<String>();
        for (EM_Event_Material_vod__c material : existingMaterials) {
            if(material.Material_vod__c != null) {
                materials.add(material.Material_vod__c);   
            }
        }
        return materials;
    }

    private static Map<String, String> fetchLastModifiedDates(List<EM_Event_Material_vod__c> materials) {
        if (materials == null) {
            return null;
        }
        
        Map<String, String> lastModifiedMap = new Map<String, String>();

        Set<String> catalogIds = new Set<String>();
        for (EM_Event_Material_vod__c material: materials) {
            if (material.Material_vod__c != null) {
                catalogIds.add(material.Material_vod__c);
            }
        }
        if (catalogIds.isEmpty()) {
            return lastModifiedMap;
        }

        Id contractRecordType = Schema.SObjectType.EM_Catalog_vod__c.getRecordTypeInfosByDeveloperName().get('Contract_vod').getRecordTypeId();
        
        List<EM_Catalog_vod__c> catalogs = [SELECT Id, RecordTypeId, (SELECT LastModifiedDate FROM CombinedAttachments
                                            WHERE Title !=: CATALOG_PREVIEW
                                            ORDER BY LastModifiedDate DESC LIMIT 1)
                                            FROM EM_Catalog_vod__c WHERE Id IN: catalogIds];
        
        for (EM_Catalog_vod__c catalog: catalogs) {
            String lastModifiedFormatted = null;
            if (catalog.CombinedAttachments != null && !catalog.CombinedAttachments.isEmpty()) {
                DateTime lastModifiedDate = catalog.CombinedAttachments[0].LastModifiedDate;
                if (catalog.RecordTypeId == contractRecordType) {
                    // display date and time for Contracts
                    lastModifiedFormatted = lastModifiedDate.format();
                } else {
                    // display just the date for print templates
                    lastModifiedFormatted = lastModifiedDate.date().format();
                }
            }
            lastModifiedMap.put(catalog.Id, lastModifiedFormatted);
        }
        return lastModifiedMap;
    }
    
    @TestVisible private class MaterialRequest {
        @TestVisible
        private String eventId;
        @TestVisible
        private String recordTypeId;
        @TestVisible
        private String currentMaterialStatus;    
    }

}