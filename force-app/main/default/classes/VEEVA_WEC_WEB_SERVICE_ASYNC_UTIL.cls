public class VEEVA_WEC_WEB_SERVICE_ASYNC_UTIL {

    
    @future(callout=true)
    public static void get(String url, Map<String,String> headers)
    {
        VEEVA_WEC_WEB_SERVICE_UTIL.get(url, headers);
    }

    @future(callout=true)
    public static void post(String url, Map<String,String> headers,String body)
    {
        VEEVA_WEC_WEB_SERVICE_UTIL.post(url, headers,body);
    }
}