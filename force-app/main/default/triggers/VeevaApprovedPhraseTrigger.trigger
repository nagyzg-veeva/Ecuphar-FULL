trigger VeevaApprovedPhraseTrigger on Approved_Phrase_vod__c(after update,before delete){
    List<Approved_Phrase_vod__c> aps = new List<Approved_Phrase_vod__c>();

    //Handle old data after update and before delete
    if(Trigger.isUpdate || Trigger.isDelete){
        aps.addAll(Trigger.old);
    }
    //Handle new data after update
    if(Trigger.isUpdate){
        aps.addAll(Trigger.new);
    }

    //Call clear phrase cache api
    VeevaContentPhraseTriggerHandler handler = new VeevaContentPhraseTriggerHandler();
    handler.clearPhraseCacheByAP(aps);
 }