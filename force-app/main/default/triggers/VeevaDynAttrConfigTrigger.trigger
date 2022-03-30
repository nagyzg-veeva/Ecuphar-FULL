trigger VeevaDynAttrConfigTrigger on Dynamic_Attribute_Configuration_vod__c (before update, before insert) {
    
    VeevaDynAttrConfigTriggerHandler handler = new VeevaDynAttrConfigTriggerHandler(Trigger.isExecuting, Trigger.size);

    if (Trigger.isUpdate && Trigger.isBefore) { 
        handler.onBeforeUpdate(trigger.Old, trigger.New);
    }

    if (Trigger.isInsert && Trigger.isBefore) {
        handler.onBeforeInsert(trigger.New);
    }
}