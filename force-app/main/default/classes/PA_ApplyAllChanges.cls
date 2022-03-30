public class PA_ApplyAllChanges {
    
    public Data_Change_Request_vod__c dataChangeRequest{get;set;}
    public Boolean isDisabled {get;set;}
    public Id currentRecordId {get;set;}
    public String mesajeWS {get;set;}
     
    public PA_ApplyAllChanges(ApexPages.StandardController stdController){
        isDisabled = false; 
        currentRecordId = ApexPages.currentPage().getParameters().get('id');
    }
    
    public PageReference updateRecord(){
        this.isDisabled = true;
        mesajeWS = '';
        dataChangeRequest = [SELECT ID, Status_vod__c, Result_vod__c FROM Data_Change_Request_vod__c WHERE ID =:currentRecordId LIMIT 1];
        dataChangeRequest.Status_vod__c = 'Processed_vod';
        dataChangeRequest.Result_vod__c = 'CHANGE_ACCEPTED';
        
        try{
            update dataChangeRequest;
        }catch (Exception e){
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + ' | ' + e.getCause() + ' | ' + e.getTypeName() + ' | ' + e.getStackTraceString() + ' | ' + e.getLineNumber()));
        }
        
        try{
            mesajeWS = DCR_Trigger_Button.Trigger_Class(currentRecordId);
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, mesajeWS + ' - ' + currentRecordId));
        }catch(Exception e){
            mesajeWS = 'Error description: ' + e.getMessage() + '\n\n';
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, mesajeWS + ' - ' + currentRecordId));
        }
        
        return null;
    }
}