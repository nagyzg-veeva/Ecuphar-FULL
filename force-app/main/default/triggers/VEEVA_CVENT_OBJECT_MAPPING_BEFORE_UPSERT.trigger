trigger VEEVA_CVENT_OBJECT_MAPPING_BEFORE_UPSERT on Cvent_Object_Mapping_vod__c (before insert, before update) {
    for (Cvent_Object_Mapping_vod__c mapping : Trigger.new) {
        List<String> keyValues = new List<String>{mapping.Cvent_Instance_vod__c,mapping.Cvent_Object_Name_vod__c,
            mapping.Salesforce_Object_Name_vod__c};
        mapping.Unique_Key_vod__c = String.join(keyValues,':');
    }
}