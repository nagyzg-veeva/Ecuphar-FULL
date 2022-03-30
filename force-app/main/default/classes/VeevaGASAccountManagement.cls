public without sharing class VeevaGASAccountManagement {
    private static Set<String> ADDRESS_QUERY_FIELDS = new Set<String> {
        'Id', 'Name', 'Address_Line_2_vod__c', 'City_vod__c', 'toLabel(State_vod__c)', 'Zip_vod__c'
    };

    public List<Account> getParentAccounts(String accountId) {
        List<String> parentAccountIds = getParentAccountIds(accountId);
        List<String> userAccessibleAddressFields = new List<String>(getUserAccessibleAddressQueryFields());
        List<String> queryFields = new List<String> { 'Id', 'Name' };
        if (userAccessibleAddressFields.size() > 0) {
            queryFields.add(String.format(
                '(SELECT {0} FROM Address_vod__r ORDER BY Primary_vod__c DESC, CreatedDate ASC LIMIT 1)',
                new List<Object>{ String.join(userAccessibleAddressFields, ', ') }
            ));
        }

        List<Account> parentAccounts = Database.query(
            String.format(
                'SELECT {0} FROM Account WHERE Id IN :parentAccountIds',
                new List<Object> { String.join(queryFields, ', ') }
            )
        );
        return parentAccounts;
    }

    public VeevaGASTerritoryAssignmentResult assignAccountsToTerritories(List<String> accountIds, List<String> territoryIds) {
        List<Territory2> territories = [SELECT Id, Name FROM Territory2 WHERE Id IN :territoryIds];
        String territoryNamesForATL = getTerritoriesToAddForATL(territories);
        List<Account_Territory_Loader_vod__c> accountAtls = getOrCreateATLRecordForAccounts(accountIds);
        for (Account_Territory_Loader_vod__c accountAtl : accountAtls) {
            accountAtl.Territory_To_Add_vod__c = territoryNamesForATL;
        }

        // Upserts ATLs with Territories to Add and returns false if any one of the ATLs failed to upsert
        List<Database.UpsertResult> upsertResults = Database.upsert(accountAtls, false);
        for (Database.UpsertResult upsertResult : upsertResults) {
            if (!upsertResult.isSuccess()){
                return new VeevaGASTerritoryAssignmentResult(false, upsertResult.getErrors().get(0).getMessage());
            }
        }
        // Verifies that the ObjectTerritory2Association was created using our ATL Process
        List<ObjectTerritory2Association> objectTerritoryAssociations = [SELECT ObjectId, Territory2Id FROM ObjectTerritory2Association WHERE ObjectId IN :accountIds AND Territory2Id IN :territoryIds];
        boolean allAssignmentsSuccessful = objectTerritoryAssociations.size() == accountIds.size() * territoryIds.size();
        // If there are any assignment failures we will retrieve the missing assignments.
        if (!allAssignmentsSuccessful) {
            List<String> missingAssignmentMessages = getMissingAssignmentMessages(objectTerritoryAssociations, accountIds, territoryIds, territories);
            return new VeevaGASTerritoryAssignmentResult(false, String.join(missingAssignmentMessages, '\n'));
        }
        return new VeevaGASTerritoryAssignmentResult(allAssignmentsSuccessful, '');
    }

    private List<String> getParentAccountIds(String accountId) {
        List<Child_Account_vod__c> relatedChildAccountRecords = [SELECT Parent_Account_vod__c FROM Child_Account_vod__c WHERE Child_Account_vod__c = :accountId];

        List<String> parentAccountIds = new List<String>();
        for (Child_Account_vod__c childRelationship : relatedChildAccountRecords) {
            parentAccountIds.add(childRelationship.Parent_Account_vod__c);
        }

        return parentAccountIds;
    }

    private Set<String> getUserAccessibleAddressQueryFields() {
        Set<String> userAccessibleFields = new Set<String>();
        Schema.DescribeSObjectResult addressDescribe = Address_vod__c.getSObjectType().getDescribe();
        if (addressDescribe.isAccessible() && addressDescribe.isQueryable()) {
            Map<String, Schema.SObjectField> addressFieldDefinitions = addressDescribe.fields.getMap();
            for (String field : ADDRESS_QUERY_FIELDS) {
                String strippedFieldName = field.startsWith('toLabel') ? field.substringBetween('(', ')') : field;
                Schema.SObjectField fieldDefinition = addressFieldDefinitions.get(strippedFieldName);
                if (fieldDefinition != null && fieldDefinition.getDescribe().isAccessible()) {
                    userAccessibleFields.add(field);
                }
            }
        }
        return userAccessibleFields;        
    }

    private List<Account_Territory_Loader_vod__c> getOrCreateATLRecordForAccounts(List<String> accountIds) {
        List<Account_Territory_Loader_vod__c> accountATLRecords = [SELECT Id, Account_vod__c, Territory_vod__c, Territory_To_Add_vod__c FROM Account_Territory_Loader_vod__c WHERE Account_vod__c IN :accountIds];
        Map<String, Account_Territory_Loader_vod__c> accountToAtl = new Map<String, Account_Territory_Loader_vod__c>();
        for (Account_Territory_Loader_vod__c atl : accountATLRecords) {
            accountToAtl.put(atl.Account_vod__c, atl);
        }

        accountAtlRecords = new List<Account_Territory_Loader_vod__c>();
        for (String accountId : accountIds) {
            Account_Territory_Loader_vod__c atl = accountToAtl.get(accountId);
            if (atl == null) {
                atl = new Account_Territory_Loader_vod__c(
                    Account_vod__c=accountId
                );
            }
            accountATLRecords.add(atl);
        }
        return accountATLRecords;
    }

    private String getTerritoriesToAddForATL(List<Territory2> territories) {
        List<String> territoryNames = new List<String>();
        for (Territory2 territory : territories) {
            territoryNames.add(territory.Name);
        }
        return ';' + String.join(territoryNames, ';') + ';';
    }

    private List<String> getMissingAssignmentMessages(List<ObjectTerritory2Association> objectTerritoryAssociations, List<String> accountIds, List<String> territoryIds, List<Territory2> territories) {
        Set<ObjectTerritory2Association> missingObjectTerritory2Associations = getMissingObjectTerritory2Associations(objectTerritoryAssociations, accountIds, territoryIds);
        Map<String, List<String>> missingAccountToTerritoriesAssignments = new Map<String, List<String>>();
        for (ObjectTerritory2Association missingOTA : missingObjectTerritory2Associations) {
            List<String> missingTerritoryAssignments = missingAccountToTerritoriesAssignments.get(missingOTA.ObjectId);
            if (missingTerritoryAssignments == null) {
                missingTerritoryAssignments = new List<String>();
                missingAccountToTerritoriesAssignments.put(missingOTA.ObjectId, missingTerritoryAssignments);
            }
            missingTerritoryAssignments.add(missingOTA.Territory2Id);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :missingAccountToTerritoriesAssignments.keySet()]);
        Map<Id, Territory2> territoryMap = new Map<Id, Territory2>(territories);
        List<String> missingAssignmentMessages = new List<String>();
        for (String accountIdWithMissingAssignments : missingAccountToTerritoriesAssignments.keySet()) {
            List<String> missingTerritoryIdAssignments = missingAccountToTerritoriesAssignments.get(accountIdWithMissingAssignments);
            List<String> missingTerritoryNames = new List<String>();
            for (String territoryId : missingTerritoryIdAssignments) {
                missingTerritoryNames.add(territoryMap.get(territoryId).Name);
            }
            missingAssignmentMessages.add(accountMap.get(accountIdWithMissingAssignments).Name + ' : ' + String.join(missingTerritoryNames, ', '));
        }
        return missingAssignmentMessages;
    }

    private Set<ObjectTerritory2Association> getMissingObjectTerritory2Associations(List<ObjectTerritory2Association> objectTerritoryAssociations, List<String> accountIds, List<String> territoryIds) {
        Set<ObjectTerritory2Association> expectedObjectTerritory2Associations = getExpectedObjectTerritory2Associations(accountIds, territoryIds);
        for (ObjectTerritory2Association ota : objectTerritoryAssociations) {
            // SObjects are equal when the fields are equal. This means the new ObjectTerritory2Association will correctly remove a matching ObjectTerritory2Association from our set.
            expectedObjectTerritory2Associations.remove(new ObjectTerritory2Association(
                ObjectId=ota.ObjectId,
                Territory2Id=ota.Territory2Id
            ));
        }
        return expectedObjectTerritory2Associations;
    }

    private Set<ObjectTerritory2Association> getExpectedObjectTerritory2Associations(List<String> accountIds, List<String> territoryIds) {
        Set<ObjectTerritory2Association> expectedObjectTerritory2Associations = new Set<ObjectTerritory2Association>();
        for (String territoryId : territoryIds) {
            for (String accountId : accountIds) {
                ObjectTerritory2Association ota = new ObjectTerritory2Association(
                    ObjectId=accountId,
                    Territory2Id=territoryId
                );
                expectedObjectTerritory2Associations.add(ota);
            }
        }
        return expectedObjectTerritory2Associations;
    }
}