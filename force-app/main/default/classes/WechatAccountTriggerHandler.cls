public without sharing class WechatAccountTriggerHandler {
    public WechatAccountTriggerHandler() {
    }
    
    public void handleTrigger() {
        System.TriggerOperation triggerOperation = Trigger.operationType;
        switch on triggerOperation {
            when AFTER_INSERT {
                afterInsert(Trigger.New);
            }
            when AFTER_UPDATE {
                afterUpdate(Trigger.Old, Trigger.New);
            }
        }
    }

    //union id should change from null to specific value
    private void afterUpdate(List<Account> oldAccounts, List<Account> newAccounts) { 
        List<Account> wechatAccounts = new List<Account>();
        for (Integer i = 0; i < newAccounts.size(); i++) {
            Account oldAcct = oldAccounts.get(i);
            Account newAcct = newAccounts.get(i);
            if(String.isBlank(oldAcct.Union_Id_vod__c) && String.isNotBlank(newAcct.Union_Id_vod__c)){
                wechatAccounts.add(newAcct);
            }
        }
        if(!wechatAccounts.isEmpty()){
           upsertRelated(wechatAccounts); 
        }
    }
      
    private void afterInsert(List<Account> newAccounts) {
        List<Account> wechatAccounts = new List<Account>();
        for (Account acct : newAccounts) {
            if(acct.Union_Id_vod__c != null){
                wechatAccounts.add(acct);
            }
        }
        if(!wechatAccounts.isEmpty()){
            upsertRelated(newAccounts);
        }
    }

    private void upsertRelated(List<Account> newAccounts){
        
        Schema.RecordTypeInfo multiConsentRd = Schema.SObjectType.Multichannel_Consent_vod__c.getRecordTypeInfosByDeveloperName().get('WeChat_vod');
        if(multiConsentRd == null){
            return;
        }
        List<Consent_Type_vod__c> consentType = [SELECT Id FROM Consent_Type_vod__c 
                                                  WHERE RecordType.DeveloperName = 'WeChat_vod' 
                                                  ORDER BY LastModifiedDate DESC
                                                  LIMIT 1];
        if(consentType.size() == 0){
            return;
        }
        List<Content_Type_vod__c> contentType = [SELECT Id FROM Content_Type_vod__c 
                                                  WHERE RecordType.DeveloperName = 'WeChat_WeChatWork_vod' 
                                                    AND Service_Account_App_Id_vod__c!=null
                                                  ORDER BY LastModifiedDate DESC
                                                  LIMIT 1];
        if(contentType.size() == 0){
            return;
        }
        Set<String> unionIds = new Set<String>();
        for (Account acct : newAccounts) {
            unionIds.add(acct.Union_Id_vod__c);
        }
        List<Multichannel_Consent_vod__c> multichannelConsents = new List<Multichannel_Consent_vod__c>();
        Map<String, Social_Identity_vod__c> socialIdentityMap = new Map<String, Social_Identity_vod__c>();
        Map<String, Social_Binding_Activity_vod__c> socialBindingActivitiesMap = new Map<String, Social_Binding_Activity_vod__c>();
        Map<String, DateTime> siCaptureTimeMap = new Map<String, DateTime>();
        for(Social_Identity_vod__c socialIdentity : [SELECT Id, Channel_Value_vod__c, Union_ID_vod__c,
                                                     (SELECT Id, Capture_Time_vod__c, Status_vod__c, Type_vod__c
                                                      FROM Social_Binding_Activities__r 
                                                      where Social_Channel_Type_vod__c = 'WeChat_Work_vod' ORDER BY CreatedDate ASC) 
                                                     FROM Social_Identity_vod__c 
                                                     WHERE RecordType.DeveloperName = 'WeChat_vod'
                                                     AND Social_Channel_Type_vod__c = 'WeChat_Work_vod'
                                                     AND Status_vod__c = 'New_vod' AND Union_ID_vod__c IN : unionIds]){ 
          socialIdentityMap.put(socialIdentity.Union_ID_vod__c, socialIdentity);  
          List<SObject> socialBindingActivities = socialIdentity.getSObjects('Social_Binding_Activities__r');
          if(socialBindingActivities != null && socialBindingActivities.size() > 0){
              for(SObject sba : socialBindingActivities){
                  Social_Binding_Activity_vod__c socialBindingActivity = (Social_Binding_Activity_vod__c)sba;
                  if(socialBindingActivity.Type_vod__c == 'Bind_vod'){
                      if(socialBindingActivity.Status_vod__c == 'Pending_vod'){          
                          socialBindingActivitiesMap.put(socialIdentity.Id, socialBindingActivity);
                      } else if(socialBindingActivity.Status_vod__c == 'Approved_vod'){                      
                          siCaptureTimeMap.put(socialIdentity.Id, socialBindingActivity.Capture_Time_vod__c);
                      } 
                  }
              }
          }
        }
        List<Social_Identity_vod__c> updateSocialIdentityList = new List<Social_Identity_vod__c>();
        List<Social_Binding_Activity_vod__c> updateSocialBindingActivitiesList = new List<Social_Binding_Activity_vod__c>();
        List<String> accountIds = new List<String>();
        Decimal disclaimerMode = WeChat_Settings_vod__c.getInstance().CUSTOMIZED_CONSENT_DISCLAIMER_vod__c;
        String optType = 'Opt_In_vod';
        String status = 'Approved_vod';
        if(disclaimerMode == 1.0){
            optType = 'Opt_In_Pending_vod'; 
            status = 'Submitted_vod';
        }
        for (Account acct : newAccounts) {
            // create a consent line
            Social_Identity_vod__c si = socialIdentityMap.get(acct.Union_Id_vod__c);
            Social_Binding_Activity_vod__c socialBindingActivities;
            if(si != null){
                socialBindingActivities = socialBindingActivitiesMap.get(si.Id);
            }else{
                continue;
            }
            if(acct.Union_Id_vod__c != null && socialBindingActivities != null){
                DateTime captureTime = null;  
                if (disclaimerMode == 2.0) {
                    if(socialBindingActivities.Capture_Time_vod__c == null){
                        captureTime = siCaptureTimeMap.get(si.Id);
                    }else{
                        captureTime = socialBindingActivities.Capture_Time_vod__c;
                    }       
                }
                accountIds.add(acct.Id);
                //Insert MCC: Mode 1 is pending; else Opt-in,Channel value is populated from SI.
                multichannelConsents.add(new Multichannel_Consent_vod__c(
                    Account_vod__c = acct.Id,
                    RecordTypeId = multiConsentRd.getRecordTypeId(),
                    Union_Id_vod__c = acct.Union_Id_vod__c,
                    Opt_Type_vod__c = optType,
                    Channel_Value_vod__c = si.Channel_Value_vod__c,
                    Consent_Type_vod__c = consentType.get(0).Id,
                    Content_Type_vod__c = contentType.get(0).Id,
                    Captured_By_vod__c = acct.CreatedById,
                    Capture_Datetime_vod__c = captureTime
                ));
                
                //Update SI to Bind with capture time and Account
                si.Capture_Time_vod__c = System.now();
                si.Account_vod__c = acct.Id;
                si.Status_vod__c = 'Bind_vod';
                updateSocialIdentityList.add(si);
                
                //Update SBA: Mode 1 is Submitted_vod; else Approved_vod,              
                socialBindingActivities.Status_vod__c = status;
                socialBindingActivities.Bound_To_vod__c = acct.Id;                   
                updateSocialBindingActivitiesList.add(socialBindingActivities);
            }
        }

        if(multichannelConsents.size() > 0){
            insert multichannelConsents;
        }
        if(updateSocialIdentityList.size() > 0){
            update updateSocialIdentityList;
        }
        if(updateSocialBindingActivitiesList.size() > 0){
            update updateSocialBindingActivitiesList;
        }
        
        callChangeRemarkAPI(accountIds);
    }
    
    //call the Wechat change remark API
    private void callChangeRemarkAPI(List<String> accountIds){       
        if(accountIds.size() > 0){
            String domainUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c;       
            if(domainUrl != null && !(''.equals(domainUrl))){            
                Map<String,String> headers = new Map<String,String>();
                String orgId = UserInfo.getOrganizationId();
                String ts = String.valueOf(datetime.now().getTime());
                headers = VeevaWechatServiceUtil.getPostHeaders(ts, orgId);
                RequestBody requestBody = new RequestBody();
                requestBody.setTs(ts);
                requestBody.setAccoundIds(accountIds);
                String url = domainUrl + '/qyaw-service/api/v1/external/wechatcrm/change-remark';
                String body = JSON.serialize(requestBody);
                VEEVA_WEC_WEB_SERVICE_ASYNC_UTIL.post(url, headers, body);
            }
        }
    }
    
    private class RequestBody{
        private String ts;
        private List<String> accountIds;
        public void setTs(String ts){
            this.ts = ts;
        }
        public void setAccoundIds(List<String> accountIds){
            this.accountIds = accountIds;
        }
    }
}