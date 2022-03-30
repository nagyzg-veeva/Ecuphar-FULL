public without sharing class VeevaMultichannelContentTriggerHandler {
    private static Map<Id, Schema.RecordTypeInfo> mccRecordTypeMap = Schema.SObjectType.Multichannel_Content_vod__c.getRecordTypeInfosById();

    public void handleTrigger(List<Multichannel_Content_vod__c> newMultichannelContents, System.TriggerOperation triggerEvent) {
        switch on triggerEvent {
            when BEFORE_INSERT, BEFORE_UPDATE {
                setVeevaExternalIds(newMultichannelContents);
            }
            when AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE {
                syncRefreshCache();
            }
            when else {
               //do nothing for BEFORE_DELETE
            }
        }
    }

    private void setVeevaExternalIds(List<Multichannel_Content_vod__c> newMultichannelContents) {
        for (Multichannel_Content_vod__c mcc: newMultichannelContents) {
            if(mccRecordTypeMap.get(mcc.RecordTypeId).getDeveloperName() == 'WeChat_vod' && mccRecordTypeMap.get(mcc.RecordTypeId).isActive() && mcc.VExternal_Id_vod__c == null) {
                // Only set the VExternal_Id_vod__c for record type is WeChat_Vod and that field is null 
                mcc.VExternal_Id_vod__c = GuidUtil.NewGuid() + '::1';
            }
        }
    }

    private void syncRefreshCache() {
        WeChat_Settings_vod__c wechatSetting = WeChat_Settings_vod__c.getInstance();
        Decimal enableApprovedWeChat = wechatSetting.ENABLE_APPROVED_WECHAT_vod__c;

        Decimal enabled = 1.0;
        if(enabled != enableApprovedWeChat){
            return;
        }

        String original = wechatSetting.APPROVED_WECHAT_BASE_URL_vod__c;
        // extract only the domain (remove the context path)
        URL url = new URL(original);
        String baseUrl = url.getProtocol() + '://' + url.getHost() + '/';
        String partnerURL = baseUrl + 'approved-service/cache/refresh/productContent/'+UserInfo.getOrganizationId();
        VEEVA_WEC_WEB_SERVICE_ASYNC_UTIL.get(partnerURL, null);
    }
}