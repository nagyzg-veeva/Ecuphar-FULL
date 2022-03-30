public with sharing class StakeholderNavigatorController {

    @AuraEnabled
    public static VeevaStakeholderNavigatorInitData initializeGraph(Id rootId) {
        ID accountId = VeevaStakeholderNavigatorQueryService.getAccountIdOfAccountPlan(rootId);
        VeevaStakeholderNavigatorInitData initData;
        if (accountId == null) {
            initData = getInitialData(rootId, null);
        } else {
            initData = getInitialData(accountId, rootId);
        }
        return initData;
    }

    @AuraEnabled
    public static VeevaStakeholderNavigatorHierarchyResult loadInitialHierarchy(Id rootId){
        return getHierarchy(new Set<Id>{rootId}, true);
    }

    @AuraEnabled
    public static VeevaStakeholderNavigatorHierarchyResult loadHierarchy(List<Id> ids){
        return getHierarchy(new Set<Id>(ids), false);
    }

    @AuraEnabled
    public static VeevaStakeholderNavigatorHierarchyResult loadParentHierarchy(Id childId){
        return getParentHierarchy(childId);
    }

    @AuraEnabled
    public static VeevaStakeholderNavigatorBatchResult loadAccountBatch(Id batchId, List<Id> accounts) {
        return getAccountBatch(batchId, accounts);
    }

    @AuraEnabled
    public static String checkPermissions(Id id) {
        return getPermissionErrorString(id);
    }

    private static VeevaStakeholderNavigatorInitData getInitialData(Id graphRootId, Id accountPlanId) {
        Map<String, String> veevaMessages = VeevaStakeholderNavigatorQueryService.getStakeholderNavigatorVeevaMessages();
        Map<String, Map<String, String>> objectTranslations = getObjectTranslations();
        Map<String, Map<String, String>> picklistTranslations = getPicklistTranslations();
        List<Id> keyStakeholders = null;
        if (accountPlanId != null && hasKeyStakeholderPermission()) {
            keyStakeholders = VeevaStakeholderNavigatorQueryService.getKeyStakeholders(accountPlanId);
        } else {
            keyStakeholders = new List<Id>();
        }
        return new VeevaStakeholderNavigatorInitData(graphRootId, keyStakeholders, veevaMessages, objectTranslations, picklistTranslations);
    }

    private static VeevaStakeholderNavigatorBatchResult getAccountBatch(Id batchId, List<Id> accounts) {
        VeevaStakeholderNavigatorBatchResult batchResult = new VeevaStakeholderNavigatorBatchResult(batchId);
        Set<Id> accountIdSet = new Set<Id>(accounts);
        addNodesToResult(batchResult, accountIdSet);
        try {
            addAffiliationsToResult(batchResult, accountIdSet);
        } catch(Exception e) {
            //affiliation object access is not required for SN to load
            //SN will simply load with no affiliations
            System.debug('No access to Affiliation Object');
        }
        return batchResult;
    }

    private static void addNodesToResult(VeevaStakeholderNavigatorBatchResult batchResult, Set<Id> accountIds) {
        List<VeevaStakeholderNavigatorNode> nodes = new List<VeevaStakeholderNavigatorNode>();
        Map<Id, Set<String>> accountToTerritoryMap = VeevaStakeholderNavigatorQueryService.getAccountToTerritoryMap(accountIds);
        List<Account> acctObjs = VeevaStakeholderNavigatorQueryService.getAccounts(accountIds);
        SObjectAccessDecision acctSecurity = Security.stripInaccessible(AccessType.READABLE, acctObjs);
        for (SObject acct : acctSecurity.getRecords()) {
            Id acctId = acct.Id;
            Set<String> territories = accountToTerritoryMap.get(acctId);
            nodes.add(new VeevaStakeholderNavigatorNode(acct, territories));
        }
        batchResult.addAccounts(nodes);
    }

    private static void addAffiliationsToResult(VeevaStakeholderNavigatorBatchResult batchResult, Set<Id> accountIds) {
        List<Affiliation_vod__c> affs = new List<Affiliation_vod__c>();
        //get heap limit with and subtract a buffer of 200KB
        Integer heapLimit = Limits.getLimitHeapSize() - 200000;
        //get CPU time limit and subtract a buffer of 1000ms
        Integer cpuLimit = Limits.getLimitCpuTime() - 1000;
        Integer counter = 0;
        for (Affiliation_vod__c aff : [
            SELECT From_Account_vod__c, To_Account_vod__c, Influence_vod__c, Relationship_Strength_vod__c, 
                   Role_vod__c, Therapeutic_Area_vod__c, Comments_vod__c
            FROM Affiliation_vod__c 
            WHERE From_Account_vod__c IN :accountIds
            LIMIT 49000
        ]) {
            affs.add(aff);
            if (math.mod(counter,10) == 0 && Limits.getHeapSize() > heapLimit && Limits.getCpuTime() > cpuLimit) {
                batchResult.setLimitTriggered(true);
                break;
            }
            counter++;
        }
        SObjectAccessDecision affSecurity = Security.stripInaccessible(AccessType.READABLE, affs);
        batchResult.addAffiliations(affSecurity.getRecords());
    }

    private static VeevaStakeholderNavigatorHierarchyResult getHierarchy(Set<Id> ids, Boolean isInitialHierarchy) {
        //Salesforce governer limit is 50000 query records per transaction.  
        //The initial query to getParentId has in indeterminate number of queries records based on number of parents
        //Thus, 50 queries records is subtracted from the 50000 limit to be safe
        Integer queryLimit = 49950;
        Boolean hasUnloadedParent = false;

        if (isInitialHierarchy && ids.size() == 1 && getParentId(new List<Id>(ids)[0]) != null) {
            hasUnloadedParent = true;
        }

        VeevaStakeholderNavigatorHierarchyResult firstLevel = getChildrenHierarchy(ids, queryLimit);
        Set<Id> firstLevelIds = new Set<Id>();
        for (Id acctId : ids) {
            Set<Id> children = firstLevel.hierarchy.get(acctId);
            if (children != null) {
                firstLevelIds.addAll(children);
            }
        }
        if (firstLevel.queryLimitTriggered || firstLevelIds == null || !isInitialHierarchy ) {
            firstLevel.setRootHasUnloadedParent(hasUnloadedParent);
            return firstLevel;
        }
        queryLimit = queryLimit - firstLevel.queryResultCount;

        VeevaStakeholderNavigatorHierarchyResult secondLevel = getChildrenHierarchy(firstLevelIds, queryLimit);
        if (secondLevel.queryLimitTriggered || firstLevelIds.size() > 499) {
            VeevaStakeholderNavigatorHierarchyResult mergedHierarchy = mergeHierarchies(new VeevaStakeholderNavigatorHierarchyResult[]{firstLevel, secondLevel}, 1);
            mergedHierarchy.setRootHasUnloadedParent(hasUnloadedParent);
            return mergedHierarchy;
        }
        queryLimit = queryLimit - secondLevel.queryResultCount;
        Set<Id> secondLevelIds = new Set<Id>();
        for (Id acctId : firstLevelIds) {
            Set<Id> children = secondLevel.hierarchy.get(acctId);
            if (children != null) {
                secondLevelIds.addAll(children);
            }
        }

        VeevaStakeholderNavigatorHierarchyResult thirdLevel = getChildrenHierarchy(secondLevelIds, queryLimit);
        VeevaStakeholderNavigatorHierarchyResult finalHierarchy = mergeHierarchies(new VeevaStakeholderNavigatorHierarchyResult[]{firstLevel, secondLevel, thirdLevel}, 2);
        finalHierarchy.setRootHasUnloadedParent(hasUnloadedParent);
        return finalHierarchy;
    }

    private static VeevaStakeholderNavigatorHierarchyResult getParentHierarchy(Id childId) {
        Integer queryLimit = 49950;
        Id rootId = getParentId(childId);
        Boolean newRootHasParent = hasParent(rootId);

        VeevaStakeholderNavigatorHierarchyResult firstLevel = getChildrenHierarchy(new Set<Id>{rootId}, queryLimit);
        Set<Id> firstLevelIds = new Set<Id>();
        Set<Id> children = firstLevel.hierarchy.get(rootId);
        if (children != null) {
            firstLevelIds.addAll(children);
        }
        Boolean containsRootChild = firstLevelIds.contains(childId);
        if (firstLevel.queryLimitTriggered || firstLevelIds == null) {
            //check to ensure the childId was included in the children list
            if (!containsRootChild) {
                children.add(childId);
            }
            firstLevel.setNewRoot(rootId);
            firstLevel.setRootHasUnloadedParent(newRootHasParent);
            return firstLevel;
        }

        if (containsRootChild) {
            firstLevelIds.remove(childId);
        }

        queryLimit = queryLimit - firstLevel.queryResultCount;
        VeevaStakeholderNavigatorHierarchyResult secondLevel = getChildrenHierarchy(firstLevelIds, queryLimit);
        VeevaStakeholderNavigatorHierarchyResult mergedHierarchy = mergeHierarchies(new VeevaStakeholderNavigatorHierarchyResult[]{firstLevel, secondLevel}, 1);
        mergedHierarchy.setNewRoot(rootId);
        mergedHierarchy.setRootHasUnloadedParent(newRootHasParent);
        return mergedHierarchy;
    }

    private static VeevaStakeholderNavigatorHierarchyResult mergeHierarchies(List<VeevaStakeholderNavigatorHierarchyResult> hierarchyResults, Integer depth) {
        Map<Id, Set<Id>> mergedHierarchy = new Map<Id, Set<Id>>();
        Set<Id> rootAccounts = new Set<Id>();
        Integer mergedQueryResultCount = 0;
        Boolean mergedQueryLimitTriggered = false;
        for (Integer i = 0; i < hierarchyResults.size(); i++) {
            VeevaStakeholderNavigatorHierarchyResult hierarchyResult = hierarchyResults.get(i);
            if (i == 0) {
                rootAccounts = hierarchyResult.rootAccounts;
            }
            mergedHierarchy.putAll(hierarchyResult.hierarchy);
            mergedQueryResultCount += hierarchyResult.queryResultCount;
            mergedQueryLimitTriggered = mergedQueryLimitTriggered || hierarchyResult.queryLimitTriggered;
        }
        return new VeevaStakeholderNavigatorHierarchyResult(mergedHierarchy, rootAccounts, mergedQueryResultCount, mergedQueryLimitTriggered, depth);
    }

    public static VeevaStakeholderNavigatorHierarchyResult getChildrenHierarchy(Set<Id> parentIds, Integer queryLimit){
        Integer queryCounter = 0;
        Map<Id, Set<Id>> hierarchy = new Map<Id, Set<Id>>();
        List<Id> childrenToVerify = new List<Id>();
        for (Child_Account_vod__c child : [
            SELECT Parent_Account_vod__c, Child_Account_vod__c, Primary_vod__c, Parent_Account_vod__r.Formatted_Name_vod__c, Child_Account_vod__r.Primary_Parent_vod__c
            FROM Child_Account_vod__c 
            WHERE Parent_Account_vod__c in :parentIds
            LIMIT :queryLimit
        ]) {
            queryCounter++;
            if (child.Child_Account_vod__r.Primary_Parent_vod__c == child.Parent_Account_vod__c) {
                //if primary then no need to check if there exists a "better" parent
                if (!hierarchy.containsKey(child.Parent_Account_vod__c)) {
                    hierarchy.put(child.Parent_Account_vod__c, new Set<Id>());
                }
                hierarchy.get(child.Parent_Account_vod__c).add(child.Child_Account_vod__c);
            } else {
                childrenToVerify.add(child.Child_Account_vod__c);
            }
        }

        //if non-primary, all Child_Account records need to be checked for multiple parents and the best one chosen
        Map<Id, Child_Account_vod__c> childToParentMap = new Map<Id, Child_Account_vod__c>();

        Integer newLimit = queryLimit - queryCounter;
        for (Child_Account_vod__c child : [
            SELECT Parent_Account_vod__c, Child_Account_vod__c, Primary_vod__c, Parent_Account_vod__r.Formatted_Name_vod__c, Child_Account_vod__r.Primary_Parent_vod__c
            FROM Child_Account_vod__c 
            WHERE Child_Account_vod__c in :childrenToVerify
            LIMIT :newLimit
        ]) {
            queryCounter++;
            Id childId = child.Child_Account_vod__c;
            if (isValidChildAccountRecord(child)) {
                Child_Account_vod__c oldChild = childToParentMap.get(childId);
                if (isBetterChildAcct(oldChild, child)) {
                    childToParentMap.put(childId, child);
                }
            }
        }

        //go through non-primary "winners" and add them to hierarchy
        for (Child_Account_vod__c child : childToParentMap.values()) {
            if (parentIds.contains(child.Parent_Account_vod__c)) {
                if (!hierarchy.containsKey(child.Parent_Account_vod__c)) {
                     hierarchy.put(child.Parent_Account_vod__c, new Set<Id>());
                }
                hierarchy.get(child.Parent_Account_vod__c).add(child.Child_Account_vod__c);
            }
        }

        return new VeevaStakeholderNavigatorHierarchyResult(hierarchy, parentIds, queryCounter, queryCounter == queryLimit, 1);
    }

    private static Map<String, Map<String, String>> getObjectTranslations() {
        List<String> accountFields = new List<String>{'Specialty_1_vod__c', 'Specialty_2_vod__c', 'Group_Specialty_1_vod__c', 'Group_Specialty_2_vod__c', 'Account_Identifier_vod__c', 'PersonEmail', 'Phone'};
        Map<String, String> accountTranslations = getObjectTranslation(Account.sObjectType.getDescribe(), accountFields);

        List<String> affFields = new List<String>{'From_Account_vod__c', 'To_Account_vod__c', 'Influence_vod__c', 'Relationship_Strength_vod__c', 'Role_vod__c', 'Therapeutic_Area_vod__c', 'Comments_vod__c'};
        Map<String, String> affTranslations = getObjectTranslation(Affiliation_vod__c.sObjectType.getDescribe(), affFields);

        Map<String, Map<String, String>> objectTranslations = new Map<String, Map<String, String>>();
        objectTranslations.put('account', accountTranslations);
        objectTranslations.put('affiliation', affTranslations);
        
        return objectTranslations;
    }

    private static Map<String, String> getObjectTranslation(DescribeSObjectResult obj, List<String> fieldNames) {
        Map<String, String> objectTranslations = new Map<String, String>();
        Map<String, SObjectField> fields = obj.fields.getMap();
        for (String field : fieldNames) {
            SObjectField fieldObj = fields.get(field);
            if (fieldObj != null) {
                objectTranslations.put(field, fieldObj.getDescribe().getLabel());
            }
        }
        return objectTranslations;
    }

    private static Map<String, Map<String, String>> getPicklistTranslations() {
        List<String> accountFields = new List<String>{'Specialty_1_vod__c', 'Group_Specialty_1_vod__c', 'Group_Specialty_1_vod__c', 'Group_Specialty_2_vod__c'};
        List<String> affFields = new List<String>{'Relationship_Strength_vod__c', 'Role_vod__c', 'Influence_vod__c', 'Therapeutic_Area_vod__c'};

        Map<String, Map<String, String>> picklistTranslations = getObjectPicklistTranslation(Account.sObjectType.getDescribe(), accountFields);
        picklistTranslations.putAll(getObjectPicklistTranslation(Affiliation_vod__c.sObjectType.getDescribe(), affFields));

        return picklistTranslations;
    }

    private static Map<String, Map<String, String>> getObjectPicklistTranslation(DescribeSObjectResult obj, List<String> fieldNames) {
        Map<String, Map<String, String>> picklistTranslations = new Map<String, Map<String, String>>();
        Map<String, SObjectField> fields = obj.fields.getMap();
        for (String field : fieldNames) {
            SObjectField fieldObj = fields.get(field);
            if (fieldObj != null) {
                picklistTranslations.put(field, toTranslationMap(fieldObj.getDescribe().getPicklistValues()));
            }
        }
        return picklistTranslations;
    }

    private static Map<String, String> toTranslationMap(List<PicklistEntry> picklists) {
        Map<String, String> translationMap = new Map<String, String>();
        for (PicklistEntry p : picklists) {
            translationMap.put(p.getValue(), p.getLabel());
        }
        return translationMap;
    }

    private static Boolean hasParent(Id id) {
        ID parentId = getParentId(id);
        return parentId != null;
    }

    private static Boolean isValidChildAccountRecord(Child_Account_vod__c child) {
        return child.Parent_Account_vod__c != null &&
               child.Child_Account_vod__c != null &&
               String.isNotBlank(child.Parent_Account_vod__r.Formatted_Name_vod__c);
    }

    private static Id getParentId(Id id) {
        List<Child_Account_vod__c> allRelationships = VeevaStakeholderNavigatorQueryService.getParentChildRelationshipsFromChild(new List<Id>{id});
        Child_Account_vod__c winner = null;
        for (Child_Account_vod__c childAcct : allRelationships) {
            if (isValidChildAccountRecord(childAcct) && isBetterChildAcct(winner, childAcct)) {
                winner = childAcct;
            }
        }
        return winner != null ? winner.Parent_Account_vod__c : null;
    }

    @TestVisible
    private static Boolean isBetterChildAcct(Child_Account_vod__c oldChild, Child_Account_vod__c newChild) {
        return (
            oldChild == null || 
            newChild.Parent_Account_vod__c == newChild.Child_Account_vod__r.Primary_Parent_vod__c ||
            (oldChild.Parent_Account_vod__c != oldChild.Child_Account_vod__r.Primary_Parent_vod__c && 
                newChild.Parent_Account_vod__r.Formatted_Name_vod__c.compareTo(oldChild.Parent_Account_vod__r.Formatted_Name_vod__c) < 0)
        );
    }

    private static String getPermissionErrorString(Id id) {
        //first check if user has access to root account of stakeholder navigator
        Id accountId = VeevaStakeholderNavigatorQueryService.getAccountIdOfAccountPlan(id);
        if (accountId == null) {
            accountId = id;
        }
        if (!VeevaStakeholderNavigatorQueryService.hasAccountAccess(accountId)) {
            String defaultString = 'Stakeholder Navigator cannot open because you do not have access to this Account.';
            String vm = VeevaStakeholderNavigatorQueryService.getSNVeevaMessageWithDefault('NO_ACCOUNT_ACCESS', defaultString);
            return vm;
        }

        //then check that object and field permission
        List<String> objectsWithoutPermission = getObjectsWithoutPermissions();
        List<String> fieldsWithoutPermission = getFieldsWithoutPermissions();

        if (objectsWithoutPermission.size() > 0 || fieldsWithoutPermission.size() > 0) {
            String defaultString = 'Stakeholder Navigator cannot open because you do not have access to the following:\nObjects: {0}\nObject Fields: {1}';
            String vm = VeevaStakeholderNavigatorQueryService.getSNVeevaMessageWithDefault('NO_FLS_ACCESS', defaultString);
            vm = vm.replace('{0}', String.join(objectsWithoutPermission, ', '));
            vm = vm.replace('{1}', String.join(fieldsWithoutPermission, ', '));
            return vm;
        }

        return '';
    }

    private static List<String> getObjectsWithoutPermissions() {
        List<String> objectsWithoutPermission = new List<String>();
        DescribeSobjectResult accountObj = Account.sObjectType.getDescribe();
        DescribeSobjectResult childAccountObj = Child_Account_vod__c.sObjectType.getDescribe();
        if (!accountObj.isQueryable() || !accountObj.isAccessible()) {
            objectsWithoutPermission.add(accountObj.getName());
        }
        if (!childAccountObj.isQueryable() || !childAccountObj.isAccessible()) {
            objectsWithoutPermission.add(childAccountObj.getName());
        }
        return objectsWithoutPermission;
    }

    private static List<String> getFieldsWithoutPermissions() {
        List<String> fieldsWithoutPermission = new List<String>();
        List<String> accountFields = new List<String>{'Id', 'Formatted_Name_vod__c'};
        List<String> childAccountFields = new List<String>{'Id', 'Child_Account_vod__c', 'Parent_Account_vod__c', 'Primary_vod__c'};

        fieldsWithoutPermission.addAll(checkObjectFieldPermissions(Account.sObjectType.getDescribe(), accountFields));
        fieldsWithoutPermission.addAll(checkObjectFieldPermissions(Child_Account_vod__c.sObjectType.getDescribe(), childAccountFields));

        return fieldsWithoutPermission;
    }

    private static List<String> checkObjectFieldPermissions(DescribeSObjectResult obj, List<String> fields) {
        List<String> fieldsWithoutPermission = new List<String>();
        String objectlabel = obj.getName();
        Map<String, SObjectField> objectFields = obj.fields.getMap();
        for (String field : fields) {
            SObjectField objectField = objectFields.get(field);
            if (objectField == null) {
                //field doesn't exist in org or user does not have visibility
                fieldsWithoutPermission.add(objectLabel + '.' + field);
                continue;
            }
            DescribeFieldResult fieldResult = objectField.getDescribe();
            if (!fieldResult.isAccessible()) {
                fieldsWithoutPermission.add(objectLabel + '.' + fieldResult.getName());
            }
        }
        return fieldsWithoutPermission;
    }

    private static Boolean hasKeyStakeholderPermission() {
        DescribeSobjectResult keyStakeholderObj = Key_Stakeholder_vod__c.sObjectType.getDescribe();
        if (keyStakeholderObj != null && keyStakeholderObj.isQueryable() && keyStakeholderObj.isAccessible()) {
            DescribeFieldResult accountPlanField = Key_Stakeholder_vod__c.Account_Plan_vod__c.getDescribe();
            if (accountPlanField != null && accountPlanField.isAccessible()) {
                return true;
            }
        }
        return false;
    }
}