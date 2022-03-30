trigger VeevaImplicitFilterTrigger on Implicit_Filter_vod__c(before insert, before update) {
    VeevaTriggerHandler handler = new VeevaImplicitFilterTriggerHandler();
    handler.handleTrigger();
}