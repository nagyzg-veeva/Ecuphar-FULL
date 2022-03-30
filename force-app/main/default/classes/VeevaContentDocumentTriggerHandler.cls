public inherited sharing class VeevaContentDocumentTriggerHandler extends VeevaTriggerHandler {

    private List<SObject> oldDocs = new List<SObject>();
    private Map<Id, SObject> oldDocsMap = new Map<Id, SObject>();
    private List<SObject> newDocs = new List<SObject>();

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.oldDocs = triggerOld;
        this.oldDocsMap = triggerOldMap;
        this.newDocs = triggerNew;
    }

    protected override String sObjectType() {
        return 'ContentDocument';
    }

    @TestVisible
    protected override void beforeUpdate() {
        Map<Id, ContentDocument> newVersionDocs = new Map<Id, ContentDocument>();

        for (Integer i=0; i<newDocs.size(); i++) {
            ContentDocument oldDoc = (ContentDocument)oldDocs.get(i);
            ContentDocument newDoc = (ContentDocument)newDocs.get(i);
            if (oldDoc.LatestPublishedVersionId != newDoc.LatestPublishedVersionId) {
                //changed VersionId means Upload New Version
                newVersionDocs.put(newDoc.Id, newDoc);
            }
        }
        if (newVersionDocs.size() > 0) {
            processContentDocuments(newVersionDocs, false, false);
        }
    }

    @TestVisible
    protected override void beforeDelete() {
        processContentDocuments(this.oldDocsMap, true, false);
    }

    private static void processContentDocuments(Map<Id, SObject> docsMap, boolean isBeforeDelete, boolean skipEditPermissions) {
        List<ContentDocumentLink> docLinks = getContentDocumentLinks(docsMap.keySet());

        if (isBeforeDelete) {
            VeevaEmMaterialProcessor emMaterialProcessor = new VeevaEmMaterialContentDocProcessor(docLinks);
            emMaterialProcessor.updateHasAttachmentFlagForDelete();
        }

        Map<Id, SObject> entityIdToDoc = getEntityIdToDocsMap(docLinks, docsMap);
        VeevaFileObjectProcessorFactory.processFileObjectsValidation(docLinks, entityIdToDoc, skipEditPermissions);
    }

    private static List<ContentDocumentLink> getContentDocumentLinks(Set<Id> docIds) {
        return [
            SELECT Id, ContentDocumentId, LinkedEntityId, LinkedEntity.Name
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
        ];
    }

    private static Map<Id, SObject> getEntityIdToDocsMap(List<ContentDocumentLink> docLinks, Map<Id, SObject> docsMap) {
        Map<Id, SObject> entityIdToDoc = new Map<Id, SObject>();
        for (ContentDocumentLink link : docLinks) {
            entityIdToDoc.put(link.LinkedEntityId, docsMap.get(link.ContentDocumentId));
        }
        return entityIdToDoc;
    }
}