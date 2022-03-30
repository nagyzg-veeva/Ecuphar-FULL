public class TaskTriggerHandler {

 String NO_DEL_SUB;
 String NO_UPD_SUB;
 Map <Id, Call2_vod__c> calls;
 
 public TaskTriggerHandler(List<Task> tasks) {
    VOD_ERROR_MSG_BUNDLE bnd = new VOD_ERROR_MSG_BUNDLE ();
    NO_DEL_SUB = bnd.getErrorMsg('NO_DEL_SUB');
    NO_UPD_SUB = bnd.getErrorMsg('NO_UPD_SUB');
    setUp(tasks);
 }
 
 public void setUp(List<Task> tasks) {
    List <String> referenceCall = new List <String> ();
    for (Integer i = 0; i < tasks.size(); i++) {
    	String whatId = tasks[i].whatId;
    	boolean overrideFlag = isOverRideFlagTrue(tasks[i]);
    	
    	if (whatId != null && whatId.startsWith(Schema.SObjectType.Call2_vod__c.getKeyPrefix()) && !overrideFlag) {
        	referenceCall.add(tasks[i].WhatId);
    	}
    }
    calls = VOD_CALL2_CHILD_COMMON.getCallMap(referenceCall);    
 }
 
 public boolean isOverRideFlagTrue(Task task) {
   return (task.Override_Lock_vod__c == true);
 }
 
 public void setOverRideFlag(Task task, boolean flagSetTo) {     
     task.Override_Lock_vod__c = flagSetTo;          
 }
 
 public boolean isReferenceCallLocked(String whatId) {
   boolean isCallLocked = VOD_CALL2_CHILD_COMMON.isLocked(whatId, calls);   
   return isCallLocked;
 }
 
 public void setCallError(Task task, boolean isDelete) {
   if (isDelete) {
     task.whatId.addError(NO_DEL_SUB);
   }else {
     task.whatId.addError(NO_UPD_SUB);
   }
 }
 
 public void handleTask(boolean isDeleteTrigger, List<Task> tasks) {
 	
 	 for (Integer k = 0; k < tasks.size(); k++) {    
 	 	if (!isDeleteTrigger && isOverRideFlagTrue(tasks[K])) {
 	 		setOverRideFlag(tasks[k], false);            
            continue;
 	 	}
 	 	
 	 	if (isReferenceCallLocked(tasks[k].whatId)) {         
            if (isDeleteTrigger) {
            	setCallError(tasks[k], true);                
            } else {
            	setCallError(tasks[k], false);
            }
 	 	}
 	 }
 }
 
}