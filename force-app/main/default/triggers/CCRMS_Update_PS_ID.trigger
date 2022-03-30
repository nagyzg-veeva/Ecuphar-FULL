Trigger CCRMS_Update_PS_ID on CCRMS_Permission_Set_Map__c (before update, before insert){
  for (CCRMS_Permission_Set_Map__c obj: trigger.new){
  try{
        PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name =: obj.CCRMS_Permission_Set_name__c LIMIT 1];
        obj.CCRMS_Permission_Set_ID__c = ps.Id;
    }
    catch(Exception e){
        //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This Permission Set API Name does not exist');
        //ApexPages.addMessage(myMsg);
        System.assert(false,'This Permission Set API Name does not exist');
    }
    
    
  }
}