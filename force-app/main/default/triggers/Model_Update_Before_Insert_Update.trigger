trigger Model_Update_Before_Insert_Update on Model_Update_vod__c (before insert,before update) {
    List<String> nameList = new List<String>();
   
    for(Model_Update_vod__c modelUpdate: Trigger.new) {
        if (Trigger.isInsert) {
            if ( 'Active_vod' == modelUpdate.Status_vod__c ) {
                nameList.add(modelUpdate.Name);
            }
        } else {
            if ('Active_vod' == modelUpdate.Status_vod__c) {
                Model_Update_vod__c oModelUpdate = Trigger.oldMap.get(modelUpdate.Id);
                if ( 'Active_vod' != oModelUpdate.Status_vod__c ) {
                    nameList.add(modelUpdate.Name);
                }
            }
        }
    }
   
    if ( nameList.size() > 0 ) {
        List<Model_Update_vod__c> modelUpdateList = [select Id,Status_vod__c from Model_Update_vod__c where Status_vod__c='Active_vod' and Name in :nameList ];
        if ( modelUpdateList.size() >0 ) {
            for(Model_Update_vod__c modelUpdate: modelUpdateList) {
                modelUpdate.Status_vod__c='Inactive_vod';
            }
            update modelUpdateList;
        }
    }
}