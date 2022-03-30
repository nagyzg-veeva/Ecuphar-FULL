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
 * VeevaSuggestionTriggerHandler populates record type field by Id or name when either of the value presents. 
 * For inserting WeChat_Call_vod or WeChat_vod suggestion record types, suggestion suvery field will be auto populated by WeChat setting.
 */
public without sharing class VeevaSuggestionTriggerHandler extends VeevaTriggerHandler {
    private static Map<Id, Schema.RecordTypeInfo> RECORD_TYPE_ID_MAP = Schema.SObjectType.Suggestion_vod__c.getRecordTypeInfosById();
    private static Map<String, Schema.RecordTypeInfo> RECORD_TYPE_NAME_MAP = Schema.SObjectType.Suggestion_vod__c.getRecordTypeInfosByDeveloperName();
    private static final List<String> SUGGESTION_SURVEY_RECORD_TYPES = new List<String>{'WeChat_vod', 'WeChat_Call_vod'};

    private List<Suggestion_vod__c> newSuggestions = new List<Suggestion_vod__c>();
    private List<Suggestion_vod__c> oldSuggestions = new List<Suggestion_vod__c>();
    private Map<ID, Suggestion_vod__c> newSuggestionsMap = new Map<ID, Suggestion_vod__c>();
    private Map<ID, Suggestion_vod__c> oldSuggestionsMap = new Map<ID, Suggestion_vod__c>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newSuggestions = (List<Suggestion_vod__c>) triggerNew;
        this.oldSuggestions = (List<Suggestion_vod__c>) triggerOld;
        this.newSuggestionsMap = (Map<ID, Suggestion_vod__c>) triggerNewMap;
        this.oldSuggestionsMap = (Map<ID, Suggestion_vod__c>) triggerOldMap;
    }
    
    protected override boolean doRecursionCheck() {
        return true;
    }
    
    protected override String sObjectType() {
        return 'Suggestion_vod__c';
    }

    protected override void beforeInsert() {
        vodSuggestionBeforeInsert();
    }
    
    protected override void beforeUpdate() {
        vodSuggestionBeforeUpdate();
    }

    private void vodSuggestionBeforeInsert() {
        List<Suggestion_vod__c> suggestionsToUpdate = new List<Suggestion_vod__c>();
        for (Suggestion_vod__c suggestion : newSuggestions) {
            String recordTypeName = suggestion.Record_Type_Name_vod__c;
            String recordTypeId = suggestion.RecordTypeId;
            if (String.isNotBlank(recordTypeName)) {
                setSuggestionRecordTypeByName(suggestion, recordTypeName);
            } else if (String.isNotBlank(recordTypeId)) {
                setSuggestionRecordTypeById(suggestion, recordTypeId);
            }
            if (String.isBlank(suggestion.Suggestion_Survey_vod__c) && SUGGESTION_SURVEY_RECORD_TYPES.contains(suggestion.Record_Type_Name_vod__c)) {
                suggestionsToUpdate.add(suggestion);
            }
        }
        if (suggestionsToUpdate.size() > 0) {
            populateSuggestionSurvey(suggestionsToUpdate);
        }
    }

    private void vodSuggestionBeforeUpdate() {
        for (Suggestion_vod__c suggestion : newSuggestions) {
            String recordTypeName = suggestion.Record_Type_Name_vod__c;
            String recordTypeId = suggestion.RecordTypeId;
            Suggestion_vod__c oldSuggestion = oldSuggestionsMap.get(suggestion.Id);
            if (recordTypeName != oldSuggestion.Record_Type_Name_vod__c) {
                setSuggestionRecordTypeByName(suggestion, recordTypeName);
            } else if (recordTypeId != oldSuggestion.RecordTypeId) {
                setSuggestionRecordTypeById(suggestion, recordTypeId);
            }
        }
    }

    private void setSuggestionRecordTypeByName(Suggestion_vod__c suggestion, String recordTypeName) {
        RecordTypeInfo recordType = RECORD_TYPE_NAME_MAP.get(recordTypeName);
        if (recordType != null) {
            suggestion.RecordTypeId = recordType.getRecordTypeId();
        }
    }

    private void setSuggestionRecordTypeById(Suggestion_vod__c suggestion, String recordTypeId) {
        RecordTypeInfo recordType = RECORD_TYPE_ID_MAP.get(recordTypeId);
        if (recordType != null) {
            suggestion.Record_Type_Name_vod__c = recordType.getDeveloperName();
        }
    }

    private void populateSuggestionSurvey(List<Suggestion_vod__c> suggestionsToUpdate) {
        // check WeChat setting and message
        String mappingValue = VOD_VEEVA_MESSAGE.getWeChatSettingsMsg('SUGGESTION_SURVEY_MAPPING_vod__c');
        if (String.isNotBlank(mappingValue)) {
            Map<String, String> suggestionSurveyMap = parseMappingData(mappingValue);
            if (suggestionSurveyMap.size() > 0) {
                updateSuggestionSurveyId(suggestionSurveyMap, suggestionsToUpdate);
            }
        }
    }

    private void updateSuggestionSurveyId(Map<String, String> suggestionSurveyMap, List<Suggestion_vod__c> suggestionsToUpdate) {
        Map<String, String> surveyNameIdMap = querySurveyByName(suggestionSurveyMap.values());
        for (Suggestion_vod__c suggestion : suggestionsToUpdate) {
            String surveyName = suggestionSurveyMap.get(suggestion.Record_Type_Name_vod__c);
            if (String.isNotBlank(surveyName)) {
                String surveyId = surveyNameIdMap.get(surveyName);
                if (String.isNotBlank(surveyId)) {
                    suggestion.Suggestion_Survey_vod__c = surveyId;
                }
            }
        }
    }

    @TestVisible private Map<String, String> parseMappingData(String value) {
        Map<String, String> resultMap = new Map<String, String>();
        List<String> entries = getSplitValues(value, ';;');
        for (String entry : entries) {
            String[] pairs = entry.split(',');
            if (pairs.size() == 2) {
                String recordType = pairs[0].trim();
                String surveyName = pairs[1].trim();
                // fetch first value for matched key
                if (String.isNotBlank(surveyName) && SUGGESTION_SURVEY_RECORD_TYPES.contains(recordType)
                    && !resultMap.containsKey(recordType)) {
                    resultMap.put(recordType, surveyName);
                }
            }
        }
        return resultMap;
    }

    private List<String> getSplitValues(String inputValue, String separator) {
        List<String> values;
        if (String.isNotBlank(inputValue)) {
            values = inputValue.split(separator);
        } else {
            values = new List<String>();
        }
        return values;
    }

    private Map<String, String> querySurveyByName(List<String> surveyNames) {
        Map<String, String> surveyNameIdMap = new Map<String, String>();
        for (Survey_vod__c survey : [SELECT Id, Name FROM Survey_vod__c WHERE Start_Date_vod__c <= TODAY AND End_Date_vod__c >= TODAY 
                        AND Status_vod__c = 'Published_vod' AND Channels_vod__c = 'Suggestions_vod'
                        AND Name IN :surveyNames ORDER BY LastModifiedDate ASC]) {            
            // get latest survey matches the survey name
            surveyNameIdMap.put(survey.Name, survey.id);
        }
        return surveyNameIdMap;
    }
    
}