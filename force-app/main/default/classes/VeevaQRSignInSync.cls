global class VeevaQRSignInSync implements Queueable, Database.AllowsCallouts{

    Set<Id> eventIds = new Set<Id>();

    public VeevaQRSignInSync(Set<Id> eventIds){
            this.eventIds = eventIds;
    }

    public void execute(QueueableContext context) {
        String auth = VOD_EMBED_CONTROLLER.getSfdcAuth();
        String sfSession = VOD_EMBED_CONTROLLER.getSfSession();
        String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();

        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String baseUrl = settings.Veeva_Server_vod__c + '/' + settings.Veeva_Version_vod__c + '/api/v1/';
        baseUrl += 'em/syncjob/';


        //System.debug('Auth: ' + auth);
        //System.debug('sfSession: ' + sfSession);
        //System.debug('sfEndpoint: ' + sfEndpoint);
        //System.debug('BaseURL: ' + baseUrl);
        //System.debug('queryIds: ' + queryIds);


        String queryIds = JSON.serialize(eventIds);
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl);
        req.setMethod('POST');
        req.setHeader('Authorization', auth);
        req.setHeader('sfSession', sfSession);
        req.setHeader('sfEndpoint', sfEndpoint);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setBody(queryIds);
		http.send(req);
    }
}