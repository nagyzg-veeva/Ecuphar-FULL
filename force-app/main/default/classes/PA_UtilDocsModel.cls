/* @Author Agimenez
    Description: This class should be use to create all Document generation methods
*/
global class PA_UtilDocsModel {
    global static Id CreateDoc(String DocTitle, String DocBody,Id DocFolderID){
        Document Document =  new Document(Name = DocTitle,
                            Body = Blob.ValueOf(DocBody),
                            FolderId = DocFolderID);
        insert Document;

        return Document.Id;
    }
    
    global static void CreateExceptionDoc(String DocTitle, String ErrorMessage,Id DocFolderID) {
        insert new Document(Name = DocTitle,
                            Body = Blob.valueOf(ErrorMessage),
                            FolderId = DocFolderId);
    }
}