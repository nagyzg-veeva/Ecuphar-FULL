global class VEEVA_RUN_CONCUR_SYNC_PROCESS implements Schedulable {
    global void execute(SchedulableContext sc) {
        runActivitySync();
    }

    @future(callout=true)
    public static void runActivitySync() {
        String url = VOD_Common.VOD_SERVER_URL + '/' + VOD_Common.VOD_VERSION;
                
        String orgId = [select Id from organization limit 1].Id;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(url+'?oType=concursync&orgId='+orgId);
        HttpResponse res = h.send(req);
    }
}