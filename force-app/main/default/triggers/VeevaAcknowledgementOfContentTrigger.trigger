trigger VeevaAcknowledgementOfContentTrigger on Content_Acknowledgement_vod__c (before update) {
    // Iterate through triggers and determine logic
    for (Integer i = 0 ;  i < Trigger.new.size(); i++)  {
        // Check locking logic for
        if (Trigger.new[i].Unlock_vod__c == true){
            Trigger.new[i].Unlock_vod__c = false;
            continue;
        } else if (Trigger.old[i].Status_vod__c == 'Completed_vod') {
            Trigger.new[i].Status_vod__c.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('NO_UPD_SUB','TriggerError','You may not update a submitted call or any of the supporting data.'), false);
        }
    }
}