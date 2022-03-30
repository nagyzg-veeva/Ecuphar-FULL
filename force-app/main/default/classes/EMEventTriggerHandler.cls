/*
 * This class is meant to hold the call to the AdHocSyncProcess for QR Sign-In. Current implementation has syncEvents()
 * called from triggers/VOD_EM_EVENT_AFTER_INS_UPD.trigger for events with name change only and in classes/VOD_EVENT_UTILS.cls
 * for roll-up called by changes to event attendees and event speakers. Be careful to move calls to this method,
 * VeevaQRSignInSync.callAdHocSyncProcess() has a callout with a future annotation that can cause errors if already in a
 * future context from a previous class.
 * See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_future.htm
 */

public class EMEventTriggerHandler{

    public static void syncEvents(List<EM_Event_vod__c> events){
        Set<String> objectFields = Schema.SObjectType.EM_Event_vod__c.fields.getMap().keySet();
        if(objectFields.contains('qr_sign_in_enabled_vod__c')){
        	Set<Id> eventIds = new Set<Id>();

            List<EM_Event_vod__c> eventsQRDefined = [SELECT Id
                                                     FROM EM_Event_vod__c
                                                     WHERE Id IN :events and QR_Sign_In_Enabled_vod__c = 'Yes_vod'];

            for(EM_Event_vod__c event: eventsQRDefined){
                eventIds.add(event.Id);
            }

            if (eventIds.size() > 0 && !(System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled())) {
                VeevaQRSignInSync adHocJob = new VeevaQRSignInSync(eventIds);
                System.enqueueJob(adHocJob);
            }
        }
    }
}