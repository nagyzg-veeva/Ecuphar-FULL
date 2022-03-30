public with sharing class VeevaUserInterfaceAPI {

	@AuraEnabled(cacheable=true)
	public static Map<String, String> getInfo(String session, String url) {
		return request(session, url);
	}

	@AuraEnabled
	public static Map<String, String> getData(String session, String url) {
		return request(session, url);
	}

	private static Map<String, String> request(String session, String url) {
		Map<String, String> result = new Map<String, String>();
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setEndpoint(System.URL.getOrgDomainUrl().toExternalForm() + '/services/data/v50.0' + url);
		request.setMethod('GET');
		request.setHeader('Authorization', 'OAuth ' + session);
		request.setHeader('Content-Type', 'application/json;charset=UTF-8');
		request.setHeader('X-Chatter-Entity-Encoding', 'false');
		HttpResponse response = http.send(request);
		if (response.getStatusCode() == 200) {
			result.put('data', response.getBody());
		}
		else {
            result.put('errorData', response.getBody());
			result.put('errorStatus', response.getStatus());
		}
		return result;
	}
}