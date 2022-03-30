trigger VeevaMonitoringRuleTrigger on Monitoring_Rule_vod__c (before insert, before update) {
    
    VeevaMonitoringRuleTriggerHandler handler = new VeevaMonitoringRuleTriggerHandler();
    
    if (Trigger.isInsert)
    {
        if (Trigger.isBefore)
        {
            handler.OnBeforeInsert(Trigger.New);
        }
    }
	else if (Trigger.isUpdate)
    {
        if (Trigger.isBefore)
        {
            handler.OnBeforeUpdate(Trigger.New, Trigger.Old, Trigger.NewMap, Trigger.OldMap);
        }
    }
}