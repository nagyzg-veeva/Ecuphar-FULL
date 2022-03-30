trigger VEEVA_WEC_MULTICHANNEL_CONTENT_TRIGGER on Multichannel_Content_vod__c (after insert,after update, after delete, before insert, before update, before delete) {
    VeevaMultichannelContentTriggerHandler handler = new VeevaMultichannelContentTriggerHandler();
    handler.handleTrigger(Trigger.new, Trigger.operationType);
}