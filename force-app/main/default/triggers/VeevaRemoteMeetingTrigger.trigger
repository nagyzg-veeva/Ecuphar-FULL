trigger VeevaRemoteMeetingTrigger on Remote_Meeting_vod__c (before update, before insert) {

    VeevaRemoteMeetingTriggerHandler handler = new VeevaRemoteMeetingTriggerHandler();

    if (Trigger.isUpdate) {
        handler.onBeforeUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isInsert) {
        handler.onBeforeInsert(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    }
}