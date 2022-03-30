public with sharing class VEEVA_WECHAT_EMBED_CONTROLLER {

    private static final String CLEAR_CACHE_ENDPOINT='/cache/all/clear';
    
    public String getClearCacheEndpoint() {
        return CLEAR_CACHE_ENDPOINT;
    }

    public String getFullWcrmUrl() {
        return getServerUrl(getSettings().WECHAT_CRM_BASE_URL_vod__c, true);
    }
    
    private WeChat_Settings_vod__c getSettings() {
        return WeChat_Settings_vod__c.getInstance();
    }
    
    private String getServerUrl(String urlFromSetting, boolean includeContextPath) {
        String serverUrl = '';
        if(String.isNotBlank(urlFromSetting)) {
            try {
                URL url = new URL(urlFromSetting);
                String port = url.getPort() > 0 ? (':' + String.valueOf(url.getPort())) : '';
                serverUrl = url.getProtocol() + '://' + url.getHost() + port;
                if (includeContextPath && String.isNotBlank(url.getPath())) {
                    List<String> paths = url.getPath().split('/');
                    for (String path : paths) {
                        if (String.isNotBlank(path)) {
                            serverUrl += ('/' + path);
                            break;
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('URL in WeChat Setting is not valid, url=' + urlFromSetting +
                        ', e=[' + e.getTypeName() + ']-' + e.getMessage());
            }
        }
        return serverUrl;
    }
}