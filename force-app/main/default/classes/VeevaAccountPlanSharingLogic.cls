public without sharing class VeevaAccountPlanSharingLogic {

    /* this class is used for updating sharing rules for account plan hierarchy
    * This class has logic for upsert of account team member , also for the object in hierarchy
    */

    private Set<Id> inActiveUsersId = new Set<Id>();
    private Set<Id> checkedUserIds = new Set<Id>();
    private Set<Id> toDeleteIds = new Set<Id>();
    private Set<Id> userIds = new Set<Id>();
    private VeevaAccountPlanHierarchy accountPlanHierarchy;
    private Map<Id, Account_Team_Member_vod__c> accountTeamMembers = new Map<Id, Account_Team_Member_vod__c>();
    private Boolean isDeleteNeeded = false;
    private Boolean isEntryAccountTeamMember = false;
    private Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();



    public VeevaAccountPlanSharingLogic(VeevaAccountPlanHierarchy acctHierarchy) {
        this.accountPlanHierarchy = acctHierarchy;
    }

    public void calculateSharingRules (List<SObject> objectList, String objectName, Boolean doWeDelete) {
        // go through the objects and process
        isDeleteNeeded = doWeDelete;
        if (objectName == 'Account_Team_Member_vod__c') {
            isEntryAccountTeamMember = true;
            processAccountTeamMembers(objectList);
        } else {
            prepareProcessHierarchy(objectList, objectName);
        }
    }

    private void processAccountTeamMembers(List<SObject> objectList) {
        Set<Id> accountPlanIds = accountTeamMemberSharingUpdate(objectList);
        // before process the full hierarchy get the first level objects that match the account plan
        String objectName = getObjectName(0);
        List<SObject> firstLevelObjects = queryFirstLevelObjects(objectName, accountPlanIds, getLookUpFieldName(objectName));
        processHierarchy(firstLevelObjects, accountTeamMembers, 0);
    }

    private void prepareProcessHierarchy(List<SObject> objectList, String objectName ) {

        Integer position = accountPlanHierarchy.getObjectPosition(objectName);
        if (position == -1 ) {
            return;
        }
        Map<Id, Account_Team_Member_vod__c> accountTeamMemberMap = new Map<Id, Account_Team_Member_vod__c> ();
        Set<Id> accountPlanIds = new Set<Id> ();
        if (position == 0) {
            String firstLevelObjectName = getObjectName(0);
            accountPlanIds = getAccountPlanIds(objectList, getLookUpFieldName(firstLevelObjectName));
            accountTeamMemberMap = getAccountTeamMembers(accountPlanIds);
        }
        processHierarchy(objectList, accountTeamMemberMap, position);

    }


    private void processHierarchy(List<SObject> objectList, Map<Id, Account_Team_Member_vod__c> acctTeamMembersMap, Integer positionAt) {
        List<String > objectHierarchy = accountPlanHierarchy.getObjectHierarchy();
        Set<Id> processedIds = new Set<Id> ();
        for (Integer position=positionAt; position <  objectHierarchy.size(); position++) {
            String objName = objectHierarchy[position];
            if (position == 0) {
                processedIds = firstLevelSharingRulesCalculate(objectList, objName, acctTeamMembersMap);
            } else if (position == positionAt) {
                processedIds = getNextLevelLookupIDs(objectList, getLookUpFieldName(objName));
                processedIds = nextLevelSharingRulesCalculate(processedIds, getLookUpFieldName(objName), objName, objectList);
            } else {
                List<SObject> nextLevelObjectList = queryNextLevel(getLookUpFieldName(objName), objName, processedIds);
                processedIds = nextLevelSharingRulesCalculate(processedIds, getLookUpFieldName(objName), objName, nextLevelObjectList);

            }
        }
    }

    private String getLookUpFieldName(String objectName) {
        return accountPlanHierarchy.getFieldName(objectName);
    }

    private String getObjectName(Integer position) {
        return accountPlanHierarchy.getObjectName(position);
    }

    private Set<Id> accountTeamMemberSharingUpdate(List<Account_Team_Member_vod__c> objectList) {

        List<Account_Team_Member_vod__c> membersWithAccess = new List<Account_Team_Member_vod__c>();
        Set<Id> accountPlanIds = new Set<Id> ();
        // get the users id for inactive user id query
        for (Account_Team_Member_vod__c  actTeamMember : objectList) {
            userIds.add(actTeamMember.Team_Member_vod__c);

        }
        VeevaKamUtils.updateInactiveUserIds(userIds, checkedUserIds, inActiveUsersId);

        for (Account_Team_Member_vod__c  actTeamMember : objectList) {
            if (actTeamMember.Access_vod__c == null || actTeamMember.Account_Plan_vod__c == null || actTeamMember.Team_Member_vod__c == null || (inActiveUsersId != null && inActiveUsersId.contains(actTeamMember.Team_Member_vod__c))) {
                continue;
            }
            membersWithAccess.add(actTeamMember);
            accountTeamMembers.put( actTeamMember.Id , actTeamMember);
            accountPlanIds.add(actTeamMember.Account_Plan_vod__c);
        }
        accountPlanSharingEntry(membersWithAccess);

        return accountPlanIds;

    }


    private void accountPlanSharingEntry(List<Account_Team_Member_vod__c> membersWithAccess) {

        /* no need to remove the share entry for account plan share business case as follows
        * Account team member (ATM) 1 is modified now with AP1 and User1 with some access say Read.
        * There may be exact same record of Account member which did not make it part of this upsert so we can not delete share records for account plan
        */
        List<SObject> accountPlanShareObjects = new List<SObject> ();
        Set<Id> accountPlanIds = new Set<Id> ();
        if (globalDescribe.get('Account_Plan_vod__Share') != null ) {
            for (Account_Team_Member_vod__c actTeamMember : membersWithAccess) {
                // for all entries of account team member add share entries for account plan
                accountPlanIds.add(actTeamMember.Account_Plan_vod__c);
                SObject accountPlanShare = createShareObject('Account_Plan_vod__Share', actTeamMember.Account_Plan_vod__c, actTeamMember.Team_Member_vod__c, actTeamMember.Access_vod__c);
                accountPlanShareObjects.add(accountPlanShare);
            }
            if (accountPlanShareObjects.size() > 0) {
                insert accountPlanShareObjects;
            }
        }
    }

    private List<SObject> queryFirstLevelObjects(String objectName, Set<Id> accountPlanIds, String lookupFieldName) {
        String selectString = 'Select Id, ' + lookupFieldName + ', Share_With_vod__c from ' + objectName;
        List<SObject>  processObjectList = Database.query(selectString + ' where  ' + lookupFieldName + '  in : accountPlanIds');
        return processObjectList;
    }

    private Set<Id> getAccountPlanIds(List<SObject> objectList, String lookupFieldName) {
        // for the first level get the account plan ids from the objects came from the trigger
        Set<Id> accountPlanIds = new Set<Id> ();
        for(SObject obj : objectList) {
            accountPlanIds.add((Id)obj.get(lookupFieldName));
        }
        return accountPlanIds;
    }

    private Map<Id, Account_Team_Member_vod__c> getAccountTeamMembers(Set<Id> accountPlanIds) {

        // used by the first level entry we need to query the account team member for the account plans that is matching
        Map<Id, Account_Team_Member_vod__c> accountTeamMembers = new Map<Id, Account_Team_Member_vod__c>
                ([SELECT Id, Name, Account_Plan_vod__c, Team_Member_vod__c, Role_vod__c, Access_vod__c FROM Account_Team_Member_vod__c WHERE Account_Plan_vod__c IN :accountPlanIds]);
        return accountTeamMembers;
    }


    private Set<Id> firstLevelSharingRulesCalculate (List<SObject> objectList, String objectName, Map<Id, Account_Team_Member_vod__c> accountTeamMembers ) {

        /* since this is first level we will update based on share with and account plan using the object list query for all the account team members
         *  whose share with value matches the account team member and find all the account plan ids
         */

        Map<Id, Set<Id>> teamMembersToObjectIds = new Map<Id, Set<Id>>();

        // query
        Set<Id> userIds = new Set<Id> ();
        for (Account_Team_Member_vod__c teamMember : accountTeamMembers.values()) {
            userIds.add(teamMember.Team_Member_vod__c);
        }
        VeevaKamUtils.updateInactiveUserIds(userIds, checkedUserIds, inActiveUsersId);

        String lookupFieldName = getLookUpFieldName(objectName);

        for (SObject obj : objectList) {
            Id acctPlan = (Id) obj.get(lookupFieldName);
            String shareWithValues = (String) obj.get('Share_With_vod__c');
            Id objectId = (Id) obj.get('Id');
            toDeleteIds.add(objectId);
            for (Account_Team_Member_vod__c teamMember : accountTeamMembers.values()) {
                if (acctPlan == teamMember.Account_Plan_vod__c ) {
                    if (teamMember.Team_Member_vod__c == null || (inActiveUsersId != null && inActiveUsersId.contains(teamMember.Team_Member_vod__c))) {
                        toDeleteIds.add(objectId);
                        continue;
                    }
                    if (shareWithValues != null &&  teamMember.Role_vod__c != null && teamMember.Access_vod__c != null && shareWithValues.contains(teamMember.Role_vod__c)) {
                        Set<Id> objectIDsList = teamMembersToObjectIds.get(teamMember.Id);
                        if (objectIDsList == null) {
                            objectIDsList = new Set<Id>();
                        }
                        objectIDsList.add(objectId);
                        teamMembersToObjectIds.put(teamMember.Id, objectIDsList);
                    } else {
                        // deletion path
                        toDeleteIds.add(objectId);
                    }
                }
            }
        }

        Set<Id> processedIds = firstLevelSharingRulesUpdate(accountTeamMembers, teamMembersToObjectIds,  objectName);
        return processedIds;
    }


    private Set<Id> firstLevelSharingRulesUpdate (Map<Id, Account_Team_Member_vod__c> accountTeamMembers, Map<Id, Set<Id>> teamMembersToObjectIds, String objectName)  {

        String shareTableName = objectName.replace('__c', '__share');
        List<SObject> shareObjects = new List<SObject> ();
        Set<Id> processedIds = new Set<Id> ();

        if (globalDescribe.get(shareTableName) != null) {
            for (Id teamMemberId : teamMembersToObjectIds.keySet()) {
                Account_Team_Member_vod__c teamMember = accountTeamMembers.get(teamMemberId);
                Set<Id> objectIds = teamMembersToObjectIds.get(teamMemberId);
                for (Id objectId : objectIds) {
                    // add the plan tactic ids
                    processedIds.add(objectId);
                    // need to update the plan tactic share
                    SObject newShareObj = createShareObject(shareTableName, objectId, teamMember.Team_Member_vod__c, teamMember.Access_vod__c);
                    shareObjects.add(newShareObj);
                }
            }
        }
        deleteShareRecords(shareTableName, toDeleteIds);
        if (shareObjects.size() > 0 )  {
            insert shareObjects;
        }
        return processedIds;
    }


    private void addDeleteForNextLevel(String lookupFieldName, String currentObjectName, String shareTableNameCurrentLevel ) {

        String selectClauseDelete = 'Select Id ,' + lookupFieldName + ' from ' + currentObjectName;
        String whereClauseDelete = ' where ' + lookupFieldName + ' in : toDeleteIds';

        Map<Id, SObject> sObjectsMap = new Map<Id, SObject>(Database.query(selectClauseDelete + whereClauseDelete));

        // let this be the delete ids for the next level
        toDeleteIds.clear();
        toDeleteIds.addAll(sObjectsMap.keySet());
        deleteShareRecords(shareTableNameCurrentLevel, toDeleteIds);

    }

    private List<SObject> queryNextLevel (String lookupFieldName, String currentObjectName, Set<Id> lookupIds ) {

        String selectClause = 'Select Id ,' + lookupFieldName + ' from ' + currentObjectName;
        String whereClause = ' where ' + lookupFieldName + ' in : lookupIds';
        List<SObject> currentObjects = Database.query( selectClause + whereClause );
        return currentObjects;

    }

    private Set<Id> getNextLevelLookupIDs (List<SObject> objectList, String lookupFieldName) {
        Set<Id> lookupIds = new Set<Id> ();
        for (SObject obj : objectList) {
            lookupIds.add((Id) obj.get(lookupFieldName));
        }
        return lookupIds;
    }

    private Set<Id> nextLevelSharingRulesCalculate(Set<Id> lookupIds, String lookupFieldName, String currentObjectName, List<SObject> objectList) {

        String shareTableNameCurrentLevel = currentObjectName.replace('__c', '__share');

        // delete is needed in the next level only if entry point is account
        if (isDeleteNeeded) {
            addDeleteForNextLevel(lookupFieldName, currentObjectName, shareTableNameCurrentLevel);
        }

        Map<Id, Id> currentObjectPreviousObjectMap = new Map<Id, Id> ();
        // we need the current object id to make entry into the share table

        for (SObject obj : objectList ) {
            currentObjectPreviousObjectMap.put((Id) obj.get('Id'), (Id) obj.get(lookupFieldName));
        }

        String shareTableNamePreviousLevel = lookupFieldName.replace('__c', '__share');


        List<SObject> shareRecordsList = new List<SObject>();

        if (globalDescribe.get(shareTableNamePreviousLevel) != null )  {

            String selectShareClause = ' SELECT Id, ParentId, AccessLevel, UserOrGroupId, RowCause FROM ' + shareTableNamePreviousLevel ;
            String whereShareClause = ' WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' and ParentId in : lookupIds AND UserOrGroupId != NULL';

            List<SObject> previousLevelShares = Database.query(selectShareClause + whereShareClause);

            Set<Id> idsToCheck = new Set<Id>();
            for (SObject shareRecord: previousLevelShares) {
                shareRecordsList.add(shareRecord);
                idsToCheck.add((Id) shareRecord.get('UserOrGroupId'));
            }
            VeevaKamUtils.updateInactiveUserIds(idsToCheck, checkedUserIds, inActiveUsersId);
        }

        Set<Id> processedIds = nextLevelSharingRulesUpdate(currentObjectPreviousObjectMap, shareRecordsList, currentObjectName);
        return processedIds;

    }

    private Set<Id> nextLevelSharingRulesUpdate( Map<Id, Id> currentObjectPreviousObjectMap, List<SObject> shareRecords, String currentObjectName) {
        /* with the previous object name and look up ids query share table
        * for the current object with the object name query the field with name lookupFieldName and use the look up ids. For the queried result qualifies for entry into share table
         *
         */

        String shareTableNameCurrentLevel = currentObjectName.replace('__c', '__share');

        // now move on to see if any records need to be added to sharing
        // for the current level use the previous level share and insert for the current ids
        Set<Id> processedIds = new Set<Id> ();
        List<SObject> toInsertSObjects = new List<SObject> ();

        for(Id objId: currentObjectPreviousObjectMap.keySet()) {
            Id previousLevelLookup = currentObjectPreviousObjectMap.get(objId);
            for (SObject shareRecord : shareRecords) {
                if (inActiveUsersId.contains((Id) shareRecord.get('UserOrGroupId'))) {
                    continue;
                }
                Id parentId = (Id) shareRecord.get('ParentId');
                if (parentId == previousLevelLookup) {
                    processedIds.add(objId);
                    if (globalDescribe.get(shareTableNameCurrentLevel) != null) {
                        SObject currentObjectShare = createShareObject(shareTableNameCurrentLevel, objId, (String) shareRecord.get('UserOrGroupId'), (String) shareRecord.get('AccessLevel'));
                        toInsertSObjects.add(currentObjectShare);
                    }
                }
            }
        }

        if (toInsertSObjects.size() > 0)  {
            insert toInsertSObjects;
        }

        return processedIds;
    }

    private SObject createShareObject (String shareTableName, String parentId, String userId, String accessLevel) {
        SObject currentObjectShare = globalDescribe.get(shareTableName).newSObject();
        currentObjectShare.put('ParentId', parentId);
        currentObjectShare.put('UserOrGroupId', userId) ;
        currentObjectShare.put('RowCause', 'Veeva_Account_Plan_Sharing_vod__c');
        if (accessLevel == 'Read_vod' || accessLevel == 'Read') {
            currentObjectShare.put('AccessLevel', 'Read');
        } else if (accessLevel == 'Edit_vod' || accessLevel == 'Edit') {
            currentObjectShare.put('AccessLevel', 'Edit');
        }
        return currentObjectShare;
    }



    // delete all the share record before inserting because something might have changed like the user in team member changed, share with changed or role changed
    // also something changed in the first level then delete the lower levels
    private void deleteShareRecords(String shareTableName, Set<Id> deleteIds) {
        // no need to  run the query for delete in case of insert
        if (globalDescribe.get(shareTableName) != null && isDeleteNeeded) {
            String selectString  = '';
            if (isEntryAccountTeamMember) {
                selectString = ' SELECT Id, UserOrGroupId FROM  ' + shareTableName + ' WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND ParentId IN :deleteIds AND UserOrGroupId IN : userIds';
            } else {
                selectString = ' SELECT Id, UserOrGroupId FROM  ' + shareTableName + ' WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND ParentId IN :deleteIds';
            }
            List<SObject> objectShares = Database.query(selectString);
            if (objectShares.size() > 0) {
                List<Database.DeleteResult> deleteResults = Database.delete(objectShares, false);
                // before calling the delete
                for (Database.DeleteResult result : deleteResults) {
                    if (!result.isSuccess()) {
                        System.debug('delete error: ' + result.getErrors()[0]);
                    }
                }
            }

        }

    }

}