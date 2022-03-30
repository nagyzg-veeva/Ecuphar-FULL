public inherited sharing class VeevaUserTriggerHandler extends VeevaTriggerHandler {
    private List<User> oldUsers = new List<User>();
    private List<User> newUsers = new List<User>();
    private Map<ID, User> oldUsersMap = new Map<ID, User>();
    private Map<ID, User> newUsersMap = new Map<ID, User>();

    @testVisible protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newUsers = (List<User>) triggerNew;
        this.oldUsers = (List<User>) triggerOld;
        this.newUsersMap = (Map<ID, User>) triggerNewMap;
        this.oldUsersMap = (Map<ID, User>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'User';
    }

    private boolean isConnectCustomer() {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        if( settings == null ) {
            return false;
        }
        String url = settings.Engage_Connect_Server_vod__c;
        return url != null && url != '';
    }

    protected override void afterInsert() {
        if (isConnectCustomer()) {
            Set<ID> groupChange = new Set<ID>();
            Set<ID> otherChange = new Set<ID>();
            if (filterConnectRelevantUsers(true, groupChange, otherChange)) {
	            VeevaEngageConnectUserActions.passUsersToConnectServer(groupChange, otherChange);
            }
        }
    }

    protected override void afterUpdate() {
        if (isConnectCustomer()) {
            Set<ID> groupChange = new Set<ID>();
            Set<ID> otherChange = new Set<ID>();
            if (filterConnectRelevantUsers(false, groupChange, otherChange)) {
	            VeevaEngageConnectUserActions.passUsersToConnectServer(groupChange, otherChange);
            }
        }
    }

    private List<String> changedConnectRelevantFields(ID userId) {
        List<String> delta = new List<String>();
        User oldUser = oldUsersMap.get(userId);
        User newUser = newUsersMap.get(userId);
        if (newUser.Engage_Connect_Group_Request_vod__c != oldUser.Engage_Connect_Group_Request_vod__c) {
            delta.add('request');
        }
        if (newUser.Engage_Connect_Group_Status_vod__c != oldUser.Engage_Connect_Group_Status_vod__c &&
            newUser.Engage_Connect_Group_Status_vod__c == 'Retry_Request_vod') {
            delta.add('status');
        }
        if (newUser.Email != oldUser.Email) {
            delta.add('email');
        }
        if(newUser.User_Type_vod__c != oldUser.User_Type_vod__c) {
            delta.add('type');
        }
        if(newUser.IsActive != oldUser.IsActive) {
            delta.add('active');
        }
        return delta;
    }

    @testVisible private boolean filterConnectRelevantUsers(boolean isInsertEvent, Set<ID> groupChange, Set<ID> otherChange) {
        for (User newUser: newUsers) {
            if (isInsertEvent) {
                if (newUser.Engage_Connect_Group_Request_vod__c != null) {
                    groupChange.add(newUser.ID);
                }
            }
            else {
                List<String> delta = changedConnectRelevantFields(newUser.ID);
                if (delta.size() == 0) { // no relevant changes, ignore
                    continue;
                }
                if (delta.contains('status') || delta.contains('request')) {
                    groupChange.add(newUser.ID);
                }
                else if (newUser.Engage_Connect_Group_vod__c != null) { // don't communicate other changes if group is null && status != retry
                    otherChange.add(newUser.ID);
                }
            }
        }
        return groupChange.size() > 0 || otherChange.size() > 0;
    }
}