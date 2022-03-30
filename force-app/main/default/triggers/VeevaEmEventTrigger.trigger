trigger VeevaEmEventTrigger on EM_Event_vod__c (before insert, before update, before delete, after insert, after update) {
    VeevaTriggerHandler handler = new VeevaEmEventTriggerHandler();
    handler.handleTrigger();
}