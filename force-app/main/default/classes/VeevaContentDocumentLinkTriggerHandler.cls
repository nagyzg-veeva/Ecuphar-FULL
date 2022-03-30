public inherited sharing class VeevaContentDocumentLinkTriggerHandler extends VeevaTriggerHandler {

    private List<ContentDocumentLink> oldLinks = new List<ContentDocumentLink>();
    private List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.oldLinks = (List<ContentDocumentLink>)triggerOld;
        this.newLinks = (List<ContentDocumentLink>)triggerNew;
    }

    protected override String sObjectType() {
        return 'ContentDocumentLink';
    }

    @TestVisible
    protected override void beforeDelete() {
        Map<Id, SObject> entityIdToDoc = getEntityIdToDocsMap(oldLinks);
        VeevaFileObjectProcessorFactory.processFileObjectsValidation(oldLinks, entityIdToDoc);
    }

    protected override void afterInsert() {
        VeevaEMCatalogUtil.setEMCatalogIds(this.newLinks);
        VeevaEmMaterialProcessor emMaterialProcessor = new VeevaEmMaterialContentDocProcessor(newLinks);
        emMaterialProcessor.updateHasAttachmentFlagForInsert();
    }

    private static Map<Id, SObject> getEntityIdToDocsMap(List<ContentDocumentLink> docLinks) {
        Map<Id, SObject> entityIdToDoc = new Map<Id, SObject>();
        for (ContentDocumentLink link : docLinks) {
            entityIdToDoc.put(link.LinkedEntityId, link);
        }
        return entityIdToDoc;
    }
}