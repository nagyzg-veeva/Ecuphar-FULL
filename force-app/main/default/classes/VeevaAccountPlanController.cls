public with sharing class VeevaAccountPlanController {
    static final String OBJECT_NAME = 'Account_Plan_vod__c';
    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();

    @AuraEnabled (cacheable = true)
    public static String getAccountPlanObjectHierarchy() {
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getOrgDefaults();
        if (settings != null) {
            return settings.Account_Plan_Object_Hierarchy_vod__c;
        }
        return null;
    }

    @AuraEnabled    
    public static Map<String, String> insertClonedAccountPlan(Map<String, Object[]> hierarchyObjects, Map<String, String> hierarchyMap, 
        Map<String, Object[]> relatedObjects) {
        
        return AccountPlanCloneUtil.insertClonedAccountPlan(hierarchyObjects, hierarchyMap, relatedObjects);
    }

    @AuraEnabled
    public static Map<String, List<Id>> getHierarchyRecordIds(Map<String, String> hierarchyRelationships, Id recordId){
        Map<String, List<Id>> objectIdList = new Map<String, List<Id>>();
        List<id> idList = new List<Id>();
        String childObjectName;
        String childRelationshipName;

        idList.add(recordId);
        String parentObj = OBJECT_NAME;
        objectIdList.put(parentObj, idList);

        while (hierarchyRelationships.containsKey(parentObj)){
            //get child object and relationship names
            String[] childInfo = String.valueOf(hierarchyRelationships.get(parentObj)).split(',');
            childObjectName = childInfo[0];
            childRelationshipName = childInfo[1];
            if (objectIdList.get(parentObj).isEmpty()){
                break;
            }
            SObject[] sObjects = fetchChildObjects(parentObj, childRelationshipName, objectIdList.get(parentObj));
            idList = new List<id>();
            for(SObject sObj : sObjects){
                if (sObj.getSObjects(childRelationshipName) != null){
                    for (SObject childSObj : sObj.getSObjects(childRelationshipName)){
                        if (childSObj.getSObjectType().getDescribe().getName() != 'Call_Objective_vod__c' || childSObj.get('Parent_Objective_vod__c') == null){
                            idList.add(childSObj.Id);
                        }
                    }
                }
            }
            objectIdList.put(childObjectName, idList);
            parentObj = childObjectName;
        }
        return objectIdList;
    }

    @AuraEnabled
    public static Map<String, List<Id>> getRelatedRecordIds(Map<String, String> relatedObjectInfo, Id recordId){

        Map<String, List<Id>> relatedObjectsMap = new Map<String, List<Id>>();
        SObject[] sObjects = fetchRelatedObjects('Account_Plan_vod__c', relatedObjectInfo.values(), recordId);
        List<SObject> childObjects;
        List<Id> idList;
        for (String relatedObjectName : relatedObjectInfo.keySet()){
            idList = new List<Id>();
            childObjects = sObjects[0].getSObjects(relatedObjectInfo.get(relatedObjectName));
            if (childObjects != null){
                for (SObject child : childObjects){
                    if (relatedObjectName != 'Call_Objective_vod__c' || child.get('Parent_Objective_vod__c') == null){
                        idList.add(child.Id);
                    }
                }
            }
            if (idList.size() > 0)
                relatedObjectsMap.put(relatedObjectName, idList);
        }
        return relatedObjectsMap;
    }

    private static SObject[] fetchChildObjects(String parent, String childRelationship, List<Id> parentIds){
        boolean validObjectRelationship = isObjectRelationshipNameValid(parent, childRelationship);
        String query;
        if(!validObjectRelationship){
            AuraHandledException ex = new AuraHandledException('Hierarchy Object or Relationship does not exist');
            ex.setMessage('Hierarchy Object or Relationship does not exist');
            throw ex;
        }
        if (isCallObjectiveRelationship(parent, childRelationship)){
            query = 'SELECT Id, (SELECT Id, Parent_Objective_vod__c FROM ' + childRelationship + ') FROM ' + parent + ' WHERE Id IN :parentIds';
        } else {
            query = 'SELECT Id, (SELECT Id FROM ' + childRelationship + ') FROM ' + parent + ' WHERE Id IN :parentIds';
        }
        return Database.query(query);
    }

    private static SObject[] fetchRelatedObjects(String parent, List<String> relatedObjectRelationships, Id parentId){
        boolean valid = areRelatedObjectsValid(relatedObjectRelationships);
        if (!valid){
            AuraHandledException ex = new AuraHandledException('Child Object specified does not exist in the Org');
            ex.setMessage('Child Object specified does not exist in the Org');
            throw ex;
        }
        String query = 'SELECT Id '; 
        for (String relatedObjectRelationship : relatedObjectRelationships){
            if (isCallObjectiveRelationship(OBJECT_NAME, relatedObjectRelationship)){
                query += ', (SELECT Id, Parent_Objective_vod__c FROM ' + relatedObjectRelationship + ') ';
            }else{
                query += ', (SELECT Id FROM ' + relatedObjectRelationship + ') ';
            }
        }
        query += ' FROM ' + parent + ' WHERE Id = :parentId';
        return Database.query(query);
    }

    private static boolean isObjectRelationshipNameValid(String child, String relationship){
        boolean valid = false;
        SObjectType type = globalDescribe.get(child);
        if (type != null){
            DescribeSObjectResult sObjectDescribe = type.getDescribe();
            for(Schema.ChildRelationship childRelationship : sObjectDescribe.getChildRelationships()){
                if (childRelationship.getRelationshipName() == relationship){
                    valid = true;
                    break;
                }
            }
        }
        return valid;
    }

    private static boolean areRelatedObjectsValid(List<String> relationshipNames){
        boolean valid = false;
        for (String relationshipName : relationshipNames){
            DescribeSObjectResult sObjectDescribe = globalDescribe.get('Account_Plan_vod__c').getDescribe();
            for(Schema.ChildRelationship childRelationship : sObjectDescribe.getChildRelationships()){
                if (childRelationship.getRelationshipName() == relationshipName){
                    valid = true;
                    break;
                }
            }
        }
        return valid;
    }

    private static boolean isCallObjectiveRelationship(String parent, String relationshipName){
        boolean isCallObjectiveRef = false;
        DescribeSObjectResult sObjectDescribe = globalDescribe.get(parent).getDescribe();
        for(Schema.ChildRelationship childRelationship : sObjectDescribe.getChildRelationships()){
            if (childRelationship.getRelationshipName() == relationshipName && childRelationship.getChildSObject().getDescribe().getName() == 'Call_Objective_vod__c'){
                isCallObjectiveRef = true;
                break;
            }
        }
        return isCallObjectiveRef;
    }
}