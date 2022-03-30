trigger VeevaMultichannelContentAssetTrigger on Multichannel_Content_Asset_vod__c (before insert,before update){
    VeevaMcContentAssetTriggerHandler handler = new VeevaMcContentAssetTriggerHandler();
    handler.handleTrigger(Trigger.new, Trigger.operationType);
}