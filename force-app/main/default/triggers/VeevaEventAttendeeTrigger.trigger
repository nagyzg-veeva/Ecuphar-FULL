trigger VeevaEventAttendeeTrigger on Event_Attendee_vod__c (before insert, before update, before delete, after insert, after update, after delete) {
    VeevaTriggerHandler handler = new VeevaEventAttendeeTriggerHandler();
    handler.handleTrigger();
}