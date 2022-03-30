public without sharing class VeevaMcContentAssetTriggerHandler {

    private static Map<Id, Schema.RecordTypeInfo> mccRecordTypeMap = Schema.SObjectType.Multichannel_Content_vod__c.getRecordTypeInfosById();

    public void handleTrigger(List<Multichannel_Content_Asset_vod__c> newMultichannelContentAssets, System.TriggerOperation triggerEvent) {
        switch on triggerEvent {
            when BEFORE_INSERT, BEFORE_UPDATE {
                setExternalLinkContentFields(newMultichannelContentAssets);
            }
            when else {
               //do nothing for others
            }
        }
    }

    private void setExternalLinkContentFields(List<Multichannel_Content_Asset_vod__c> newMultichannelContentAssets) {

        Set<Id> mccIds = new Set<Id>();
        for(Multichannel_Content_Asset_vod__c mca : newMultichannelContentAssets){
            if (mca.Multichannel_Content_vod__c != null && mca.External_URL_vod__c != null){
                mccIds.add(mca.Multichannel_Content_vod__c);
            }
        }
    
        if (mccIds.size() > 0){
            setAssetVersionAndVeevaExternalIds(newMultichannelContentAssets, mccIds);
        }
    }

    private void setAssetVersionAndVeevaExternalIds(List<Multichannel_Content_Asset_vod__c> newMultichannelContentAssets, Set<Id> mccIds){
        List<Multichannel_Content_vod__c> updateContents = new List<Multichannel_Content_vod__c>();
        Map<Id, Multichannel_Content_vod__c> mccMap = new Map<Id, Multichannel_Content_vod__c>([SELECT Id, RecordTypeId, Name, VExternal_Id_vod__c FROM Multichannel_Content_vod__c WHERE Id IN : mccIds]);
        for(Multichannel_Content_Asset_vod__c mca : newMultichannelContentAssets){
            //Only update the VeevaExternal, Version of a asset and trigger the update for WeChat_vod content
            Multichannel_Content_vod__c mcc = mccMap.get(mca.Multichannel_Content_vod__c);
            if (mcc != null && mccRecordTypeMap.get(mcc.RecordTypeId).getDeveloperName() == 'WeChat_vod') {
                updateContents.add(mcc);
                if (mca.Multichannel_Content_vod__c != null && mca.External_URL_vod__c != null){
                    mca.VExternal_Id_vod__c = mcc.VExternal_Id_vod__c + '::1::'+ mca.Status_vod__c;
                    mca.Version_vod__c = '1.0';
                }
            }
        }
        // This update will trigger the chche sync cache update process.
        update updateContents;
    }
}