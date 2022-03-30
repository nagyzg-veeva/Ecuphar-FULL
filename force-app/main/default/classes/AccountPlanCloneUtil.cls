public with sharing class AccountPlanCloneUtil {
    
    static final String OBJECT_NAME = 'Account_Plan_vod__c';
    static final String[] ADDITIONAL_FIELDS = new String[]{'Account_Plan_vod__c'};
    static final String CALL_OBJECTIVE_OBJECT_NAME = 'Call_Objective_vod__c';
    static final String CALL_OBJECTIVE_PREREQUISITE_FIELD_NAME = 'Prerequisite_vod__c';
    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();

    public static Map<String, String> insertClonedAccountPlan(Map<String, Object[]> hierarchyObjects, Map<String, String> hierarchyMap, 
        Map<String, Object[]> relatedObjects) {
        Map<String, String> result = new Map<String, String>();
        String newAccountPlanId = insertHierarchyObjects(hierarchyObjects, hierarchyMap);
        if (!String.isBlank(newAccountPlanId)){
            insertRelatedObjects(relatedObjects, newAccountPlanId);
            result.put('newAccountPlanId', newAccountPlanId);
        }
        return result;
    }
    
    public static String insertHierarchyObjects(Map<String, Object[]> hierarchyObjects, Map<String, String> hierarchyMap){
        String currObjectName = OBJECT_NAME;
        String parentName = null;    
        List<SObject> sObjects;
        Map<Id, Id> idMap = new Map<Id, Id>();
        List<SObject> updatedSObjects = null;
        List<String> parentList = new List<String>();
        Id newAccountPlanId;
        Id oldAccountPlanId;
        while (!String.isBlank(currObjectName)){
            Object[] objects = hierarchyObjects.get(currObjectName);
            List<Id> oldIdList = new List<Id>();
            if (objects != null && objects.size() > 0){

                sObjects = getSObjectsList(objects);
                for (SObject sO : sObjects){
                    oldIdList.add(sO.Id);
                    sO.Id = null;
                }
                if (String.isBlank(parentName)){
                    SObject accountPlan = sObjects.get(0);
                    Set<String> externalIdFields = getAllExternalIdFields(currObjectName);
                    clearExternalIdFields(accountPlan, externalIdFields);
                    insert accountPlan;
                    newAccountPlanId = accountPlan.Id;
                    oldAccountPlanId = Id.valueOf(String.valueOf(accountPlan.get('Clones_vod__c')));
                    idMap.put(oldAccountPlanId, newAccountPlanId);
                } else {
                    Map<Id, Id> origLookupMapping = new Map<Id, Id>();
                    updatedSObjects = assignParentAndAdditionalFieldIds(currObjectName, sObjects, idMap, parentList);
                    if (currObjectName == CALL_OBJECTIVE_OBJECT_NAME){
                        origLookupMapping = clearLookupFieldAndGetMapping(updatedSObjects, oldIdList, CALL_OBJECTIVE_OBJECT_NAME, CALL_OBJECTIVE_PREREQUISITE_FIELD_NAME);
                    }
                    insert updatedSObjects;
                    if(updatedSObjects != null && updatedSObjects.size() > 0){
                        for(Integer i = 0; i < updatedSObjects.size(); i++){
                            idMap.put(oldIdList.get(i), updatedSObjects.get(i).Id);
                        }
                    }
                    if (currObjectName == CALL_OBJECTIVE_OBJECT_NAME){
                        updateObjectLookupFieldValues(updatedSObjects, origLookupMapping, idMap, CALL_OBJECTIVE_PREREQUISITE_FIELD_NAME);
                    }
                }
            }
            parentList.add(currObjectName);
            parentName = currObjectName;
            if (hierarchyMap.containsKey(currObjectName)){
                currObjectName = hierarchyMap.get(currObjectName);
            } else {
                currObjectName = null;
            }
        }        
        return newAccountPlanId;
    }    

    private static List<SObject> assignParentAndAdditionalFieldIds(String objectName, List<SObject> sObjects, Map<Id, Id> idMap, List<String> hierarchyObjects){
        //check for all upstream parents in hierarchy
        Set<String> parentReferenceFields = checkHierarchyParentFieldsOnObject(objectName, hierarchyObjects);
        Set<String> externalIdFields = getAllExternalIdFields(objectName);
        for (SObject sObj : sObjects){
            for (String field : parentReferenceFields){
                if (sObj.get(field) != null && idMap.containsKey((Id)sObj.get(field))){
                    sObj.put(field, idMap.get((Id)sObj.get(field)));
                }
            }
            clearExternalIdFields(sObj, externalIdFields);
        }
        return sObjects;
    }

    private static void insertRelatedObjects(Map<String, Object[]> relatedObjects, Id newAccountPlanId){
        List<SObject> sObjects = new List<SObject>();
        List<Id> oldIds = new List<Id>();
        for (String relatedObjectName : relatedObjects.keySet()){
            Set<String> externalIdFields = getAllExternalIdFields(relatedObjectName);
            Set<String> parentReferenceFields = checkHierarchyParentFieldsOnObject(relatedObjectName, new String[]{'Account_Plan_vod__c'});
            for (SObject sObj : getSObjectsList(relatedObjects.get(relatedObjectName))){
                oldIds.add(sObj.Id);
                sObj.Id = null;
                for (String field : parentReferenceFields){
                    sObj.put(field, newAccountPlanId);
                }
                clearExternalIdFields(sObj, externalIdFields);
                sObjects.add(sObj);
            }
        }
        Map<Id, Id> origLookupMapping = new Map<Id, Id>();
        if (relatedObjects.containsKey(CALL_OBJECTIVE_OBJECT_NAME)){
            origLookupMapping = clearLookupFieldAndGetMapping(sObjects, oldIds, CALL_OBJECTIVE_OBJECT_NAME, CALL_OBJECTIVE_PREREQUISITE_FIELD_NAME);
        }
        insert sObjects;
        if (relatedObjects.containsKey(CALL_OBJECTIVE_OBJECT_NAME)){
            updateRelatedCallObjectives(sObjects, oldIds, origLookupMapping);
        }
    }

    private static void updateRelatedCallObjectives(List<SObject> sObjects, List<Id> oldIds, Map<Id, Id> origLookupMapping){
        List<SObject> callObjectiveSObjects = new List<SObject>();
        Map<Id, Id> idMap = new Map<Id, Id>();
        for (Integer i = 0; i < sObjects.size(); i++){
            SObject sObj = sObjects.get(i);
            if (sObj.getSObjectType().getDescribe().getName() == CALL_OBJECTIVE_OBJECT_NAME){
                callObjectiveSObjects.add(sObj);
                idMap.put(oldIds.get(i), sObj.Id);
            }
        }
        if (callObjectiveSObjects.size() > 0){
            updateObjectLookupFieldValues(callObjectiveSObjects, origLookupMapping, idMap, CALL_OBJECTIVE_PREREQUISITE_FIELD_NAME);
        }
    }

    private static List<SObject> getSObjectsList(Object[] objectList){
        List<SObject> sObjectList = new List<SObject>();
        for (Object obj : objectList){
            SObject sObj = (SObject) JSON.deserialize(JSON.serialize(obj), SObject.class);    
            sObjectList.add(sObj);
        }
        return sObjectList;
    } 

    private static Set<String> checkHierarchyParentFieldsOnObject(String objectName, List<String> hierarchyObjects){
        Schema.DescribeSObjectResult sObjectDescribe = globalDescribe.get(objectName).getDescribe();
        Map<String, Schema.SObjectField> objFieldMap = sObjectDescribe.fields.getMap();
        Set<String> lookupFields = new Set<String>();
        for (String parentObject : hierarchyObjects){
            if (parentObject == objectName){
                break;
            }
            for (Schema.SObjectField field : objFieldMap.values()){
                schema.describeFieldResult fldDesc = field.getDescribe();
                for(Schema.SObjectType reference : fldDesc.getReferenceTo()) {
                    if (reference.getDescribe().getName() == parentObject){
                        lookupFields.add(field.getDescribe().getName());
                    }
                }
            }
        }
        return lookupFields;
    }

    private static Set<String> getAllExternalIdFields(String objectName){
        Schema.DescribeSObjectResult sObjectDescribe = globalDescribe.get(objectName).getDescribe();
        Map<String, Schema.SObjectField> objFieldMap = sObjectDescribe.fields.getMap();
        Set<String> externalIdFields = new Set<String>();
        for (Schema.SObjectField field : objFieldMap.values()){
            schema.describeFieldResult fldDesc = field.getDescribe();
            if (fldDesc.isExternalId()){
                externalIdFields.add(fldDesc.getName());
            }
        }
        return externalIdFields;
    }

    private static void clearExternalIdFields(SObject sObj, Set<String> externalIdFields){
        for (String externalIdField : externalIdFields){
            if (sObj.get(externalIdField) != null){
                sObj.put(externalIdField, null);
            }
        }
    }

    private static void updateObjectLookupFieldValues(List<SObject> sObjList, Map<Id, Id> origLookupMapping, Map<Id, Id> idMap, String field){
        for (SObject sObj : sObjList){
            Id oldId = findIdInMap(idMap, sObj.Id);
            if (origLookupMapping.get(oldId) != null){
                Id originalLookupValue = origLookupMapping.get(oldId);
                sObj.put(field, idMap.get(originalLookupValue));
            }
        }
        VEEVA_CALL_OBJECTIVE_TRIG.setInvoked(false);
        upsert sObjList;
    }

    private static Id findIdInMap(Map<Id, Id> idMap, Id newId){
        Id oldId;
        for (Id tmpId : idMap.keySet()){
            if (idMap.get(tmpId) == newId){
                oldId = tmpId;
                break;
            }
        }
        return oldId;
    }

    private static Map<Id, Id> clearLookupFieldAndGetMapping(List<SObject> sObjectList, List<Id> oldIdList, String objectName, String fieldName){
        Map<Id, Id> lookupFieldMapping = new Map<Id, Id>();
        Integer count = 0;
        for (SObject sObj : sObjectList){
            if (sObj.getSObjectType().getDescribe().getName() == objectName && sObj.get(fieldName) != null){
                lookupFieldMapping.put(oldIdList.get(count), (Id)sObj.get(fieldName));
                sObj.put(fieldName, null);
            }
            count++;
        }
        return lookupFieldMapping;
    }
}