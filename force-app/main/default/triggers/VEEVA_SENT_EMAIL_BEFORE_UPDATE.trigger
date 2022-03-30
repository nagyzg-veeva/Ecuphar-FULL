trigger VEEVA_SENT_EMAIL_BEFORE_UPDATE on Sent_Email_vod__c (before update) {
    //Copy entity reference over to account lookup
    VOD_Utils.copyRefIdToLookup('Entity_Reference_Id_vod__c', 'Account_vod__c', Schema.Account.SObjectType, Trigger.New);

    //ordered enum of status values as they progress
    private enum EmailStatus{Scheduled_vod, Saved_vod, Pending_vod, Pending_Approval_vod, Approved_vod, Sent_vod,
                            Failed_vod, Delivered_vod, Dropped_vod, Bounced_vod, Marked_Spam_vod, Unsubscribed_vod, Group_vod, Rejected_vod}
    for(Sent_Email_vod__c newEmail: Trigger.new){
        String newStatus = newEmail.Status_vod__c;
        String oldStatus = Trigger.oldMap.get(newEmail.Id).Status_vod__c;
        EmailStatus newStatusE;
        EmailStatus oldStatusE;
        //go through and find the enum value for each status
        for(EmailStatus e: EmailStatus.values()){
            if(e.name() == newStatus){
                newStatusE = e;
            }
            if(e.name() == oldStatus){
                oldStatusE = e;
            }
        }
        //if this new status comes before the old status in our enum, keep the old status
        if(newStatusE.ordinal() < oldStatusE.ordinal()){
            newEmail.Status_vod__c = oldStatus;
        }
        //clear message when status is set to Sent or Delivered
        if(newEmail.Status_vod__c == EmailStatus.Sent_vod.name() || newEmail.Status_vod__c == EmailStatus.Delivered_vod.name()) {
            newEmail.Failure_Msg_vod__c = null;
        }
        //do not overwrite sent date if value already exists
        DateTime newSentDate = newEmail.Email_Sent_Date_vod__c;
        Datetime oldSentDate = Trigger.oldMap.get(newEmail.Id).Email_Sent_Date_vod__c;
        if (newSentDate == null && oldSentDate != null) {
            newEmail.Email_Sent_Date_vod__c = oldSentDate;
        }

        //error message if changing status from Pending_Approval to anything besides Approved_vod or Rejected_vod
        if (SentEmailHelper.isIncorrectReviewProcess(oldStatus, newStatus))  {
            newEmail.Status_vod__c = EmailStatus.Pending_Approval_vod.name();
            newEmail.addError(SentEmailHelper.buildErrorMessage('APP_EMAIL_PENDING_STATUS_CHANGE_ERROR', 'Pending Approval emails can only be Approved or Rejected.'));
        }

        //error message if user trying to update rejected status
        if (oldStatus == EmailStatus.Rejected_vod.name() && oldStatus != newStatus) {
            //rejected is at end of enum, so no need to manually set status
            newEmail.addError(SentEmailHelper.buildErrorMessage('APP_EMAIL_REJECTED_STATUS_CHANGE_ERROR', 'You cannot change the status of a rejected email.'));
        }
        SentEmailHelper.handleReviewEmails(newStatus, newEmail, datetime.now(), UserInfo.getUserId());
    }

    VeevaCountryHelper.updateCountryFields(Sent_Email_vod__c.getSObjectType(), Sent_Email_vod__c.OwnerId, Sent_Email_vod__c.Account_vod__c, Trigger.isUpdate, Trigger.new, Trigger.old);
}