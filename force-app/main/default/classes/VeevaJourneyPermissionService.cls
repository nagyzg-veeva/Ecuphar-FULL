public inherited sharing class VeevaJourneyPermissionService {
    private static final String OPERATION_READ = 'read';
    private static final String OPERATION_CREATE = 'create';
    private static final String OPERATION_UPDATE = 'update';
    private static final String OPERATION_DELETE = 'delete';
    private static final List<String> OPERATIONS = new List<String> {
        OPERATION_READ, OPERATION_CREATE, OPERATION_UPDATE, OPERATION_DELETE
    };

    public Map<String, Boolean> getPermissions(String target) {
        Map<String, Boolean> permissions = new Map<String, Boolean>();

        for (String operation: OPERATIONS) {
            Boolean permission = false;
            if (operation == OPERATION_READ) {
                permission = canRead(target);
            } else if (operation == OPERATION_CREATE) {
                permission = canCreate(target);
            } else if (operation == OPERATION_UPDATE) {
                permission = canUpdate(target);
            } else if (operation == OPERATION_DELETE) {
                permission = canDelete(target);
            } else {
                System.debug('Unsupported operation: ' + operation);
            }
            permissions.put(operation, permission);
        }

        return permissions;
    }

    public Boolean canRead(String target) {
        return canReadObject(target);
    }

    public Boolean canCreate(String target) {
        return canCreateObject(target);
    }

    public Boolean canUpdate(String target) {
        return canUpdateObject(target);
    }

    public Boolean canDelete(String target) {
        return canDeleteObject(target);
    }

    private Boolean canReadObject(String objectName) {
        Boolean ret = false;
        Schema.SObjectType objectType = VeevaJourneyHelper.getObjectTypeByObjectName(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult objectInfo = objectType.getDescribe();
            ret = objectInfo.isAccessible() && objectInfo.isQueryable();
        }
        return ret;
    }

    private Boolean canCreateObject(String objectName) {
        Boolean ret = false;
        Schema.SObjectType objectType = VeevaJourneyHelper.getObjectTypeByObjectName(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult objectInfo = objectType.getDescribe();
            ret = objectInfo.isCreateable();
        }
        return ret;
    }

    private Boolean canUpdateObject(String objectName) {
        Boolean ret = false;
        Schema.SObjectType objectType = VeevaJourneyHelper.getObjectTypeByObjectName(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult objectInfo = objectType.getDescribe();
            ret = objectInfo.isUpdateable();
        }
        return ret;
    }

    private Boolean canDeleteObject(String objectName) {
        Boolean ret = false;
        Schema.SObjectType objectType = VeevaJourneyHelper.getObjectTypeByObjectName(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult objectInfo = objectType.getDescribe();
            ret = objectInfo.isDeletable();
        }
        return ret;
    }
}