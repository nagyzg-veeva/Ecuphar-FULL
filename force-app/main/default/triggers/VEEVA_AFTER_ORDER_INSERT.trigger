trigger VEEVA_AFTER_ORDER_INSERT on Order_vod__c (after insert) {

    VeevaOrderTriggerHelper.createImRelatedRecords(Trigger.newMap);

}