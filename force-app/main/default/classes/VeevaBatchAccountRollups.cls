global without sharing class VeevaBatchAccountRollups implements Database.Batchable<SObject> {

    private VeevaAccountPlanHierarchy accountPlanHierarchy = new VeevaAccountPlanHierarchy();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Active_vod__c FROM Account_Plan_vod__c WHERE Active_vod__c = TRUE]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> batch) {
        if (this.accountPlanHierarchy.isValidHierarchy()) {
            processRollup(batch, 0);
        }
    }

    global void finish(Database.BatchableContext bc) {

    }

    private Decimal processRollup(List<SObject> parentObjects, Integer depth) {
        Integer totalObjects = 0;
        Integer completedObjects = 0;

        if (depth >= this.accountPlanHierarchy.getObjectHierarchy().size()) {
            for (SObject parentObject : parentObjects) {
                totalObjects++;
                if (isObjectCompleted(parentObject)) {
                    completedObjects++;
                }
            }
            if(totalObjects > 0) {
                return (Decimal.valueOf(completedObjects) / totalObjects) * 100;
            }
            return null;
        }

        String objectName = this.accountPlanHierarchy.getObjectName(depth);
        String objectFieldName = this.accountPlanHierarchy.getFieldName(objectName);

        Set<String> parentIds = new Set<String>();
        for (Integer i = 0; i < parentObjects.size (); i++) {
            parentIds.add(parentObjects[i].Id);
        }

        List<String> queryFields = new List<String>{'Id', objectFieldName};
        if (objectName == 'Call_Objective_vod__c') {
            queryFields.add('Completed_Flag_vod__c');
        } else {
            queryFields.add('Status_vod__c');
        }

        Map<String, List<SObject>> parentIdToObjects = new Map<String, List<SObject>>();

        String query = 'SELECT ';
        query += String.join(queryFields, ', ');
        query += ' FROM ' + objectName;
        query += ' WHERE ' + objectFieldName + ' IN :parentIds';

        for (SObject cObj : Database.query(query)) {
            String parentId = String.valueOf(cObj.get(objectFieldName));
            if (parentIdToObjects.containsKey(parentId) == false) {
                parentIdToObjects.put(parentId, new List<SObject>());
            }
            parentIdToObjects.get(parentId).add(cObj);
        }

        List<SObject> updatedSObjects = new List<SObject>();
        for (SObject parentObject : parentObjects) {
            totalObjects++;
            if (isObjectCompleted(parentObject)) {
                completedObjects++;
                continue;
            }
            if (parentIdToObjects.containsKey(parentObject.Id)) {
                Decimal progressPercentage = processRollup(parentIdToObjects.get(parentObject.Id), depth + 1);
                if (progressPercentage == null) {
                    continue;
                }
                parentObject.put('Progress_vod__c', progressPercentage);
                updatedSObjects.add(parentObject);
                if (progressPercentage == 100 && parentObject.getSObjectType().getDescribe().getName() != 'Account_Plan_vod__c') {
                    parentObject.put('Status_vod__c', 'Completed_vod');
                    completedObjects++;
                }
            }
        }

        update(updatedSObjects);

        if(totalObjects > 0) {
            return (Decimal.valueOf(completedObjects) / totalObjects) * 100;
        }
        return null;

    }

    private Boolean hasSObjectField(String fieldName, SObject so) {
        return so.getSObjectType().getDescribe().fields.getMap().keySet().contains(fieldName.toLowerCase());
    }

    private Boolean isObjectCompleted(SObject obj) {
        String fieldName;
        if (String.valueOf(obj.getSObjectType()) == 'Call_Objective_vod__c') {
            fieldName = 'Completed_Flag_vod__c';
            if (hasSObjectField(fieldName, obj) && Boolean.valueOf(obj.get(fieldName)) == true) {
                return true;
            }
        } else if (String.valueOf(obj.getSObjectType()) == 'Account_Plan_vod__c') {
            return false;
        } else {
            fieldName = 'Status_vod__c';
            if (hasSObjectField(fieldName, obj) && String.valueOf(obj.get(fieldName)) == 'Completed_vod') {
                return true;
            }
        }
        return false;
    }
}