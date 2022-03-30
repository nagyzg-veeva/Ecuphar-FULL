public without sharing class VeevaContentPhraseTriggerHandler {
    public VeevaContentPhraseTriggerHandler(){
        
    }
    private static final String RD_WECHAT_PHRASE = 'WeChat_Phrase_vod';
    
    //Build phrase cache hashkey and clear cache by Approved_Phrase_vod__c 
    public void clearPhraseCacheByAP(List<Approved_Phrase_vod__c> aps){       
        if(aps == null || aps.size() == 0){
            return;
        }

        Set<Id> ids = new Set<Id>();
        Map<Id,Set<String>> apMap = new Map<Id,Set<String>>();
        for(Approved_Phrase_vod__c ap : aps){
            if(ids.contains(ap.Id)){
                apMap.get(ap.Id).add(ap.Language_vod__c);
            } else{
            	ids.add(ap.Id);
            	Set<String> languageSet = new Set<String>();
                languageSet.add(ap.Language_vod__c);
            	apMap.put(ap.Id, languageSet);
            }
        }

        Set<String> keySet = new Set<String>();
        if(ids.size() > 0){
            for(Content_Phrase_Association_vod__c cpa : [SELECT Content_vod__c, Approved_Phrase_vod__c
                                                         FROM Content_Phrase_Association_vod__c
                                                         WHERE Approved_Phrase_vod__c in :ids
                                                         AND RecordType.DeveloperName=:RD_WECHAT_PHRASE]){
  				for(String language : apMap.get(cpa.Approved_Phrase_vod__c)){
                    String hashKey = 'contentId=' + cpa.Content_vod__c + ',language=' + language;
                    keySet.add(hashKey);
                }
			}
        }

        //Call clear phrase cache api
        if(keySet.size() > 0){
            this.callClearPhraseCacheAPI(keySet);
        }
    }

    //Build phrase cache hashkey and clear cache by Content_Phrase_Association_vod__c
    public void clearPhraseCacheByCPA(List<Content_Phrase_Association_vod__c> cpas){
        if(cpas == null || cpas.size() == 0){
            return;
        }

        Set<String> keySet = new Set<String>();
        RecordTypeInfo recordType = Schema.SObjectType.Content_Phrase_Association_vod__c
                                          .getRecordTypeInfosByDeveloperName()
                                          .get(RD_WECHAT_PHRASE);
        if(recordType != null){
            Set<Id> ids = new Set<Id>();
            Map<Id,Set<Id>> cpaIdMap = new Map<Id,Set<Id>>();
            for(Content_Phrase_Association_vod__c cpa : cpas){
                if(recordType.getRecordTypeId().equals(cpa.RecordTypeId)){
                    if(ids.contains(cpa.Approved_Phrase_vod__c)){
                        cpaIdMap.get(cpa.Approved_Phrase_vod__c).add(cpa.Content_vod__c);
                    }else{
                      	ids.add(cpa.Approved_Phrase_vod__c);
                        Set<Id> contentIdSet = new Set<Id>();
                        contentIdSet.add(cpa.Content_vod__c);
                        cpaIdMap.put(cpa.Approved_Phrase_vod__c, contentIdSet);
                    }
                }
            }

            if(ids.size() > 0){
                for(Approved_Phrase_vod__c ap : [SELECT Id,Language_vod__c
                                                 FROM Approved_Phrase_vod__c
                                                 WHERE Id in :ids]){
                    for(Id contentId : cpaIdMap.get(ap.Id)){
						String hashKey = 'contentId=' + contentId + ',language=' + ap.Language_vod__c;
						keySet.add(hashKey);
                    }
				}
            }
        }

        //Call clear phrase cache api
        if(keySet.size() > 0){
            this.callClearPhraseCacheAPI(keySet);
        }
    }

    //Call the clear content phrase cache API
    private void callClearPhraseCacheAPI(Set<String> keySet){
        String domainUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c;
        if(domainUrl != null && !(''.equals(domainUrl))){
            Map<String,String> headers = new Map<String,String>();
            String orgId = UserInfo.getOrganizationId();
            String ts = String.valueOf(datetime.now().getTime());
            headers = VeevaWechatServiceUtil.getPostHeaders(ts, orgId);
            String url = domainUrl + '/crm-service/api/v1/external/wechatcrm/phrase-cache';
            Map<String,Object> param = new Map<String,Object>();
            param.put('orgId', orgId);
            param.put('ts', ts);
            param.put('keySet', keySet);
            String body = JSON.serialize(param);
            
            VEEVA_WEC_WEB_SERVICE_ASYNC_UTIL.post(url, headers, body);
        }
    }
}