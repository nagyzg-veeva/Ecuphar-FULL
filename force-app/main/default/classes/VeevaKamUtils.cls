public without sharing class VeevaKamUtils {

    public static boolean isVeevaAccountPlanShareEnabled() {
        Veeva_Settings_vod__c vsc = Veeva_Settings_vod__c.getOrgDefaults();
        if(vsc == null || vsc.Account_Plan_Sharing_vod__c == null || vsc.Account_Plan_Sharing_vod__c.intValue() != 1) {
            return false;
        }
        return true;
    }


    public static void updateInactiveUserIds(Set<Id> userIds, Set<Id> checkedIds, Set<Id> inactiveIds) {
        userIds.removeAll(checkedIds);
        if (userIds.size() > 0) {
            Map<Id, User> userObjectsMap = new Map<Id, User>([SELECT Id, IsActive FROM User WHERE IsActive = FALSE AND Id IN :userIds]);
            inactiveIds.addAll(userObjectsMap.keySet());
        }
        checkedIds.addAll(userIds);
    }


}