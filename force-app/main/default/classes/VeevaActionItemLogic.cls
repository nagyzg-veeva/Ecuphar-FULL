global without sharing class VeevaActionItemLogic {

    public static void actionItemStamping (List<Action_Item_vod__c> actionItems) {
        /** when the status pick list is set to completed then stamp the completed date and completed by
         *
          * */

        for (Action_Item_vod__c aItem : actionItems) {
            if (aItem.Status_vod__c == 'Completed_vod') {
                // stamp only if not already stamped to preserve the completed date and user to avoid sync problems from offline
                if (aItem.Completed_Date_vod__c  == null) {
                    aItem.Completed_Date_vod__c = Date.today();
                }
                if (aItem.Completed_By_vod__c  == null) {
                    aItem.Completed_By_vod__c = UserInfo.getUserId();
                }

            }
        }
    }

}