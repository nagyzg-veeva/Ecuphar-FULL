public with sharing class TerritoryUtilitiesExtensionController {
    public TerritoryUtilitiesExtensionController(ApexPages.StandardSetController controller) {
    }

    public TerritoryUtilitiesExtensionController(ApexPages.StandardController controller) {
    }

    public TerritoryUtilitiesExtensionController() {
    }

    public static boolean getIsSandbox() {
        Map<String, Object> result = VeevaOrgConfigurationService.getOrgConfigWithFeatures('sandbox');
        return (Boolean)result.get('sandbox');
    }
}