public without sharing class VeevaDynAttrConfigActions {

    private static final String multiSelectLengthError = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('CHARACTER_LIMIT', 'COMMON', 'Each entry cannot exceed {0} characters');
    
    public static void checkChanges(List<Dynamic_Attribute_Configuration_vod__c> originalDAConfig,
                               List<Dynamic_Attribute_Configuration_vod__c> newDAConfig) {
        SObjectType schemaMap = Schema.getGlobalDescribe().get('Dynamic_Attribute_Configuration_vod__c');
        Map<String, Schema.SObjectField> fieldMap = schemaMap.getDescribe().fields.getMap();
        List<Schema.SObjectField> dacFields = fieldMap.values();
        List<String> dacFieldNames = new List <String> ();
        for (Schema.SObjectField sObjectFields : dacFields){
            dacFieldNames.add(sObjectFields.getDescribe().getName());
        }
        for (Integer i = 0; i < originalDAConfig.size(); i++){
            Dynamic_Attribute_Configuration_vod__c originalConfig = originalDAConfig.get(i);
            Dynamic_Attribute_Configuration_vod__c newConfig = newDAConfig.get(i);

            if ((originalConfig.RecordTypeId != newConfig.RecordTypeId)){
                newConfig.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('RECORD_TYPE_NOT_MODIFIABLE', 'Common',
                    '\'Record Type\' cannot be modified for any Dynamic Attribute Configuration records.'));
            }

            if ('Active_vod'.equals(originalConfig.Status_vod__c)) {
                for (String field : dacFieldNames){
                    if (newConfig.get(field) != originalConfig.get(field) && !(field.equals('Status_vod__c'))){
                        newConfig.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('ACTIVE_NOT_MODIFIABLE', 'COMMON',
        	                'Record cannot be modified while \'Status\' is set to \'Active\'.'));
                    }
                }
            }
        }
    }

    public static void checkMultiSelectPicklistLength(List<Dynamic_Attribute_Configuration_vod__c> newDAConfigs) {
        Map<Id, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Dynamic_Attribute_Configuration_vod__c.getRecordTypeInfosById();
        for (Dynamic_Attribute_Configuration_vod__c daConfig: newDAConfigs) {
            Schema.RecordTypeInfo recordTypeIdInfo = recordTypes.containsKey(daConfig.RecordTypeId) ? recordTypes.get(daConfig.RecordTypeId) : null;
            if (recordTypeIdInfo != null && recordTypeIdInfo.getDeveloperName().equals('Multi_Select_Picklist_vod')) {
                String[] availableValues = daConfig.Available_Values_vod__c.split(';;');
                for (String value : availableValues) {
                    value = value.replace('\n', '').replace('\r', '');
                    if (value.length() > 255) {
                        daConfig.Available_Values_vod__c.addError(String.format(multiSelectLengthError, new String[]{'255'}));
                    }
                }
            }
        }
    }
}