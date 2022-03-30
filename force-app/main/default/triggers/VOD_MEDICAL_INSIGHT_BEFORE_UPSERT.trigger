trigger VOD_MEDICAL_INSIGHT_BEFORE_UPSERT on Medical_Insight_vod__c (before update, before insert) {
    // check for the submitted error
    if (Trigger.isUpdate) {
        for (Medical_Insight_vod__c insight : Trigger.new) {
            Medical_Insight_vod__c oldInsight = Trigger.oldMap.get(insight.Id);
            if (insight.Override_Lock_vod__c == true) {
                insight.Override_Lock_vod__c = false;
                continue;
            }
            if (insight.Status_vod__c == 'Submitted_vod' && oldInsight.Status_vod__c == 'Submitted_vod') {
                insight.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('MEDICAL_INSIGHTS_NO_UPDATE_SUBMITTED', 'Medical', 'You may not update a submitted Key Medical Insight.'));
            }
        }
    }
    KMITriggerHandler kmiResWrd = new KMITriggerHandler();
    kmiResWrd.validateRestrictedWords(Trigger.new);

    VeevaCountryHelper.updateCountryFields(Medical_Insight_vod__c.getSObjectType(), Medical_Insight_vod__c.OwnerId, Medical_Insight_vod__c.Account_vod__c, Trigger.isUpdate, Trigger.new, Trigger.old);
}