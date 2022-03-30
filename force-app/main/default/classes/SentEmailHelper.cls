public class SentEmailHelper {

    private enum EmailStatus{Scheduled_vod, Saved_vod, Pending_vod, Pending_Approval_vod, Approved_vod, Sent_vod,
                                Failed_vod, Delivered_vod, Dropped_vod, Bounced_vod, Marked_Spam_vod, Unsubscribed_vod, Group_vod, Rejected_vod}

    public static String buildErrorMessage(String messageName, String defaultErrorText) {
        List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name=:messageName AND Category_vod__c='ApprovedEmail' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
        String errorText;
        if(messages.size() != 0){
            errorText = messages[0].Text_vod__c;
        } else { // default to english hardcoded
            errorText = defaultErrorText;
        }
        return errorText;
    }

    public static void handleReviewEmails(String status, Sent_Email_vod__c email, DateTime now, String userId) {
        if (status == 'Approved_vod') {
            //stamp Review_Datetime_vod__c and Reviewer_vod__c for Approved/Rejected emails
            if (email.Review_Datetime_vod__c == null) {
                email.Review_Datetime_vod__c = now;
            }
            if (email.Reviewer_vod__c == null) {
                email.Reviewer_vod__c = userId;
            }
            //if email has scheduled send datetime, make it scheduled status. Otherwise put in Saved status
            if (email.Scheduled_Send_Datetime_vod__c != null) {
                email.Status_vod__c = 'Scheduled_vod';
            } else {
                email.Status_vod__c = 'Saved_vod';
            }
        }

        if (status == 'Rejected_vod') {
            //stamp Review_Datetime_vod__c and Reviewer_vod__c for Approved/Rejected emails
            if (email.Review_Datetime_vod__c == null) {
                email.Review_Datetime_vod__c = now;
            }
            if (email.Reviewer_vod__c == null) {
                email.Reviewer_vod__c = userId;
            }
        }
    }

    public static boolean isIncorrectReviewProcess(String oldStatus, String newStatus) {
        return oldStatus == EmailStatus.Pending_Approval_vod.name() && (newStatus != EmailStatus.Approved_vod.name() && newStatus  != EmailStatus.Rejected_vod.name() && newStatus != EmailStatus.Pending_Approval_vod.name());
    }
}