public without sharing class AssignCallObjectiveLgtnController {
    @AuraEnabled
    public static List<Call_Objective_vod__c> getObjectives(Id tacticId) {
        if (tacticId == null) {
            return new List<Call_Objective_vod__c>();
        }
        Account_Tactic_vod__c tactic = [SELECT Account_vod__c FROM Account_Tactic_vod__c WHERE Id = :tacticId LIMIT 1];
        return [SELECT Id, Name, Name_vod__c, RecordType.Name, From_Date_vod__c, To_Date_vod__c  FROM Call_Objective_vod__c Where Account_Tactic_vod__c = NULL AND Completed_Flag_vod__c = false
                AND Parent_Objective_vod__c =null AND Account_vod__c = :tactic.Account_vod__c];
    }

    @AuraEnabled
    public static Map<String, String> getFieldNames() {
        Map<String, String> returnMap = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Call_Objective_vod__c.fields.getMap();
        for (String key : fieldMap.keySet()) {
            Schema.DescribeFieldResult R = fieldMap.get(key).getDescribe();
            String fieldLabel = R.getLabel();
            returnMap.put(key, fieldLabel);
        }
        returnMap.put('cancel', System.Label.Common_CancelButton_vod);
        returnMap.put('RecordType', Schema.SObjectType.RecordType.getLabel());
        return returnMap;
    }

    @AuraEnabled
    public static void assignToObjective(Id tacticId, Id objectiveId) {
        Call_Objective_vod__c objective = new Call_Objective_vod__c(Id= objectiveId, Account_Tactic_vod__c = tacticId);
        update objective;
    }
}