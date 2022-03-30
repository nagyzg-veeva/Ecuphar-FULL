public with sharing class MyInsightsController {

    public MyInsightsController(ApexPages.StandardSetController controller) {
    }

    public MyInsightsController(ApexPages.StandardController controller) {
    }

    public MyInsightsController() {
    }

    public static Boolean getIsSandbox() {
        Map<String,Object> result = VeevaOrgConfigurationService.getOrgConfigWithFeatures('sandbox');
        return (Boolean)result.get('sandbox');
    }

    public static String getOrgDomainUrl() {
        return URL.getOrgDomainUrl().toExternalForm();
    }
}