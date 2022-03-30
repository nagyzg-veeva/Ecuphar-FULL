public without sharing class VeevaEmEventTeamMemberTriggerHandler extends VeevaTriggerHandler{
    private List<EM_Event_Team_Member_vod__c> newEMEventTeamMembers;
    private List<EM_Event_Team_Member_vod__c> oldEMEventTeamMembers;
    private Map<ID, EM_Event_Team_Member_vod__c> newEMEventTeamMembersMap;
    private Map<ID, EM_Event_Team_Member_vod__c> oldEMEventTeamMembersMap;
    private VeevaEmTeamMemberBeforeInsertUpdateHdl beforeInsertUpdateHandler;
    private VeevaEmTeamMemberAfterInsertUpdateHdl afterInsertUpdateHandler;
    private VeevaEmTeamMemberAfterDeleteHdl afterDeleteHandler;
    private Map<String, String> errorMessageMap = new Map<String, String>();
    private String emMessageCategory = 'EVENT_MANAGEMENT';
    private String virtualEventOneHostAllowedMsgKey = emMessageCategory + ';;VIRTUAL_EVENT_ONE_HOST_ALLOWED';
    private String virtualEventLicenseRequiredMsgKey = emMessageCategory + ';;VIRTUAL_EVENT_LICENSE_REQUIRED';
    private String virtualEventLockHostMsgKey = emMessageCategory + ';;VIRTUAL_EVENT_LOCK_HOST';
    private String duplicateTeamMemberErrorMsgKey = emMessageCategory + ';;DUPLICATE_TEAM_MEMBER_ERROR';
    private String duplicateTeamMemberErrorGroupMsgKey = emMessageCategory + ';;DUPLICATE_TEAM_MEMBER_ERROR_GROUP';
    private String virtualEventOneHostAllowedMsgDefault = 'Only one Host is allowed per Event.';
    private String virtualEventLicenseRequiredMsgDefault = 'This Event Team Member does not have an Engage License available.';
    private String virtualEventLockHostMsgDefault = 'You are not allowed to update/delete the Host of a scheduled Engage event.';
    private String duplicateTeamMemberErrorMsgDefault = 'This person is already on the event team';
    private String duplicateTeamMemberErrorGroupMsgDefault = 'This group is already on the event team';


    protected override boolean doRecursionCheck() {
        return true;
    }

    protected override String sObjectType() {
        return 'EM_Event_Team_Member_vod__c';
    }

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newEMEventTeamMembers = (List<EM_Event_Team_Member_vod__c>) triggerNew;
        oldEMEventTeamMembers = (List<EM_Event_Team_Member_vod__c>) triggerOld;
        newEMEventTeamMembersMap = (Map<ID, EM_Event_Team_Member_vod__c>) triggerNewMap;
        oldEMEventTeamMembersMap = (Map<ID, EM_Event_Team_Member_vod__c>) triggerOldMap;
        // BeforeInsertUpdateHandler
        beforeInsertUpdateHandler = new VeevaEmTeamMemberBeforeInsertUpdateHdl(newEMEventTeamMembers,
                                                                                        oldEMEventTeamMembers,
                                                                                        newEMEventTeamMembersMap,
                                                                                        oldEMEventTeamMembersMap);
        // AfterInsertUpdateHandler
        afterInsertUpdateHandler = new VeevaEmTeamMemberAfterInsertUpdateHdl(newEMEventTeamMembers,
                                                                                       oldEMEventTeamMembers,
                                                                                       newEMEventTeamMembersMap,
                                                                                       oldEMEventTeamMembersMap);
        // AfterDeleteHandler
        afterDeleteHandler = new VeevaEmTeamMemberAfterDeleteHdl(newEMEventTeamMembers,
                                                                           oldEMEventTeamMembers,
                                                                           newEMEventTeamMembersMap,
                                                                           oldEMEventTeamMembersMap);
    }

    protected override void beforeInsert() {
        Set<String> associatedEvents = getAssociatedEventIds(newEMEventTeamMembers);
        List<EM_Event_vod__c> emEvents = getEmEvents(associatedEvents);
        eventLockCheckBeforeInsertUpdateDelete(emEvents);
        populateErrorMessageMap();
        List<EM_Event_Team_Member_vod__c> eventTeamMembers = getEventTeamMembers(associatedEvents);
        List<User> associatedUsers = getAssociatedUsers();
        // if new team member's Virtual_Role_vod__c has value, then validate alt host
        if(shouldValidateAltHostBeforeInsert()) {
            emEventTeamMemberAltHostValidationBeforeInsert(emEvents, eventTeamMembers, associatedUsers);
        }
        beforeInsertUpdateHandler.emEventTeamMemberBeforeInsertUpdate(errorMessageMap, eventTeamMembers, associatedUsers);
    }

    protected override void beforeUpdate() {
        Set<String> associatedEvents = getAssociatedEventIds(newEMEventTeamMembers);
        List<EM_Event_vod__c> emEvents = getEmEvents(associatedEvents);
        eventLockCheckBeforeInsertUpdateDelete(emEvents);
        populateErrorMessageMap();
        List<EM_Event_Team_Member_vod__c> eventTeamMembers = getEventTeamMembers(associatedEvents);
        List<User> associatedUsers = getAssociatedUsers();
        // if Virtual_Role_vod__c of new/old team member has value, then validate alt host
        if (shouldValidateAltHostBeforeUpdate()) {
            emEventTeamMemberAltHostValidationBeforeUpdate(emEvents, associatedUsers);
        }
        beforeInsertUpdateHandler.emEventTeamMemberBeforeInsertUpdate(errorMessageMap, eventTeamMembers, associatedUsers);
    }

    protected override void beforeDelete() {
        Set<String> associatedEvents = getAssociatedEventIds(oldEMEventTeamMembers);
        List<EM_Event_vod__c> emEvents = getEmEvents(associatedEvents);
        eventLockCheckBeforeInsertUpdateDelete(emEvents);
        // TODO if Virtual_Role_vod__c has value, then validate alt host !!
        if (shouldValidateAltHostBeforeDelete()) {
            populateErrorMessageMap();
            emEventTeamMemberAltHostValidationBeforeDelete(emEvents);
        }
    }

    protected override void afterInsert() {
        afterInsertUpdateHandler.emEventTeamMemberAfterInsertUpdate();
    }
    protected override void afterUpdate() {
        afterInsertUpdateHandler.emEventTeamMemberAfterInsertUpdate();
    }
    protected override void afterDelete() {
        afterDeleteHandler.emEventTeamMemberAfterDelete();
    }

    /*
    Method to get veeva messages.
    Note that in order to reduce SOQL queries to SFDC, use this method when necessary, and at the beginning of the process.
    */
    private void populateErrorMessageMap() {
        List<String> messageKeyList = new List<String>();
        messageKeyList.add(virtualEventOneHostAllowedMsgKey);
        messageKeyList.add(virtualEventLicenseRequiredMsgKey);
        messageKeyList.add(virtualEventLockHostMsgKey);
        messageKeyList.add(duplicateTeamMemberErrorMsgKey);
        messageKeyList.add(duplicateTeamMemberErrorGroupMsgKey);
        errorMessageMap = VOD_VEEVA_MESSAGE.getVeevaMessages(messageKeyList);
        if(errorMessageMap.get(virtualEventOneHostAllowedMsgKey) == null) {
            errorMessageMap.put(virtualEventOneHostAllowedMsgKey, virtualEventOneHostAllowedMsgDefault);
        }
        if(errorMessageMap.get(virtualEventLicenseRequiredMsgKey) == null) {
            errorMessageMap.put(virtualEventLicenseRequiredMsgKey, virtualEventLicenseRequiredMsgDefault);
        }
        if(errorMessageMap.get(virtualEventLockHostMsgKey) == null) {
            errorMessageMap.put(virtualEventLockHostMsgKey, virtualEventLockHostMsgDefault);
        }
        if(errorMessageMap.get(duplicateTeamMemberErrorMsgKey) == null) {
            errorMessageMap.put(duplicateTeamMemberErrorMsgKey, duplicateTeamMemberErrorMsgDefault);
        }
        if(errorMessageMap.get(duplicateTeamMemberErrorGroupMsgKey) == null) {
            errorMessageMap.put(duplicateTeamMemberErrorGroupMsgKey, duplicateTeamMemberErrorGroupMsgDefault);
        }
    }

    private void eventLockCheckBeforeInsertUpdateDelete(List<EM_Event_vod__c> emEvents) {// check locked events before CUD
        Set<String> lockedEvents = new Set<String>();

        for (EM_Event_vod__c event : emEvents) {
            if (VOD_Utils.isEventLocked(event)) {
                lockedEvents.add(event.Id);
            }
        }

        if(Trigger.isUpdate || Trigger.isInsert) {
            for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
                if(member.Override_Lock_vod__c == true) {
                    member.Override_Lock_vod__c = false;
                } else if (member.Event_vod__c != null && lockedEvents.contains(member.Event_vod__c)) {
                    member.addError('Event is locked');
                }
            }
        } else {
            VOD_EVENT_UTILS.addErrorToLockedEventChildObject(oldEMEventTeamMembers, lockedEvents);
        }
    }

    private void emEventTeamMemberAltHostValidationBeforeInsert(List<EM_Event_vod__c> emEvents, List<EM_Event_Team_Member_vod__c> eventTeamMembers,
                                                                List<User> associatedUsers) {
        // validate engage license for host and alt hosts
        validateEngageLicenseForHostAndAltHost(associatedUsers);
        // check there is no existing Host_vod EM_Event_Team_Member record. Only one team member can have Virtual_Role_vod "Host_vod"
        Set<String> associatedEvents = new Set<String>();
        for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
            if (member.Event_vod__c != null) {
                associatedEvents.add(member.Event_vod__c);
            }
        }
        Set<String> engageEnabledEvents = getEngageEnabledEvents(emEvents);

        Set<String> eventsWithExistingHost = new Set<String>();
        List<EM_Event_Team_Member_vod__c> hostEventTeamMembers = getHostEventTeamMembers(eventTeamMembers);
        for (EM_Event_Team_Member_vod__c hostTeamMember : hostEventTeamMembers) {// TODO can this be combined with line78 in beforeInsertUpdateHdl ??
            eventsWithExistingHost.add(hostTeamMember.Event_vod__c);
        }
        for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
            String virtualRole = member.Virtual_Role_vod__c;
            // Not allowed to add a host team member to
            // 1: an Engage enabled event OR
            // 2: an event that already has a host team member
            if ((engageEnabledEvents.contains(member.Event_vod__c) || eventsWithExistingHost.contains(member.Event_vod__c))
                && virtualRole != null && virtualRole.equals('Host_vod')) {
                String onlyOneHostAllowedError = errorMessageMap.get(virtualEventOneHostAllowedMsgKey);
                member.addError(onlyOneHostAllowedError);
            }
        }
    }

    private void emEventTeamMemberAltHostValidationBeforeUpdate(List<EM_Event_vod__c> emEvents, List<User> associatedUsers) {
        // validate engage license for host and alt hosts
        validateEngageLicenseForHostAndAltHost(associatedUsers);
        // 1. check whether engage is enabled, and Virtual_Role_vod is "Host_vod"
        // 2. if (1) is true, update on Team_Member_vod, Virtual_Role_vod is not allowed
        Set<String> engageEnabledEvents = getEngageEnabledEvents(emEvents);
        for(EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
            if(member.Event_vod__c != null) {
                // get associated EM_Event_vod__c, check webinar enablement
                if (engageEnabledEvents.contains(member.Event_vod__c)) {
                    // engage has been enabled for this event.
                    // Not allowed: 1. Host_vod team member changing the Virtual_Role_vod__c; 2. Host_vod team member changing Team_Member_vod__c
                    String oldVirtualRole = oldEMEventTeamMembersMap.get(member.Id).Virtual_Role_vod__c;
                    String newVirtualRole = newEMEventTeamMembersMap.get(member.Id).Virtual_Role_vod__c;
                    if((oldVirtualRole != null && oldVirtualRole.equals('Host_vod')) &&
                       (!oldVirtualRole.equals(newVirtualRole)
                      || !newEMEventTeamMembersMap.get(member.Id).Team_Member_vod__c.equals(oldEMEventTeamMembersMap.get(member.Id).Team_Member_vod__c))){
                        String updateDeleteNotAllowedError = errorMessageMap.get(virtualEventLockHostMsgKey);
                        member.addError(updateDeleteNotAllowedError);
                    }
                } else {
                    System.debug('Event associated with team member: ' + member.Id + ' is not Engage enabled yet.');
                }
            }
        }

    }

    private void emEventTeamMemberAltHostValidationBeforeDelete(List<EM_Event_vod__c> emEvents) {
        // 1. check whether engage is enabled, and Virtual_Role_vod is "Host_vod"
        // 2. if (1) is true, delete of "Host_vod" record is not allowed
        Set<String> engageEnabledEvents = getEngageEnabledEvents(emEvents);
        for(EM_Event_Team_Member_vod__c member : oldEMEventTeamMembers) {
            if(member.Event_vod__c != null) {
                // get associated EM_Event_vod__c, check webinar enablement
                if (engageEnabledEvents.contains(member.Event_vod__c)) {// engage has been enabled for this event. Deletion of Host_vod team member is not allowed.
                    String oldVirtualRole = oldEMEventTeamMembersMap.get(member.Id).Virtual_Role_vod__c;
                    if(oldVirtualRole != null && oldVirtualRole.equals('Host_vod')){
                        String updateNotAllowedErrorMsg = errorMessageMap.get(virtualEventLockHostMsgKey);
                        member.addError(updateNotAllowedErrorMsg);
                    }
                } else {
                    System.debug('Event associated with team member: ' + member.Id + ' is not Engage enabled yet.');
                }
            }
        }
    }

    private boolean shouldValidateAltHostBeforeInsert() {
        boolean result = false;
        for (EM_Event_Team_Member_vod__c newTeamMember : newEMEventTeamMembers) {
            String virtualRole = newTeamMember.Virtual_Role_vod__c;
            if ('Host_vod'.equals(virtualRole) || 'Alternative_Host_vod'.equals(virtualRole)) {
                result = true;
                break;
            }
        }
        return result;
    }

    private boolean shouldValidateAltHostBeforeUpdate() {
        boolean result = false;
        for (EM_Event_Team_Member_vod__c newTeamMember : newEMEventTeamMembers) {
            String virtualRole = newTeamMember.Virtual_Role_vod__c;
            if ('Host_vod'.equals(virtualRole) || 'Alternative_Host_vod'.equals(virtualRole)) {
                result = true;
                break;
            }
        }
        if (!result) {
            for (EM_Event_Team_Member_vod__c oldTeamMember : oldEMEventTeamMembers) {
                String virtualRole = oldTeamMember.Virtual_Role_vod__c;
                if ('Host_vod'.equals(virtualRole) || 'Alternative_Host_vod'.equals(virtualRole)) {
                    result = true;
                    break;
                }
            }
        }
        return result;
    }

    private boolean shouldValidateAltHostBeforeDelete() {
        boolean result = false;
        for (EM_Event_Team_Member_vod__c oldTeamMember : oldEMEventTeamMembers) {
            String virtualRole = oldTeamMember.Virtual_Role_vod__c;
            if ('Host_vod'.equals(virtualRole) || 'Alternative_Host_vod'.equals(virtualRole)) {
                result = true;
                break;
            }
        }
        return result;
    }

    private void validateEngageLicenseForHostAndAltHost(List<User> associatedUsers) {
        Set<String> usersWithValidEngageLicense = new Set<String>();
        for (User user : associatedUsers) {
             if (user.Remote_Meeting_Host_Id_vod__c != null && user.Remote_Meeting_Host_Token_vod__c != null) {
                usersWithValidEngageLicense.add(user.Id);
             }
        }
        for (EM_Event_Team_Member_vod__c newMember : newEMEventTeamMembers) {
            if((newMember.Virtual_Role_vod__c != null) &&
               (newMember.Virtual_Role_vod__c.equals('Host_vod') || newMember.Virtual_Role_vod__c.equals('Alternative_Host_vod')) &&
               !usersWithValidEngageLicense.contains(newMember.Team_Member_vod__c)){
                String remoteMeetingLicenseError = errorMessageMap.get(virtualEventLicenseRequiredMsgKey);
                newMember.addError(remoteMeetingLicenseError);
            }
        }
    }

    private List<User> getAssociatedUsers() {
        Set<String> userIds = new Set<String>();
        for (EM_Event_Team_Member_vod__c member : newEMEventTeamMembers) {
            if(member.Team_Member_vod__c != null) {
                userIds.add(member.Team_Member_vod__c);
            }
        }
        List<User> users = [SELECT Id, Remote_Meeting_Host_Id_vod__c, Remote_Meeting_Host_Token_vod__c, LastName, FirstName, Name
                            FROM User
                            WHERE Id IN :userIds];
        return users;
    }

    private Set<String> getEngageEnabledEvents(List<EM_Event_vod__c> emEvents) {
        Set<String> result = new Set<String>();
        Set<String> webinarStatusToCheck = new Set<String>();
        webinarStatusToCheck.add('Off_vod');
        webinarStatusToCheck.add('Failed_vod');
        for(EM_Event_vod__c event : emEvents) {
            if (event.Engage_Webinar_vod__c != null &&
                !('Off_vod'.equals(event.Webinar_Status_vod__c) || 'Failed_vod'.equals(event.Webinar_status_vod__c)) &&
                event.Engage_Webinar_vod__r.Scheduled_vod__c) {
                result.add(event.Id);
            }
        }
        return result;
    }

    private Set<String> getAssociatedEventIds(List<EM_Event_Team_Member_vod__c> emEventTeamMembers) {
        Set<String> associatedEvents = new Set<String>();
        for (EM_Event_Team_Member_vod__c member : emEventTeamMembers) {
            if (member.Event_vod__c != null) {
                associatedEvents.add(member.Event_vod__c);
            }
        }
        return associatedEvents;
    }

    private List<EM_Event_vod__c> getEmEvents(Set<String> associatedEvents) {
        List<EM_Event_vod__c> events = new List<EM_Event_vod__c>();
        events = [SELECT Id, Override_Lock_vod__c, Lock_vod__c,
                    Engage_Webinar_vod__c, Webinar_Status_vod__c, Engage_Webinar_vod__r.Scheduled_vod__c
                    FROM EM_Event_vod__c WHERE Id IN :associatedEvents];
        return events;
    }

    private List<EM_Event_Team_Member_vod__c> getEventTeamMembers(Set<String> associatedEvents) {
        List<EM_Event_Team_Member_vod__c> eventTeamMembers = new List<EM_Event_Team_Member_vod__c>();
        eventTeamMembers = [SELECT Id, Event_vod__c, Group_Name_vod__c, Team_Member_vod__c , Virtual_Role_vod__c
                            FROM EM_Event_Team_Member_vod__c
                            WHERE Event_vod__c IN :associatedEvents];
        return eventTeamMembers;
    }

    private List<EM_Event_Team_Member_vod__c> getHostEventTeamMembers(List<EM_Event_Team_Member_vod__c> emEventTeamMembers) {
        List<EM_Event_Team_Member_vod__c> hostEventTeamMembers = new List<EM_Event_Team_Member_vod__c>();
        for(EM_Event_Team_Member_vod__c emEventTeamMember : emEventTeamMembers) {
            if ('Host_vod'.equals(emEventTeamMember.Virtual_Role_vod__c)) {
                hostEventTeamMembers.add(emEventTeamMember);
            }
        }
        return hostEventTeamMembers;
    }

}