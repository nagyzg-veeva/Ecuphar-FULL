global class VEEVA_PREVIEW_GENERATION_PROCESS {
	@future(callout=true)
    public static void generatePreview(String auth, String sfSession, String sfEndpoint, String commaSepCatalogIds) {

        String baseUrl = getBaseUrl(commaSepCatalogIds);

        sendGeneratePreviewRequest(baseUrl, auth, sfSession, sfEndpoint);

    }

    @future(callout=true)
    public static void generatePreview(String auth, String sfEndpoint, String commaSepCatalogIds) {

        String baseUrl = getBaseUrl(commaSepCatalogIds);
        sendGeneratePreviewRequest(baseUrl, auth, SessionVod.getSessionId(), sfEndpoint);

    }

    private static String getBaseUrl(String catalogIds) {
        String baseUrl = VOD_Common.VOD_SERVER_URL + '/' + VOD_Common.VOD_VERSION + '/api/v1/';
        String queryParamBaseUrl = baseUrl;
        baseUrl += 'em.print/async/generate/previewFromTrigger?baseUrl=' + queryParamBaseUrl + '&catalogIds=' + catalogIds;
        return baseUrl;
    }

    private static void sendGeneratePreviewRequest(String endpoint, String auth, String sfSession, String sfEndpoint) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', auth);
        req.setHeader('sfSession', sfSession);
        req.setHeader('sfEndpoint', sfEndpoint);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');

        HttpResponse res = http.send(req);
        System.debug('Response: ' + res.toString());
    }
}