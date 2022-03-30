trigger VOD_SUGGESTION_BEFORE_INSERT_UPDATE on Suggestion_vod__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    VeevaTriggerHandler handler = new VeevaSuggestionTriggerHandler();
    handler.handleTrigger();
}