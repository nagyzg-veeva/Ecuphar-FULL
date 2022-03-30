/**
 * @description The factory to get the instance of a service. We should be calling this factory to get
 *              services instead of using 'new' unless you're writing a test
 */
public inherited sharing class VeevaJourneyServiceFactory {
    private static VeevaJourneyService journeyService;
    private static VeevaJourneyMetadataService metadataService;
    private static VeevaJourneyLookupService lookupService;
    private static VeevaJourneyPermissionService permissionService;

    public static VeevaJourneyService getJourneyService() {
        if (journeyService == null) {
            journeyService = (VeevaJourneyService) Type.forName('VeevaJourneyService').newInstance();
        }
        return journeyService;
    }

    public static VeevaJourneyMetadataService getMetadataService() {
        if (metadataService == null) {
            metadataService =
                (VeevaJourneyMetadataService) Type.forName('VeevaJourneyMetadataService').newInstance();
        }
        return metadataService;
    }

    public static VeevaJourneyLookupService getLookupService() {
        if (lookupService == null) {
            lookupService =
                (VeevaJourneyLookupService) Type.forName('VeevaJourneyLookupService').newInstance();
        }
        return lookupService;
    }

    public static VeevaJourneyPermissionService getPermissionService() {
        if (permissionService == null) {
            permissionService =
                (VeevaJourneyPermissionService) Type.forName('VeevaJourneyPermissionService').newInstance();
        }
        return permissionService;
    }
}