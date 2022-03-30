public with sharing class VeevaStakeholderNavigatorQueryService {
    public static List<Child_Account_vod__c> getParentChildRelationshipsFromChild(List<Id> ids) {
        return [
            SELECT Parent_Account_vod__c, Child_Account_vod__c, Primary_vod__c, Parent_Account_vod__r.Formatted_Name_vod__c, Child_Account_vod__r.Primary_Parent_vod__c
            FROM Child_Account_vod__c 
            WHERE Child_Account_vod__c in :ids
        ];
    }

    public static List<Account> getAccounts(Set<Id> ids){
        return [
            SELECT Id, Formatted_Name_vod__c, RecordType.IsPersonType, RecordType.DeveloperName, toLabel(RecordType.Name),
                Specialty_1_vod__c, Group_Specialty_1_vod__c, Specialty_2_vod__c,
                Group_Specialty_2_vod__c, Account_Identifier_vod__c, PersonEmail, Phone
            FROM Account
            WHERE Id IN :ids
        ];
    }

    public static List<Affiliation_vod__c> getAffiliations(Set<Id> ids){
        return [
            SELECT From_Account_vod__c, To_Account_vod__c, Influence_vod__c, Relationship_Strength_vod__c, 
                   Role_vod__c, Therapeutic_Area_vod__c, Comments_vod__c
            FROM Affiliation_vod__c 
            WHERE From_Account_vod__c IN :ids
        ];
    }

    public static ID getAccountIdOfAccountPlan(Id rootId) {
        List<Account_Plan_vod__c> accountPlan = [
            SELECT Account_vod__c
            FROM Account_Plan_vod__c
            WHERE Id = :rootId
            LIMIT 1
        ];
        Id accountPlanId;
        if (accountPlan.size() > 0) {
            accountPlanId = accountPlan[0].Account_vod__c;
        }
        return accountPlanId;
    }

    public static ID getParentId(Id rootId) {
        List<Child_Account_vod__c> childAccounts = [
            SELECT Parent_Account_vod__c
            FROM Child_Account_vod__c
            WHERE Child_Account_vod__c = :rootId
            LIMIT 1
        ];
        if (childAccounts.size() > 0) {
            return childAccounts[0].Parent_Account_vod__c;
        }
        return null;
    }

    public static List<Id> getKeyStakeholders(Id accountPlanId) {
        List<Id> keyStakeholders = new List<Id>();
        for (Key_Stakeholder_vod__c s: [
            SELECT Key_Stakeholder_vod__c
            FROM Key_Stakeholder_vod__c
            WHERE Account_Plan_vod__c = :accountPlanId
        ]) {
            keyStakeholders.add(s.Key_Stakeholder_vod__c);
        }

        return keyStakeholders;
    }

    public static Map<String, String> getStakeholderNavigatorVeevaMessages() {
        String userLang = UserInfo.getLanguage();
        Map<String, String> veevaMessages = new Map<String, String>();

        for (Message_vod__c message: [
            SELECT Name, Text_vod__c
            FROM Message_vod__c
            WHERE Active_vod__c = true AND ((Category_vod__c = 'STAKEHOLDER_NAVIGATOR' AND Language_vod__c = :userLang) 
            OR (Category_vod__c = 'COMMON' AND Name in ('ALL', 'RECORD_TYPE_LABEL') AND Language_vod__c = :userLang))
        ]) {
            veevaMessages.put(message.Name, message.Text_vod__c);
        }
 
        return veevaMessages;
    }

    public static Boolean hasAccountAccess(Id id) {
        List<Account> acc = [SELECT Id, Formatted_Name_vod__c FROM Account WHERE Id = :id];
        return acc.size() == 1;
    }

    public static String getSNVeevaMessageWithDefault(String messageName, String defaultString) {
        String userLang = UserInfo.getLanguage();
        String veevaMessage = defaultString;

        for (Message_vod__c message: [
            SELECT Text_vod__c
            FROM Message_vod__c
            WHERE Category_vod__c = 'STAKEHOLDER_NAVIGATOR' AND 
                  Language_vod__c = :userLang AND
                  Name = :messageName AND
                  Active_vod__c = true
            LIMIT 1
        ]) {
            veevaMessage = message.Text_vod__c;
        }

        return veevaMessage;
    }

    public static Map<Id, Set<String>> getAccountToTerritoryMap(Set<Id> accountIds) {
        Map<Id, Set<Id>> acctToTerrMap = new Map<Id, Set<Id>>();
        Set<Id> allTerritoryIds = new Set<Id>();
        for (ObjectTerritory2Association t : [
            SELECT Id, ObjectId, Territory2Id
            FROM ObjectTerritory2Association
            WHERE ObjectId in :accountIds
        ]) {
            allTerritoryIds.add(t.Territory2Id);
            Set<Id> terrForAcct = acctToTerrMap.get(t.ObjectId);
            if (terrForAcct == null) {
                acctToTerrMap.put(t.ObjectId, new Set<Id>{t.Territory2Id});
            } else {
                terrForAcct.add(t.Territory2Id);
            }
        }
        TerritoryManagement2 tm = new TerritoryManagement2();
        Map<Id, Map<String, String>> territories = tm.getTerritories(allTerritoryIds);
        Map<Id, Set<String>> acctToTerrNameMap = new Map<Id, Set<String>>();
        for (Id accountId : acctToTerrMap.keySet()) {
            Set<String> terrNames = new Set<String>();
            for (Id terrId : acctToTerrMap.get(accountId)) {
                Map<String, String> terrValues = territories.get(terrId);
                if (terrValues != null) {
                    terrNames.add(terrValues.get('Name'));
                }
            }
            if (terrNames != null) {
                acctToTerrNameMap.put(accountId, terrNames);
            }
        }

        return acctToTerrNameMap;
    }
}