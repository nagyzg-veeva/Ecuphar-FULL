public with sharing class MyInsightsService {

    @AuraEnabled(cacheable=true)
    public static String getFirstTSFIdMatchingUserTerritoryNames(String accountId) {
        List<String> userTerritoryNames = getUserTerritoryNames();
        List<TSF_vod__c> sortedTSFRecordsByTerritoryNameForAccount = [SELECT Id FROM TSF_vod__c WHERE Account_vod__c = :accountId AND Territory_vod__c in :userTerritoryNames ORDER BY Territory_vod__c ASC LIMIT 1];
        String firstTSFIdMatchingUserTerritoryNamesForAccount;
        if (sortedTSFRecordsByTerritoryNameForAccount.size() > 0) {
            firstTSFIdMatchingUserTerritoryNamesForAccount = sortedTSFRecordsByTerritoryNameForAccount.get(0).Id;
        } else {
            firstTSFIdMatchingUserTerritoryNamesForAccount = null;
        }
        return firstTSFIdMatchingUserTerritoryNamesForAccount;
    }

    @AuraEnabled
    public static Map<String, String> getPicklistLabelsByValue(String objectName, String fieldName) {
        try {
            return retrievePicklistLabelsByValue(objectName, fieldName);
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage()); // This is necessary for unit tests
            throw ex;
        }
    }

    private static List<String> getUserTerritoryNames() {
        TerritoryManagement2 territoryManagement = new TerritoryManagement2();
        Set<Id> userTerritoryIds = territoryManagement.getUserTerritories(UserInfo.getUserId());
        List<Territory2> userTerritories = [SELECT Name FROM Territory2 WHERE Id in :userTerritoryIds];
        return getTerritoryNames(userTerritories);
    }

    private static List<String> getTerritoryNames(List<Territory2> territories) {
        List<String> territoryNames = new List<String>();
        for (Territory2 territory : territories) {
            territoryNames.add(territory.Name);
        }
        return territoryNames;
    }

    private static Map<String, String> retrievePicklistLabelsByValue(String objectName, String fieldName) {
        Map<String, String> picklistLabelsByValue = new Map<String, String>();
        Schema.SObjectType objectType = getSObjectType(objectName); 
        if (objectType == null) {
            throw createAuraHandledException(objectName + ' is not a recognized Object Name');
        }

        Schema.SObjectField sObjectField = getSObjectField(objectType, fieldName);
        if (sObjectField == null) {
            throw createAuraHandledException(fieldName + ' is not a recognized field name for ' + objectName);
        }
        Schema.DescribeFieldResult fieldDescribe = sObjectField.getDescribe();
        if (!isPicklistType(fieldDescribe)) {
            throw createAuraHandledException(fieldName + ' is not a picklist field type for ' + objectName);
        }

        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            picklistLabelsByValue.put(picklistValue.value, picklistValue.label);
        }

        return picklistLabelsByValue;
    }

    private static Schema.SObjectType getSObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        if (typeOfObject != null) {
            return ((SObject) typeOfObject.newInstance()).getSObjectType();
        } else {
            return null;
        }
    }

    private static Schema.SObjectField getSObjectField(Schema.SObjectType sobjectType, String fieldName) {
        Schema.DescribeSObjectResult objectDescribeResult = sobjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribeResult.fields.getMap();
        Schema.SObjectField sObjectField = fieldMap.get(fieldName);
        return sObjectField;
    }

    private static boolean isPicklistType(Schema.DescribeFieldResult fieldDescribe) {
        return fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST; 
    }

    private static AuraHandledException createAuraHandledException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message); // This is necessary for unit tests
        return ex;
    }
}