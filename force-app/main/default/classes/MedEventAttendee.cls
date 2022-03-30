public with sharing class MedEventAttendee {

    @AuraEnabled
    public static List<String> getMedEventAttendees(String medEventId) {
        String query = 'SELECT Account_vod__c, (SELECT Account_vod__c FROM Medical_Event_vod__c.Event_Attendee_vod__r WHERE Account_vod__c != null) ' + 
                'FROM Medical_Event_vod__c WHERE Id = :medEventId';
        
        List<String> accountIds = new List<String>();

        Medical_Event_vod__c medEvent = Database.query(query);
        accountIds.add(medEvent.Account_vod__c);
        for (Event_Attendee_vod__c eventAttendee : medEvent.Event_Attendee_vod__r) {
            accountIds.add(eventAttendee.Account_vod__c);
        }

        return accountIds;
    }
}