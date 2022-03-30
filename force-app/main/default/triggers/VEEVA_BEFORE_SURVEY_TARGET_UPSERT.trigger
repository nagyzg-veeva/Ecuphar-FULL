trigger VEEVA_BEFORE_SURVEY_TARGET_UPSERT on Survey_Target_vod__c (before insert, before update) {
    VeevaSurveyTargetTriggerHandler handler = new VeevaSurveyTargetTriggerHandler();
    handler.handleBeforeUpsert(Trigger.new, Trigger.oldMap);
}