trigger CCRMS_PS_AUTO_ASSIGNMENT on User (after insert, after update) {

//Get users created/updated in this new trigger
  List<User> userList = [select id, QS_Functional_Profile__c, CCRMS_Auto_Assign_Permission_Sets__c, Country_Code_QS__c from user where id in :trigger.new];
  
  system.debug('######### CCRMS_PS_AUTO_ASSIGNMENT: ' + userlist.size());
  
  for (User user : userList){
    system.debug('######### CCRMS_PS_AUTO_ASSIGNMENT - Running Assignment for: ' + user.id + ' - ' + user.QS_Functional_Profile__c + ' - ' + user.CCRMS_Auto_Assign_Permission_Sets__c +' - ' + user.Country_Code_QS__c);
    if(user.CCRMS_Auto_Assign_Permission_Sets__c){
        CCRMS_AssignPermissionSet.AssignPermissionSetToUsers(user.id, user.QS_Functional_Profile__c,user.Country_Code_QS__c);
        user.CCRMS_Auto_Assign_Permission_Sets__c = false;
        update user;
    }
  }
}