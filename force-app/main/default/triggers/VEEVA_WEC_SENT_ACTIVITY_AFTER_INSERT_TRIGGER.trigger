trigger VEEVA_WEC_SENT_ACTIVITY_AFTER_INSERT_TRIGGER on Sent_Message_vod__c (after insert) {
    WeChat_Settings_vod__c wechatSetting = WeChat_Settings_vod__c.getInstance();
    Decimal enableApprovedWeChat = wechatSetting.ENABLE_APPROVED_WECHAT_vod__c;

    Decimal enabled = 1.0;
    if(enabled != enableApprovedWeChat) {
        return;
    }
    List<Account> acctList = new List<Account>();

    Set<Id> accIds = new Set<Id>() ;
    for (Integer i = 0; i < trigger.new.size(); i++) {
        accIds.add(trigger.new[i].Account_vod__c);
    }
    Map<Id, Account> accTsm = new Map<Id, Account>([Select Id,Total_Sent_Message_vod__c from Account where Id in :accIds]);

    List<Content_Type_vod__c> contentType = [SELECT Id FROM Content_Type_vod__c 
                                                  WHERE RecordType.DeveloperName = 'WeChat_WeChatWork_vod' 
                                                    AND Service_Account_App_Id_vod__c!=null
                                                  ORDER BY LastModifiedDate DESC
                                                  LIMIT 1];
    for(Sent_Message_vod__c activity : trigger.new) {

        Account ac = accTsm.get(activity.Account_vod__c);
        
        if (ac != null) {

           if(ac.Total_Sent_Message_vod__c==null) {
              ac.Total_Sent_Message_vod__c = 0;
           }
        
           if(contentType == null || contentType.size() <= 0 || (contentType.size() >= 1 && activity.Content_Type_vod__c != contentType.get(0).Id)){
              ac.Total_Sent_Message_vod__c = ac.Total_Sent_Message_vod__c + 1;
           }
        
           acctList.add(ac);
        }
    }
    update acctList;
}