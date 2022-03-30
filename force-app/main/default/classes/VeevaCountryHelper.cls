/**
 * VeevaCountryHelper - Updates Country_User_vod__c and/or Country_Account_vod__c fields for a given list of objects.
 */
public without sharing class VeevaCountryHelper {

    /**
     * Updates the country fields using userCountryReferenceField and/or accountCountryReferenceField and updates
     * the objectsWithNewValues list by setting the country fields. 
     */
    public static void updateCountryFields(Schema.SObjectType sObjectType, Schema.SObjectField userCountryReferenceField, Schema.SObjectField accountCountryReferenceField,
                                            boolean isUpdate, List<SObject> objectsWithNewValues, List<SObject> objectsWithOldValues) {
        Veeva_Settings_vod__c orgLevelVeevaSettings = Veeva_Settings_vod__c.getOrgDefaults();
        if (orgLevelVeevaSettings.Enable_Country_Dimension_vod__c == 1) {
            Map<String, Schema.SObjectField> targetToSourceReferenceFieldMappings = createTargetToSourceMappings(userCountryReferenceField, accountCountryReferenceField);

            VeevaFilterUnsetFields filterUnset = new VeevaFilterUnsetFields();
            Set<String> targetFieldsToInspect = targetToSourceReferenceFieldMappings.keySet();
            Map<SObject, List<String>> recordsToUpdateTargetFields = filterUnset.filterRecordsWithUnsetValues(targetFieldsToInspect, objectsWithNewValues);

            if (!recordsToUpdateTargetFields.isEmpty()) {
                updateCountryFieldsForRecordsWithUnsetTargetFields(sObjectType, isUpdate, targetToSourceReferenceFieldMappings, recordsToUpdateTargetFields, objectsWithOldValues);
            }
        }
    }

    private static Map<String, Schema.SObjectField> createTargetToSourceMappings(Schema.SObjectField userCountryReferenceField, Schema.SObjectField accountCountryReferenceField) {
        Map<String, Schema.SObjectField> targetToSourceReferenceFieldMappings = new Map<String, Schema.SObjectField>();
        if (userCountryReferenceField != null) {
            targetToSourceReferenceFieldMappings.put('Country_User_vod__c', userCountryReferenceField);
        }
        if (accountCountryReferenceField != null) {
            targetToSourceReferenceFieldMappings.put('Country_Account_vod__c', accountCountryReferenceField);
        }
        return targetToSourceReferenceFieldMappings;
    }

    private static void updateCountryFieldsForRecordsWithUnsetTargetFields(Schema.SObjectType sObjectType, boolean isUpdate, Map<String, Schema.SObjectField> targetToSourceReferenceFieldMappings,
                                                                            Map<SObject,List<String>> recordsToUpdateTargetFields, List<SObject> recordsWithOldValues) {
        List<SObject> recordsToUpdate = new List<SObject>(recordsToUpdateTargetFields.keySet());
        List<Schema.SObjectField> sourceReferenceFields = targetToSourceReferenceFieldMappings.values();
        VeevaQueryReferenceFieldStrategy queryStrategy = pickStrategy(sObjectType, isUpdate, sourceReferenceFields, recordsToUpdate, recordsWithOldValues);
        VeevaCountryQueryBuilder queryBuilder = new VeevaCountryQueryBuilder(queryStrategy);
        addSourceReferenceFieldsToBuilder(sourceReferenceFields, queryBuilder);
        VeevaQueryResultMap queryResult = queryBuilder.buildQueryResultWith(recordsToUpdate);

        VeevaCountryFieldMapper fieldMapper = new VeevaCountryFieldMapper(targetToSourceReferenceFieldMappings);
        fieldMapper.performMappingOnRecordsToUpdate(recordsToUpdateTargetFields, queryResult);
    }

    private static void addSourceReferenceFieldsToBuilder(List<Schema.SObjectField> sourceReferenceFields, VeevaCountryQueryBuilder queryBuilder) {
        for (Schema.SObjectField sourceReferenceField : sourceReferenceFields) {
            queryBuilder.addSourceReferenceFieldToQuery(sourceReferenceField);   
        }
    }

    private static VeevaQueryReferenceFieldStrategy pickStrategy(Schema.SObjectType sObjectType, boolean isUpdate, List<Schema.SObjectField> sourceReferenceFieldsToInspect,
                                                                    List<SObject> recordsWithNewValuesToUpdate, List<SObject> recordsWithOldValues) {
        // we want to ignore references to Group
        List<Schema.SObjectType> objectReferencesToIgnore = new List<Schema.SObjectType>{Group.getSObjectType()};
        Map<Id, SObject> idToRecordMapForNewValues = createIdToRecordMap(recordsWithNewValuesToUpdate);
        Map<Id, SObject> idToRecordMapForOldValues = createIdToRecordMap(recordsWithOldValues);
        VeevaQueryReferenceFieldStrategy queryStrategy;
        if (isUpdate && !haveAnySourceReferenceFieldsBeenUpdated(sourceReferenceFieldsToInspect, idToRecordMapForNewValues, idToRecordMapForOldValues)) {
            queryStrategy = new VeevaQueryFromRecordStrategy(sObjectType);
        } else {
            queryStrategy = new VeevaQueryReferenceObjectStrategy(objectReferencesToIgnore);
        }
        return queryStrategy;
    }

    private static boolean haveAnySourceReferenceFieldsBeenUpdated(List<Schema.SObjectField> sourceReferenceFieldsToInspect, Map<Id, SObject> recordsToUpdateWithNewValues, Map<Id, SObject> recordsWithOldValues) {
        boolean anySourceReferenceFieldsUpdated = false;
        Iterator<Id> recordsToUpdateWithNewValuesIterator = recordsToUpdateWithNewValues.keySet().iterator();

        while (!anySourceReferenceFieldsUpdated && recordsToUpdateWithNewValuesIterator.hasNext()) {
            Id recordId = recordsToUpdateWithNewValuesIterator.next();
            SObject recordToUpdateWithNewValues = recordsToUpdateWithNewValues.get(recordId);
            SObject recordToUpdateWithOldValues = recordsWithOldValues.get(recordId);
            anySourceReferenceFieldsUpdated = anySourceReferenceFieldsUpdatedForRecord(sourceReferenceFieldsToInspect, recordToUpdateWithNewValues, recordToUpdateWithOldValues);
        }

        return anySourceReferenceFieldsUpdated;
    }

    private static boolean anySourceReferenceFieldsUpdatedForRecord(List<Schema.SObjectField> sourceReferenceFieldsToInspect, SObject recordWithNewValues, SObject recordWithOldValues) {
        boolean anySourceReferenceFieldsUpdated = false;
        Integer sourceFieldIndex = 0;
        while (!anySourceReferenceFieldsUpdated && sourceFieldIndex < sourceReferenceFieldsToInspect.size()) {
            Schema.SObjectField sourceReferenceField = sourceReferenceFieldsToInspect.get(sourceFieldIndex);
            anySourceReferenceFieldsUpdated = recordWithNewValues.get(sourceReferenceField) != recordWithOldValues.get(sourceReferenceField);
            sourceFieldIndex++;
        }
        return anySourceReferenceFieldsUpdated;
    }

    private static Map<Id, SObject> createIdToRecordMap(List<SObject> records) {
        Map<Id, SObject> idToRecords = new Map<Id, SObject>();
        if (records != null) {
            for (SObject record : records) {
                if (record.Id != null) {
                    idToRecords.put(record.Id, record);
                }
            }
        }
        return idToRecords;
    }
}