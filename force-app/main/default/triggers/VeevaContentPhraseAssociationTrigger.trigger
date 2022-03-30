trigger VeevaContentPhraseAssociationTrigger on Content_Phrase_Association_vod__c(after insert,after update,after delete){
    List<Content_Phrase_Association_vod__c> cpas = new List<Content_Phrase_Association_vod__c>();

    //Handle old data after update and after delete
    if(Trigger.isUpdate || Trigger.isDelete){
        cpas.addAll(Trigger.old);
    }

    //Handle new data after insert and after update
    if(Trigger.isInsert || Trigger.isUpdate){
        cpas.addAll(Trigger.new);
    }
    //Call clear phrase cache api
    VeevaContentPhraseTriggerHandler handler = new VeevaContentPhraseTriggerHandler();
    handler.clearPhraseCacheByCPA(cpas);
}