@RestResource(urlMapping='/veeva/org-configs/*')
global without sharing class VeevaOrgConfigurationService {

    global class SettingsResponse extends VeevaBaseResponse {
        private final Map<String,Object> data;

        private SettingsResponse(Map<String, Object> data) {
            this.data = data;
        }
    }

    global static Map<String, Object> getOrgConfigWithFeatures(String features) {
        Map<String, Object> data = new Map<String, Object>();
        List<String> featuresList = features.split(',');

        VeevaOrgConfigFactory factory = new VeevaOrgConfigFactory();

        for(String feature:featuresList){
            VeevaOrgConfig orgConfig = factory.getOrgConfig(feature);
            if(orgConfig == null){
                Map<String,boolean> errorResponse = new Map<String,boolean>();
                errorResponse.put('hasInvalidName', true);
                return errorResponse;
            }
            data.put(feature, orgConfig.getOrgConfiguration());
        }

        return data;
    }

    @HttpGet
    global static VeevaBaseResponse getOrgConfig() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        VeevaBaseResponse settingsResponse;

        String features = request.params.get('name');
        if(features == null){
            return errorMessage(null,response);
        }

        Map<String, Object> data = getOrgConfigWithFeatures(features);

        if (data.containsKey('hasInvalidName')) {
            return errorMessage('name',response);
        }

        settingsResponse = new SettingsResponse(data);
        response.statusCode = 200;
        return settingsResponse;
    }

    private static VeevaBaseResponse errorMessage(String requestParamName, RestResponse response){
        response.statusCode = 400;
        return new VeevaBaseResponse('FAILURE', 'Invalid request for features: ' + requestParamName);
    }
}