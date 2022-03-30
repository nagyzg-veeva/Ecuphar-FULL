trigger VeevaMonitoredPhraseTrigger on Monitored_Phrase_vod__c (before insert, before update) {

    VeevaMonitoredPhraseTriggerHandler handler = new VeevaMonitoredPhraseTriggerHandler();
    
    if (Trigger.isInsert)
    {
        if (Trigger.isBefore)
        {
            handler.OnBeforeInsert(Trigger.new);
        }
    }
    else if (Trigger.isUpdate)
    {
        if (Trigger.isBefore)
        {
            handler.OnBeforeUpdate(Trigger.New, Trigger.OldMap);
        }
    }
}