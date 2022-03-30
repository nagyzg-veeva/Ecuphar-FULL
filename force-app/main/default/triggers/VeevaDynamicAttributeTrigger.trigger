trigger VeevaDynamicAttributeTrigger on Dynamic_Attribute_vod__c
    (before insert, before update, after insert, after update) {

    VeevaDynamicAttributeTriggerHandler handler = new VeevaDynamicAttributeTriggerHandler(Trigger.isExecuting, Trigger.size);

    if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            handler.onBeforeUpdate(Trigger.New, Trigger.Old);
        } else {
            handler.onAfterUpdate(Trigger.New, Trigger.Old);
        }
    } else if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            handler.onBeforeInsert(Trigger.New);
        } else {
            handler.onAfterInsert(Trigger.New);
        }
    }
}