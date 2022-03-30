public without sharing class PublishHTMLReportToCDNLgtnVodController {
	@AuraEnabled
    public static void publishToCDN(String htmlReportId) {
        String requestUrl = new VOD_EMBED_CONTROLLER().getMcUrl() + '/api/v1/htmlreports/actions/publish';
        Map<String, String> vodInfo = SessionVod.getVodInfo();
        String body = '{"htmlReportId": "' + htmlReportId + '"}';
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestUrl);
		req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('sfEndpoint', vodInfo.get('sfEndpoint'));
        req.setHeader('sfSession', vodInfo.get('sfSession'));
        req.setBody(body);
        HttpResponse res = http.send(req);
    }

    @AuraEnabled
    public static String getMessage() {
        Message_vod__c message = [SELECT Text_vod__c from Message_vod__c where Name = 'PUBLISHING_STARTED' and Category_vod__c = 'FieldReporting' LIMIT 1];
        return message.Text_vod__c;
    }
}