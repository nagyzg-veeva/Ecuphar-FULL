public inherited sharing class VeevaCountryFieldMapper {

    private Map<String, Schema.SObjectField> targetFieldMappings;

    public VeevaCountryFieldMapper(Map<String, Schema.SObjectField> targetFieldMappings) {
        this.targetFieldMappings = targetFieldMappings;
    }

    /**
     * An update will occur against the map of SObjects to target fields to update using the VeevaQueryResultMap. Specifically,
     * the keys in the targetFieldsToUpdateByRecord will be updated by this call using the targetFieldMappings and the values in
     * the VeevaQueryResultMap.
     *
     * Note: The reason we use SObject as the key is because we do not have any unique fields for all SObjects during an insert from a Trigger.
     * Since the keys are SObjects it is important to that VeevaQueryResultMap should contain the same SObject keys. This means that no modifications
     * should have been made prior to this method call against these SObjects. If a modification was made against the SObject prior to this method
     * call the desired behavior of this method will fail.
     */
    public void performMappingOnRecordsToUpdate(Map<SObject, List<String>> targetFieldsToUpdateByRecord, VeevaQueryResultMap queryResultWithSourceFieldValues) {
        if (hasTargetMappings() && hasTargetFieldsToBeUpdated(targetFieldsToUpdateByRecord)) {
            Set<SObject> recordsToUpdate = targetFieldsToUpdateByRecord.keySet();
            for (SObject recordToUpdate : recordsToUpdate) {
                List<String> targetFieldsToUpdate = targetFieldsToUpdateByRecord.get(recordToUpdate);
                Map<String, Object> valuesByTargetField = getValuesByTargetFieldFromQueryResult(targetFieldsToUpdate, queryResultWithSourceFieldValues, recordToUpdate);

                // we can only update the recordToUpdate once, if we make any modifications to recordToUpdate
                // while reading from queryResult we will not be able to retrieve all values for all target fields
                for (String targetFieldToUpdate : valuesByTargetField.keySet()) {
                    Object value = valuesByTargetField.get(targetFieldToUpdate);
                    recordToUpdate.put(targetFieldToUpdate, value);
                }
            }
        }
    }

    private boolean hasTargetMappings() {
        return targetFieldMappings != null && !targetFieldMappings.isEmpty();
    }

    private boolean hasTargetFieldsToBeUpdated(Map<SObject,List<String>> targetFieldsToUpdateByRecord) {
        return targetFieldsToUpdateByRecord != null && !targetFieldsToUpdateByRecord.isEmpty();
    }

    private Map<String, Object> getValuesByTargetFieldFromQueryResult(List<String> targetFieldsToUpdate, VeevaQueryResultMap queryResultWithSourceFieldValues, SObject recordKey) {
        Map<String, Object> valuesByTargetField = new Map<String, Object>();
        for (String targetFieldToUpdate : targetFieldsToUpdate) {
            Schema.SObjectField sourceReferenceField = targetFieldMappings.get(targetFieldToUpdate);
            Object value = queryResultWithSourceFieldValues.get(sourceReferenceField, recordKey);
            valuesByTargetField.put(targetFieldToUpdate, value);
        }
        return valuesByTargetField;
    }
}