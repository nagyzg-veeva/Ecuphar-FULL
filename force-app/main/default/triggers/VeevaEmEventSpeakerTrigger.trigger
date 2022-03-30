trigger VeevaEmEventSpeakerTrigger on EM_Event_Speaker_vod__c (before insert, before update, before delete, after insert, after update, after delete) {
    VeevaTriggerHandler handler = new VeevaEmEventSpeakerTriggerHandler();
    handler.handleTrigger();
}