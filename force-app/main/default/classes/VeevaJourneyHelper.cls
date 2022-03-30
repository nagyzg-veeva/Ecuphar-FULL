public inherited sharing class VeevaJourneyHelper {
    /**
     * @description merge values in the source sobject into the target sobject
     * @param target the target sobject to merge to
     * @param source the source sobject to merged from
     * @return the target sobject after the merge
     */
    public static SObject assignSObject(SObject target, SObject source) {
        if (target == null || source == null) {
            return target;
        }
        Map<String, Object> sourceAsMap = source.getPopulatedFieldsAsMap();
        for (String fieldName : sourceAsMap.keySet()) {
            target.put(fieldName, sourceAsMap.get(fieldName));
        }
        return target;
    }

    /**
     * @description get the sobject type meta object from its object name
     * @param objectName the object name
     * @return the sobject type meta object or null if not found
     */
    public static Schema.SObjectType getObjectTypeByObjectName(String objectName) {
        Schema.SObjectType objectType = null;
        try {
            if (objectName != null && !String.isBlank(objectName)) {
                List<Schema.DescribeSObjectResult> results = Schema.describeSObjects(
                    new List<String> {objectName}
                );
                if (results != null && !results.isEmpty()) {
                    Schema.DescribeSObjectResult objectInfo = results.get(0);
                    if (objectInfo != null) {
                        objectType = objectInfo.getSobjectType();
                    }
                }
            }
        } catch (InvalidParameterValueException ex) {
            System.debug(LoggingLevel.ERROR, 'Cannot find the object type ' + objectName);
        }
        return objectType;
    }

    /**
     * @description expecting one result from the result set.
     * @param results the result set
     * @return the one result or null if not found. If there are more than one,
     *         an VeevaJourneyException with the exception type of EXPECT_ONE is thrown
     */
    public static SObject expectOneFromResults(List<SObject> results) {
        SObject ret = null;
        if (results != null && results.size() > 0) {
            if (results.size() > 1) {
                throw new VeevaJourneyException(VeevaJourneyException.Type.EXPECT_ONE);
            }
            ret = results.get(0);
        }
        return ret;
    }
}