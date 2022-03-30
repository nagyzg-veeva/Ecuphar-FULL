public with sharing class VEEVA_WEC_WEB_SERVICE_UTIL {

    public static String get(String url, Map < String, String > headers) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        if (headers != null && !headers.isEmpty()) {
            for (String key: headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }
        // Send the request, and return a response
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            String returnStr = 'StatusCode:' + String.valueOf(res.getStatusCode()) + ';' + res.getBody();
            return returnStr;
        }

    }
    public static String post(String url, Map < String, String > headers, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        if (headers != null && !headers.isEmpty()) {
            for (String key: headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }
        req.setBody(body);
        // Send the request, and return a response
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            String returnStr = 'StatusCode:+' + String.valueOf(res.getStatusCode()) + ';' + res.getBody();
            return returnStr;
        }
    }

    public static String post(String url, Map < String, String > headers, Blob body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        if (headers != null && !headers.isEmpty()) {
            for (String key: headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }
        req.setBodyAsBlob(body);
        // Send the request, and return a response
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            String returnStr = 'StatusCode:+' + String.valueOf(res.getStatusCode()) + ';' + res.getBody();
            return returnStr;
        }
    }
}