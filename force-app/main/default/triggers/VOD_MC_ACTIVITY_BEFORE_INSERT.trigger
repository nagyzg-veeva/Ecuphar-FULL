trigger VOD_MC_ACTIVITY_BEFORE_INSERT on Multichannel_Activity_vod__c(before insert) {
    
    if(Schema.sObjectType.Multichannel_Activity_vod__c.fields.Territory_vod__c.isCreateable() && (Schema.sObjectType.Sent_Email_vod__c.fields.Territory_vod__c.isAccessible() || Schema.sObjectType.Call2_vod__c.fields.Territory_vod__c.isAccessible())){

        Set<Id> sentEmailIds = new Set<Id>();
        Set<Id> callIds = new Set<Id>();
        
        //Set territory by sent message when Approved WeChat is enabled.
        WeChat_Settings_vod__c wechatSetting = WeChat_Settings_vod__c.getInstance();
        boolean enableApprovedWeChat = (wechatSetting != null && 1.0 == wechatSetting.ENABLE_APPROVED_WECHAT_vod__c);
        boolean checkSentMessage = true;

        if (!enableApprovedWeChat || Schema.SObjectType.Multichannel_Activity_vod__c.fields.getMap().get('Sent_Message_External_Id_vod__c') == null
            || !Schema.SObjectType.Multichannel_Activity_vod__c.fields.getMap().get('Sent_Message_External_Id_vod__c').getDescribe().isAccessible()
            || Schema.sObjectType.Sent_Message_vod__c.fields.getMap().get('Territory_vod__c') == null
            || !Schema.sObjectType.Sent_Message_vod__c.fields.getMap().get('Territory_vod__c').getDescribe().isAccessible()) {
                checkSentMessage = false;
        } 
        Set<String> sentMessageExtIds = new Set<String>();

        for(Multichannel_Activity_vod__c mca: Trigger.new){
            if(mca.Territory_vod__c == null){
                if (mca.Sent_Email_vod__c != null) {
                    sentEmailIds.add(mca.Sent_Email_vod__c);
                } else if (mca.Call_vod__c != null) {
                    callIds.add(mca.Call_vod__c );  
                } else if (checkSentMessage && mca.Sent_Message_External_Id_vod__c != null) {
                    sentMessageExtIds.add(mca.Sent_Message_External_Id_vod__c);
                }
            }
        }
                
        Map<Id, Sent_Email_vod__c> sentEmails;
        if(sentEmailIds.size() > 0){
            sentEmails = new Map<Id, Sent_Email_vod__c>([Select Id, Territory_vod__c FROM Sent_Email_vod__c WHERE Id IN :sentEmailIds]);
        }
        else{
            sentEmails = new Map<Id, Sent_Email_vod__c>();
        }
        
        Map<Id, Call2_vod__c> calls;
        if(callIds.size() > 0){
            calls = new Map<Id, Call2_vod__c>([Select Id, Territory_vod__c FROM Call2_vod__c WHERE Id IN :callIds]);
        }
        else{
            calls = new Map<Id, Call2_vod__c>();
        }

        List<Sent_Message_vod__c> sentMessageList;
        if (sentMessageExtIds.size() > 0) {
            sentMessageList = [select Id, VExternal_Id_vod__c, Territory_vod__c from Sent_Message_vod__c where VExternal_Id_vod__c in :sentMessageExtIds ];
        }
        
        for(Multichannel_Activity_vod__c mca: Trigger.new){
            if(mca.Territory_vod__c == null){
                if (mca.Sent_Email_vod__c != null) {
                    Sent_Email_vod__c se = sentEmails.get(mca.Sent_Email_vod__c);
                    mca.Territory_vod__c = se.Territory_vod__c;
                } else if (mca.Call_vod__c != null) {
                    Call2_vod__c call = calls.get(mca.Call_vod__c);
                    mca.Territory_vod__c = call.Territory_vod__c;
                } else if (checkSentMessage && mca.Sent_Message_External_Id_vod__c != null && sentMessageList != null && sentMessageList.size() > 0) {
                    for(Sent_Message_vod__c smsg: sentMessageList) {
                        if (mca.Sent_Message_External_Id_vod__c == smsg.VExternal_Id_vod__c) {
                            mca.Territory_vod__c = smsg.Territory_vod__c;
                            break;
                        }
                    }
                }
            }            
        }

    }
}