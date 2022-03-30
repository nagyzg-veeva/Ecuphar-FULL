public without sharing class VeevaRemoteMeetingTriggerHandler {

    public VeevaRemoteMeetingTriggerHandler() {
    }

    public void onBeforeUpdate(List<Remote_Meeting_vod__c> newRemoteMeetings, List<Remote_Meeting_vod__c> oldRemoteMeetings,
                               Map<ID, Remote_Meeting_vod__c> newRemoteMeetingsMap, Map<ID, Remote_Meeting_vod__c> oldRemoteMeetingsMap) {

        Map<Id, Remote_Meeting_vod__c> remoteMeetingsMap = new Map<Id, Remote_Meeting_vod__c>([SELECT Id, Scheduled_vod__c FROM Remote_Meeting_vod__c WHERE Id IN :newRemoteMeetingsMap.keySet()]);

        for (Remote_Meeting_vod__c newRemoteMeeting : newRemoteMeetings) {
            Remote_Meeting_vod__c oldRemoteMeeting = oldRemoteMeetingsMap.get(newRemoteMeeting.Id);

            if (remoteMeetingsMap.get(newRemoteMeeting.Id).Scheduled_vod__c == true && String.isNotBlank(oldRemoteMeeting.Assigned_Host_vod__c)
                    && !oldRemoteMeeting.Assigned_Host_vod__c.equals(newRemoteMeeting.Assigned_Host_vod__c)) {
                newRemoteMeeting.addError('You cannot change the host for an already scheduled webinar.');
            }
        }

        VeevaCountryHelper.updateCountryFields(Remote_Meeting_vod__c.getSObjectType(), Remote_Meeting_vod__c.OwnerId, null, true, newRemoteMeetings, oldRemoteMeetings);
    }

    public void onBeforeInsert(List<Remote_Meeting_vod__c> newRemoteMeetings, List<Remote_Meeting_vod__c> oldRemoteMeetings,
                               Map<ID, Remote_Meeting_vod__c> newRemoteMeetingsMap, Map<ID, Remote_Meeting_vod__c> oldRemoteMeetingsMap) {

        VeevaCountryHelper.updateCountryFields(Remote_Meeting_vod__c.getSObjectType(), Remote_Meeting_vod__c.OwnerId, null, false, newRemoteMeetings, oldRemoteMeetings);
    }
}