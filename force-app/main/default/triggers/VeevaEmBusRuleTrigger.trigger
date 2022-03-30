trigger VeevaEmBusRuleTrigger on EM_Business_Rule_vod__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    VeevaTriggerHandler handler = new VeevaEmBusRuleTriggerHandler();
    handler.handleTrigger();
}