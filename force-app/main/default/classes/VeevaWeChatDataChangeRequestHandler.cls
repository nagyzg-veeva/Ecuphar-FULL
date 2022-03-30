public without sharing class VeevaWeChatDataChangeRequestHandler {
    public void handleWeChatRelatedWork(List<Id> dcrIds) {
        updateSocialBindingActivityStatus(dcrIds);
        sendDcrNotification(dcrIds);
    }
    
    private void updateSocialBindingActivityStatus(List<Id> dcrIds) {
        List<String> unionIds = getRejectedDcrUnionId(dcrIds);
        updateSBAStatusToDenied(unionIds);
    }
    
    private List<String> getRejectedDcrUnionId(List<Id> dcrIds) {
        List<String> unionIds = new List<String>();
        
        for (Data_Change_Request_Line_vod__c dcrLine : [SELECT Id, New_Value_vod__c FROM Data_Change_Request_Line_vod__c 
             											WHERE Data_Change_Request_vod__r.Id IN :dcrIds 
            											AND Data_Change_Request_vod__r.Status_vod__c='Processed_vod' 
            											AND Data_Change_Request_vod__r.Result_vod__c='CHANGE_REJECTED'
            											AND Field_API_Name_vod__c='Union_Id_vod__c']) {
            unionIds.add(dcrLine.New_Value_vod__c);
        }
        
        return unionIds;
    }
    
	private void updateSBAStatusToDenied(List<String> unionIds) {
        if(unionIds.isEmpty()) {
            return;
        }
        
        List<Social_Binding_Activity_vod__c> updateSocialBindingActivitiesList = new List<Social_Binding_Activity_vod__c>();
    	for(Social_Identity_vod__c socialIdentity : [SELECT Id, Channel_Value_vod__c, Union_ID_vod__c,
                                                     (SELECT Id FROM Social_Binding_Activities__r 
                                                      WHERE Status_vod__c = 'Pending_vod' 
                                                      AND Social_Channel_Type_vod__c = 'WeChat_Work_vod'
                                                      AND Type_vod__c = 'Bind_vod' LIMIT 1) 
                                                     FROM Social_Identity_vod__c 
                                                     WHERE RecordType.DeveloperName = 'WeChat_vod'
                                                     AND Social_Channel_Type_vod__c = 'WeChat_Work_vod'
                                                     AND Status_vod__c = 'New_vod' AND Union_ID_vod__c IN : unionIds]){ 
          List<SObject> socialBindingActivities = socialIdentity.getSObjects('Social_Binding_Activities__r');
          if(socialBindingActivities != null && socialBindingActivities.size() > 0){
              Social_Binding_Activity_vod__c socialBindingActivity = (Social_Binding_Activity_vod__c)socialBindingActivities.get(0);
              socialBindingActivity.Status_vod__c = 'Denied_vod';
              updateSocialBindingActivitiesList.add(socialBindingActivity);
          }                                                    
        }
        
        if(updateSocialBindingActivitiesList.size() > 0){
            update updateSocialBindingActivitiesList;
        }
	}
    
    public void sendDcrNotification(List<Id> dcrIds){
        String domainUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c;
        if(domainUrl != null && !(''.equals(domainUrl))){
            Map<String,String> headers = new Map<String,String>();
            String orgId = UserInfo.getOrganizationId();
            String ts = String.valueOf(datetime.now().getTime());
            headers = VeevaWechatServiceUtil.getPostHeaders(ts,orgId);

            RequestBody requestBody = new RequestBody();
            requestBody.setDcrIds(dcrIds);
            requestBody.setTs(ts);
            String url = domainUrl + '/crm-service/api/wechatcrm/data-change-request/notification';
            String body = JSON.serialize(requestBody);
            VEEVA_WEC_WEB_SERVICE_ASYNC_UTIL.post(url, headers, body);
        }
	}
    
    private class RequestBody {
        private String ts;
        private List<String> dcrIds;
        public void setDcrIds(List<String> dcrIds){
            this.dcrIds = dcrIds;
        }
        public void setTs(String ts){
            this.ts = ts;
        }
    }
}