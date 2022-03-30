trigger VeevaEmBusRuleConfigTrigger on EM_Business_Rule_Configuration_vod__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    VeevaTriggerHandler handler = new VeevaEmBusRuleConfigTriggerHandler();
    handler.handleTrigger();
}