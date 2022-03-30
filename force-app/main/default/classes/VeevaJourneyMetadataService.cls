public inherited sharing class VeevaJourneyMetadataService {
    /**
     * @description Get the picklist of an object field
     * @param objectName The object type name
     * @param fieldName The object field name that the picklist belongs to
     * @param activeOnly The activeness of the picklist item
     * @return The picklist of the object field
     */
    public List<Schema.PicklistEntry> findPicklistByObjectField(
        String objectName,
        String fieldName,
        Boolean activeOnly
    ) {
        if (String.isBlank(objectName)) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.INVALID_PARAM,
                new List<Object> {'objectName', objectName}
            );
        }
        if (String.isBlank(fieldName)) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.INVALID_PARAM,
                new List<Object> {'fieldName', fieldName}
            );
        }

        Schema.SObjectType objectType = VeevaJourneyHelper.getObjectTypeByObjectName(objectName);
        if (objectType == null) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_DATA_FOUND,
                new List<Object> {'object type', objectName}
            );
        }

        Schema.SObjectField field = objectType.getDescribe().Fields.getMap().get(fieldName);
        if (field == null) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_DATA_FOUND,
                new List<Object> {'field', fieldName}
            );
        }

        List<Schema.PicklistEntry> picklist = field.getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> filteredList = new List<Schema.PicklistEntry>();
        Boolean hasFilter = activeOnly;
        // iterate the list only when there are filters
        if (hasFilter) {
            for (Schema.PicklistEntry entry : picklist) {
                if (activeOnly && entry.isActive()) {
                    filteredList.add(entry);
                }
            }
        }

        return hasFilter ? filteredList : picklist;
    }

    /**
     * @description Get the paginated picklist of an object field
     * @param objectName The object type name
     * @param fieldName The object field name that the picklist belongs to,
     * @param pageOptions
     * @param activeOnly The activeness of the picklist item
     * @return The paginated picklist of the object field
     */
    public VeevaJourneyPageInfo findPaginatedPicklistByObjectField(
        String objectName,
        String fieldName,
        VeevaJourneyPageOptions pageOptions,
        Boolean activeOnly
    ) {
        List<Schema.PicklistEntry> picklist = findPicklistByObjectField(objectName, fieldName, activeOnly);
        List<Schema.PicklistEntry> paginatedPicklist = new List<Schema.PicklistEntry>();
        Integer startIdx = pageOptions.getPageSize() * pageOptions.getPage();
        Integer endIdx = pageOptions.getPageSize() * (pageOptions.getPage() + 1) - 1;

        for (Integer idx = startIdx; idx <= endIdx; idx++) {
            paginatedPicklist.add(picklist.get(idx));
        }

        return new VeevaJourneyPageInfo(pageOptions, picklist.size(), paginatedPicklist);
    }

    /**
     * @description Get the list of the record types of an object
     * @param objectName The object type name
     * @param activeOnly The activeness of the record types
     * @return the list of the record types of an object
     */
    public List<Schema.RecordTypeInfo> findRecordTypesByObjectType(String objectName, Boolean activeOnly) {
        if (String.isBlank(objectName)) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.INVALID_PARAM,
                new List<Object> {'objectName', objectName}
            );
        }

        Schema.SObjectType objectType = VeevaJourneyHelper.getObjectTypeByObjectName(objectName);
        if (objectType == null) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_DATA_FOUND,
                new List<Object> {'object type', objectName}
            );
        }

        List<Schema.RecordTypeInfo> recordTypes = objectType.getDescribe().getRecordTypeInfos();
        List<Schema.RecordTypeInfo> filtered = new List<Schema.RecordTypeInfo>();
        for (Schema.RecordTypeInfo recordType : recordTypes) {
            if (
                recordType.getDeveloperName() != 'Master' &&
                (
                    activeOnly && recordType.isActive() ||
                    !activeOnly
                )
            ) {
                filtered.add(recordType);
            }
        }

        return filtered;
    }
}