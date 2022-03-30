global class CCRMS_AssignPermissionSet {

  @future 
  public static void AssignPermissionSetToUsers (ID userID, String functionalProfile, string countryCode) {
    //Gets the Mapping for that functional profile
    List<CCRMS_Permission_Set_Map__c>  PS_list = [SELECT ID, CCRMS_Functional_Profile__c, CCRMS_Permission_Set_name__c, CCRMS_Applies_To__c, CCRMS_Active__c from CCRMS_Permission_Set_Map__c 
    where CCRMS_Functional_Profile__c =: functionalProfile AND CCRMS_Active__c =: True AND (CCRMS_Applies_To__c LIKE : ('%' + countryCode + '%') OR CCRMS_Applies_To__c LIKE : ('%CORE%'))];    
    system.debug('######### CCRMS_AssignPermissionSet - PS_List: ' + PS_list.size());
    //Creates the list of PS to be assigned
    if(PS_list.size()>0){
      for (CCRMS_Permission_Set_Map__c ps_item : PS_list){
        try{
          //Gets the PS info
          system.debug('######### CCRMS_AssignPermissionSet - PS_List Getting PS: ' + ps_item.CCRMS_Permission_Set_name__c);
          PermissionSet ps = ([SELECT Id, Name FROM PermissionSet WHERE Name =: ps_item.CCRMS_Permission_Set_name__c LIMIT 1]);
                    
          system.debug('######### CCRMS_AssignPermissionSet - PS matching: ' + ps.Id);
          
          //Assign the permission set if not assigned
          if(ps != null){
            PermissionSetAssignment[] PSA_list = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =: userID AND PermissionSetId =: ps.Id];
            system.debug('######### CCRMS_AssignPermissionSet - PS Already Assigned: ' + PSA_list.size());
            
            if(PSA_list.size() == 0){
            system.debug('######### CCRMS_AssignPermissionSet - Assigning: PS:' + ps.id + ' - User: '+ userID);
              PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.id,AssigneeId = userID); 
              insert psa;
            }
          }
        }
        catch (Exception e){
        system.debug('######### CCRMS_AssignPermissionSet - ERROR: ' + e.getMessage());
        }
      }
    }
  }
}