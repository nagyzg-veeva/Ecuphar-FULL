public without sharing class VeevaCRMRequestService {
    public static String getCRMServer() {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        return settings.Veeva_Server_vod__c;
    }
    
    public static Map<Integer, String> get(String path, Map<String, String> headers, boolean auraComp) {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String crmUrl = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c;
        crmUrl += path;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(crmUrl);
        request.setMethod('GET');
        
        if(headers!=null && !headers.isEmpty()) {
            for(String key: headers.keySet()) {
                request.setHeader(key, headers.get(key));
            }
        }

        if (auraComp) {
            request.setHeader('sfSession', SessionVod.getSessionId());
        } else {
            request.setHeader('sfSession', UserInfo.getSessionId());
        }
        request.setHeader('sfEndpoint', Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/45.0/' + UserInfo.getOrganizationId());
        request.setTimeout(30000);

        HttpResponse response = new Http().send(request);
        Map<Integer, String> result = new Map<Integer, String>();

        result.put(response.getStatusCode(), response.getBody());

        return result;
    }
}