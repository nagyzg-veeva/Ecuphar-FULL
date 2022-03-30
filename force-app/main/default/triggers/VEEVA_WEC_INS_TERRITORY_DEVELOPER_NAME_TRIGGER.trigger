trigger VEEVA_WEC_INS_TERRITORY_DEVELOPER_NAME_TRIGGER on Sent_Message_vod__c (before insert) {
    WeChat_Settings_vod__c wechatSetting = WeChat_Settings_vod__c.getInstance();
    boolean enableApprovedWeChat = (wechatSetting != null && 1.0 == wechatSetting.ENABLE_APPROVED_WECHAT_vod__c);

    if(!enableApprovedWeChat || !Schema.sObjectType.Sent_Message_vod__c.fields.Territory_vod__c.isCreateable()) {
        return;
    }

    Set<Id> accountIds = new Set<Id>();
    Set<Id> userIds = new Set<Id>(); 
    for (Sent_Message_vod__c smsg : trigger.new){
        accountIds.add(smsg.Account_vod__c);
        userIds.add(smsg.User_vod__c);
    }  
    //Get user territories
    Map<Id, Map<String, String>> userTerrs = TerritoryManagementFactory.getInstance().getUserTerritories(userIds, null);

    Set<Id> territoryIds = new Set<Id>();
    Map<String, List<String>> userTerritoryMap = new Map<String, List<String>>();
    for(Map<String, String> ut : userTerrs.values()){
        String userId = ut.get('UserId');
        String territoryId = ut.get('territoryId');
        territoryIds.add(territoryId);

        List<String> userTerritories = userTerritoryMap.get(userId);
        if (userTerritories == null) {
            userTerritories = new List<String>();
            userTerritoryMap.put(userId, userTerritories);
        }
        userTerritories.add(territoryId);
    }
    Map<Id, Map<String, String>> territoryMap = TerritoryManagementFactory.getInstance().getTerritories(territoryIds);

    //Get account and user shared territories
    Map<Id, Group> groupMap = new Map<Id, Group>([SELECT Id, relatedId FROM Group where relatedId IN : territoryMap.keySet()]);
    List<AccountShare> accountShareList = [SELECT UserOrGroupId, AccountId FROM AccountShare WHERE UserOrGroupId IN :groupMap.keySet() AND AccountId IN :accountIds];

    RecordTypeInfo wxRecordType = Schema.SObjectType.Sent_Message_vod__c.getRecordTypeInfosByDeveloperName().get('WeChat_vod');
    Id wechatRTId = null;
    if(wxRecordType != null) {
        wechatRTId = wxRecordType.getRecordTypeId();
    }

    for (Sent_Message_vod__c smsg : trigger.new) {
        if ((smsg.Territory_vod__c == null || smsg.Territory_vod__c == '') && smsg.User_vod__c != null) {
            String userId = smsg.User_vod__c;
            String accountId = smsg.Account_vod__c;
            List<String> userTerritories = userTerritoryMap.get(userId);
            if (userTerritories == null || userTerritories.size() == 0) {
                continue;
            }    
            if (userTerritories.size() == 1) {
                if (territoryMap.get(userTerritories[0]) != null) {
                    smsg.Territory_vod__c = territoryMap.get(userTerritories[0]).get('Name');
                }
            } else {
                String userOrGroupId = null;
                //Find the AccountShare object for this account
                for (AccountShare acctShare: accountShareList) {
                    if (accountId.equals(acctShare.AccountId)) {
                        userOrGroupId = acctShare.UserOrGroupId;
                        break;
                    }
                }
                //If we have a group ID then get the territory for that group
                if (userOrGroupId != null && groupMap.get(userOrGroupId) != null) {
                    String terrId = groupMap.get(userOrGroupId).relatedId;
                    if ( territoryMap.get(terrId) != null) {
                        smsg.Territory_vod__c = territoryMap.get(terrId).get('Name');
                    }
                } else {
                    if (territoryMap.get(userTerritories[0]) != null) {
                        smsg.Territory_vod__c = territoryMap.get(userTerritories[0]).get('Name');
                    }
                }
            }
        }
        if (wechatRTId != null && wechatRTId == smsg.RecordTypeId && smsg.Opened_vod__c == null) {
            smsg.Opened_vod__c = 0; // Set Opened_vod__c to 0 by default when insert Sent_Message_vod__c for WeChat_vod record type
        }
    }
}