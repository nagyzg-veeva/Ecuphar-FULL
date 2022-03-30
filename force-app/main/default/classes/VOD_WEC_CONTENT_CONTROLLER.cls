public with sharing class VOD_WEC_CONTENT_CONTROLLER {
    List<VOD_WEC_CONTENT_WRAPPER> contents{get;set;}
	public ApexPages.StandardSetController contentRecords {
    	get {
            if(contentRecords == null) {
                contentRecords = new ApexPages.StandardSetController(
                    Database.getQueryLocator([SELECT Name,Expired_vod__c,Id,LastModifiedDate FROM Multichannel_Content_vod__c ORDER BY LastModifiedDate DESC]));
                contentRecords.setPageSize(25);
           }
           return contentRecords;
       }
       set;
   }
   public List<VOD_WEC_CONTENT_WRAPPER> getContents()
   {       
       contents = new List<VOD_WEC_CONTENT_WRAPPER>();
       for(Multichannel_Content_vod__c mc :(List<Multichannel_Content_vod__c>) contentRecords.getRecords())
       {
           contents.add(new VOD_WEC_CONTENT_WRAPPER(mc,getUrl(mc)));
       }
       return contents;
   }
    private String getUrl(Multichannel_Content_vod__c mc)
    {
        String url = getBaseUrl()+'/player?contentId='+mc.Id+'&orgId='+getSfOrgId()+'&ep='+getSfEndpoint()+'&sid='+getSfSessionId()+'&staged=true';
        return url;
    }
    private String getBaseUrl(){
    	return WeChat_Settings_vod__c.getOrgDefaults().APPROVED_WECHAT_BASE_URL_vod__c;
   	}
    private static String getSfSessionId() {
        return UserInfo.getSessionId();
    }

    private static String getSfEndpoint() {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/24.0/' + UserInfo.getOrganizationId();
    }
    
    private static String getSfOrgId() {
        return UserInfo.getOrganizationId();
    }
    
    public void previous() {
       contentRecords.previous();
    }

    public void next() {
        contentRecords.next();
    }
    public void first() {
       contentRecords.first();
   }
   public void last() {
       contentRecords.last();
   }
   public Boolean hasNext {
    get {
         return contentRecords.getHasNext();
       }
     set;
   }

   public Boolean hasPrevious {
       get {
           return contentRecords.getHasPrevious();
       }
       set;
   }
}