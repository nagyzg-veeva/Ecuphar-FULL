/**
 * VeevaFilterUnsetFields - This class is responsible for filtering unset records given a list of fields to inspect and records.
 */
public inherited sharing class VeevaFilterUnsetFields {

    /**
     * Filters records from the argument newValues to a subset of records that have fieldsToInspect unset.
     * Unset means the value is not currently set or was set to null.
     *
     * The Map returned will be a reference of a SObject from newValues to a List of fields that are currently unset for the SObject
     * from the set of fieldsToInspect.
     */
    public Map<SObject, List<String>> filterRecordsWithUnsetValues(Set<String> fieldsToInspect, List<SObject> newValues) {
        Map<SObject, List<String>> unsetFieldsToInspectByRecord = new Map<SObject, List<String>>();

        for (Integer i = 0; i < newValues.size(); i++) {
            SObject objectWithNewValues = getSObjectAt(newValues, i);
            for (String field : fieldsToInspect) {
                addFieldForSObjectFieldIfUnset(unsetFieldsToInspectByRecord, field, objectWithNewValues);
            }
        }

        return unsetFieldsToInspectByRecord;
    }

    /**
     * Gets the SObject at the index from the list or returns null if list is null or if index does not exist.
     */
    private SObject getSObjectAt(List<SObject> objectList, Integer index) {
        SObject obj;
        if (objectList == null || index >= objectList.size()) {
            obj = null;
        } else {
            obj = objectList.get(index);
        }
        return obj;
    }

    private void addFieldForSObjectFieldIfUnset(Map<SObject,List<String>> unsetFieldsToInspectByRecord, String field, SObject objectWithNewValues) {
        if (isFieldUnset(field, objectWithNewValues)) {
            List<String> unsetTargetFields = unsetFieldsToInspectByRecord.get(objectWithNewValues);
            if (unsetTargetFields == null) {
                unsetTargetFields = new List<String>();
                unsetFieldsToInspectByRecord.put(objectWithNewValues, unsetTargetFields);
            }
            unsetTargetFields.add(field);
        }
    }

    /**
     * Check to see objectWithNewValues for field is currently not set.
     * Specifically, check objectWithNewValues for field is null.
     *
     * Returns true if the field is currently not trying to be set.
     */
    private boolean isFieldUnset(String field, SObject objectWithNewValues) {
        return objectWithNewValues.get(field) == null;
    }
}