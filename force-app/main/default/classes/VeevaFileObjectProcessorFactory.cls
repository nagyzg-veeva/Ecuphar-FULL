public inherited sharing class VeevaFileObjectProcessorFactory {
    private static Pattern apiNamePattern = Pattern.compile('^([a-zA-Z0-9]+_)*[a-zA-Z0-9]+(__c)?$'); 
    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
    private static Map<String, String> prefixToObjNames = new Map<String, String>();
    static {
        for (SObjectType sObjType : globalDescribe.values()) {
            Schema.DescribeSObjectResult result = sObjType.getDescribe();
            prefixToObjNames.put(result.getKeyPrefix(), result.getName());
        }
    }

    public static void processFileObjectsValidation(List<ContentDocumentLink> docLinks, Map<Id, SObject> entityIdToFileObj) {
        processFileObjectsValidation(docLinks, entityIdToFileObj, false);
    }

    public static void processFileObjectsValidation(List<ContentDocumentLink> docLinks, Map<Id, SObject> entityIdToFileObj, boolean skipEditPermissions) {
        List<ContentDocumentLink> filteredDocumentLinks = filterMobileCreatedDocuments(docLinks);
        Map<String, Set<Id>> entityIdsMap = getEntityIdsMap(filteredDocumentLinks, 'linkedEntityId');
        validateHelper(entityIdsMap, entityIdToFileObj, skipEditPermissions);
    }

    public static void processFileObjectsValidation(List<Attachment> attachments, Map<Id, SObject> entityIdToAttachment) {
        Map<String, Set<Id>> entityIdsMap = getEntityIdsMap(attachments, 'parentId');
        validateHelper(entityIdsMap, entityIdToAttachment, false);
    }

    private static List<ContentDocumentLink> filterMobileCreatedDocuments(List<ContentDocumentLink> documentLinks) {
        List<ContentDocumentLink> filteredLinks = new List<ContentDocumentLink>();
        
        Map<Id, List<ContentDocumentLink>> documentsToLinks = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink documentLink : documentLinks) {
            List<ContentDocumentLink> linksForDocument = documentsToLinks.get(documentLink.ContentDocumentId);
            if (linksForDocument == null) {
                linksForDocument = new List<ContentDocumentLink>();
                documentsToLinks.put(documentLink.ContentDocumentId, linksForDocument);
            }
            linksForDocument.add(documentLink);
        }
        List<ContentVersion> mobileVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Mobile_Id_vod__c=null AND IsLatest=true AND ContentDocumentId IN :documentsToLinks.keySet()];
        for (ContentVersion version : mobileVersions) {
            filteredLinks.addAll(documentsToLinks.get(version.ContentDocumentId));
        }
        return filteredLinks;
    }

    private static Map<String, Set<Id>> getEntityIdsMap(List<SObject> linkObj, String entityIdFldName) {
        Map<String, Set<Id>> entityIdsMap = new Map<String, Set<Id>>();
        for (SObject link : linkObj) {  
            Id entityId = (Id)link.get(entityIdFldName);  

            String prefix = String.valueof(entityId).substring(0,3);
            String objectName = prefixToObjNames.get(prefix);
            if (objectName != null) {
                Set<Id> entityIds = entityIdsMap.get(objectName);
                if (entityIds == null) {
                    entityIds = new Set<Id>();
                    entityIdsMap.put(objectName, entityIds);
                }
                entityIds.add(entityId);
            }
        }
        return entityIdsMap;
    }
    
    public static void validateHelper(Map<String, Set<Id>> entityIdsMap, Map<Id, SObject> entitiesToFileObj, boolean skipEditPermissions) {                
        ApexClass[] processors = [SELECT Name FROM ApexClass WHERE Name LIKE 'Veeva%FileProcessor'];
        for (ApexClass classDef : processors) {
            Object classObj = Type.forName(classDef.Name).newInstance();
            if (classObj instanceof VeevaFileObjectProcessorFactory.BaseProcessor) {
                VeevaFileObjectProcessorFactory.BaseProcessor processor = (VeevaFileObjectProcessorFactory.BaseProcessor) classObj;
                Set<Id> entityIds = entityIdsMap.get(processor.getObjectName());
                if (entityIds != null) {
                    processor.process(entityIds, entitiesToFileObj, skipEditPermissions);
                }
            }
        }
    }

    public abstract with sharing class BaseProcessor {
        
        private String objectName;
        private Set<String> queryFields;

        public BaseProcessor(String objectName) {
            this.objectName = objectName;
            this.queryFields = new Set<String>{'Id', 'Name', 'Status_vod__c'};
        }

        public String getObjectName() {
            return this.objectName;
        }
        
        private void process(Set<Id> entityIds, Map<Id, SObject> entitiesToFileObj, boolean skipEditPermissions) {
            if (hasInvalidApiNames()) {
                return;
            }
        
            Set<Id> validEntities = new Set<Id>();
            Set<Id> submittedEntities = new Set<Id>();
            Map<Id, SObject> entityMap = new Map<Id, SObject>();
            if (skipEditPermissions || sObjUpdateable()) {
                String query = 'SELECT ' + String.join(new List<String>(this.queryFields), ',') +
                               ' FROM ' + objectName +
                               ' WHERE Id in :entityIds';
                List<SObject> sObjs = Database.query(query);
                for (SObject sObj : sObjs) {
                    entityMap.put(sObj.Id, sObj);
                    if (sObj.get('Status_vod__c') == 'Submitted_vod') {
                        submittedEntities.add(sObj.Id);
                    } else {
                        validEntities.add(sObj.Id);
                    }
                }
            }
            
            String genericErr = VeevaMessageController.getMsgWithDefault('LTNG_FILES_GENERIC_ERROR', 'Lightning', 
                'Error: You do not have permission to perform this action.');
            String submitErr = VeevaMessageController.getMsgWithDefault('LTNG_FILES_SUBMITTEDSTATUS_ERROR', 'Lightning', 
                'Error: You do not have permission to perform this action. This record is in Submitted status and cannot be modified.');

            for (Id entityId : entityIds) {
                SObject fileObj = entitiesToFileObj.get(entityId);
                if (submittedEntities.contains(entityId)) {
                    fileObj.addError(submitErr);
                } else if (!validEntities.contains(entityId)) {
                    fileObj.addError(genericErr);   
                }
            }
        }
        
        private boolean hasInvalidApiNames() {      
            for (String fldName : queryFields) {
                Matcher fldMatcher = apiNamePattern.matcher(fldName);
                if (!fldMatcher.matches()) {
                    return false;
                }
            }   
            return !apiNamePattern.matcher(objectName).matches();
        }
        
        private boolean sObjUpdateable() {
            boolean updateable = false;        
            SObjectType type = globalDescribe.get(objectName);
            if (type != null) {
                DescribeSObjectResult descr = type.getDescribe();
                updateable = descr != null && descr.isUpdateable();
            }
            return updateable;
        }
    }
}