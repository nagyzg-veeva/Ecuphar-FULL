trigger VEEVA_AFTER_ORDER_DELETE on Order_vod__c (after delete) {
    VeevaOrderTriggerHelper.deleteImRelatedRecords(Trigger.oldMap);
}