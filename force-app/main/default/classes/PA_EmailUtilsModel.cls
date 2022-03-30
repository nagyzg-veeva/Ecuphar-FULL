global with sharing class PA_EmailUtilsModel {

    global static void sendExceptionEmailToAdmin(String subjectEmail, String apexFailedClass, Exception e){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        // Set recipients to two contact IDs.
        // Replace IDs with valid record IDs in your org.
        message.toAddresses = General_Settings__c.getInstance('Standard').Email_admin__c.split(';');
        message.subject = subjectEmail;
        message.plainTextBody = apexFailedClass + ' had an exception while executing.\nLine '+e.getLineNumber()+' Exception Message: '+e.getmessage();
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }

global static void sendEmailToAdmin(String subjectEmail, String bodyEmail){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        // Set recipients to two contact IDs.
        // Replace IDs with valid record IDs in your org.
        message.toAddresses = General_Settings__c.getInstance('Standard').Email_admin__c.split(';');
        message.subject = subjectEmail;
        message.plainTextBody = bodyEmail;
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
}

}