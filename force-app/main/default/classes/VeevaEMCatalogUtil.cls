public class VeevaEMCatalogUtil {

    public VeevaEMCatalogUtil() {}

    private static void generatePreview(Set<String> catalogIds) {

        String commaSeparatedCatalogIds = String.join((Iterable<String>)catalogIds, ',');
        if(commaSeparatedCatalogIds.length() > 0) {
            String auth = VOD_EMBED_CONTROLLER.getSfdcAuth();
            String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();
            VEEVA_PREVIEW_GENERATION_PROCESS.generatePreview(auth, sfEndpoint, commaSeparatedCatalogIds);
        }
    }

    public static void setEMCatalogIds (List<ContentDocumentLink> cdls) {
        Set<String> catalogIds = new Set<String>();
        for (ContentDocumentLink cdl : cdls) {
            Id parentId = cdl.LinkedEntityId;
            if (parentId.getSobjectType() == EM_Catalog_vod__c.SObjectType) {
                catalogIds.add(parentId);
            }
        }

        generatePreview(catalogIds);
    }
}