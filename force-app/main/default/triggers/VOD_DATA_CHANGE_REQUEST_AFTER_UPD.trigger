/*
 * Used to keep the Status_vod__c of the child DCRs in sync with the parent
 */
trigger VOD_DATA_CHANGE_REQUEST_AFTER_UPD on Data_Change_Request_vod__c (after update) {
    List<Data_Change_Request_vod__c> statusChangedParents = new List<Data_Change_Request_vod__c>();
    Map<Id, String> statusByParentId = new Map<Id, String>();
    List<Id> dcrIds=new List<Id>();
    // Find parent DCRs with changed status
    for (Data_Change_Request_vod__c dcr : Trigger.new) {
        if (dcr.Parent_Data_Change_Request_vod__c == null) { // Parents only
            Data_Change_Request_vod__c oldDcr = Trigger.oldMap.get(dcr.Id);
            if (oldDcr.Status_vod__c != dcr.Status_vod__c) { // changed status only
                statusChangedParents.add(dcr);
                statusByParentId.put(dcr.Id, dcr.Status_vod__c);
                if(dcr.Status_vod__c=='Processed_vod'||dcr.Status_vod__c=='Cancelled_vod'){
                    dcrIds.add(dcr.Id);
                }
            }
        }
    }

    if (statusChangedParents.size() > 0) {
        // Find child DCRs to get status updated
        List<Data_Change_Request_vod__c> updatedList = new List<Data_Change_Request_vod__c>();
        List<Data_Change_Request_vod__c> subDcrs = 
            [select Id, Status_vod__c, Parent_Data_Change_Request_vod__c from Data_Change_Request_vod__c 
             where Parent_Data_Change_Request_vod__c IN :statusChangedParents];
        for (Data_Change_Request_vod__c subDcr : subDcrs) {
            // Only update if status does not already match - should be all, but maybe not
            String parentStatus = statusByParentId.get(subDcr.Parent_Data_Change_Request_vod__c);
            if (subDcr.Status_vod__c != parentStatus) {
                 subDcr.Status_vod__c = parentStatus;
                 updatedList.add(subDcr);
            }
        }
    
        if (updatedList.size() > 0) {
            update updatedList;
        }
    }
    
    if (dcrIds.size() > 0) {
        VeevaWeChatDataChangeRequestHandler weChatDcrHandler = new VeevaWeChatDataChangeRequestHandler();
        weChatDcrHandler.handleWeChatRelatedWork(dcrIds);
    }
}