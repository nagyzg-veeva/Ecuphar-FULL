public with sharing class NotesAttachmentsFilesController {
    
    @AuraEnabled
    public static List<ContentDocument> fetchFiles(String recordId) {
        Set<Id> contentDocIds = new Set<Id>();

        for (ContentDocumentLink link : [select ContentDocumentId from ContentDocumentLink where LinkedEntityId = :recordId]) {
            contentDocIds.add(link.ContentDocumentId);
        }

        return [
            select Id, Title, LastModifiedDate, ContentSize, FileType, 
                (select Id, ContentBodyId from ContentVersions where IsLatest = true) 
            from ContentDocument 
            where Id in :contentDocIds order by lastmodifieddate desc
        ];
	}

    @AuraEnabled(cacheable=true)
    public static List<Note> fetchNotes(String recordId) {
        return [
            select Id, Title, Lastmodifieddate 
            from Note 
            where ParentId = :recordId 
            order by lastmodifieddate desc
        ];
	}

    @AuraEnabled(cacheable=true)
    public static List<Attachment> fetchAttachments(String recordId) {
        return [
            select Id, Name, LastModifiedDate 
            from Attachment 
            where ParentId = :recordId
            order by LastModifiedDate desc
        ];
	}
}