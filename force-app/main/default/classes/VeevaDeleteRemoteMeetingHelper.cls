global without sharing class VeevaDeleteRemoteMeetingHelper {

    @future (callout=true)
    public static void deleteRemoteMeetingFromServer(String auth, String sfSession, String sfEndpoint, Set<Id> meetingIds) {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String baseUrl = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c + '/api/v1/';
        baseUrl += 'remoteMeetings/meetings?ids=' + String.join(new List<Id>(meetingIds), ',');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl);
        req.setMethod('DELETE');
        req.setHeader('Authorization', auth);
        req.setHeader('sfSession', sfSession);
        req.setHeader('sfEndpoint', sfEndpoint);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');

        HttpResponse res = http.send(req);
    }
}