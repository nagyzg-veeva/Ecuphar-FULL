public without sharing class VeevaAccountPlanSharingDeleteLogic {


    private List<SObject> toDeleteObjects = new List<SObject> ();
    private VeevaAccountPlanHierarchy accountPlanHierarchy;
    private Set<Id> accountPlanIds = new Set<Id> ();
    private Set<Id> userIds = new Set<Id> ();

    public VeevaAccountPlanSharingDeleteLogic(VeevaAccountPlanHierarchy accountHierarchy) {
        this.accountPlanHierarchy = accountHierarchy;
    }

    public void deleteSharingRules(List<SObject> objectList) {

        // only delete for account team member
        handleAccountTeamMember(objectList);
        deleteAll();
    }

    private void processHierarchy() {

        List<String > objectHierarchy = accountPlanHierarchy.getObjectHierarchy();
        Set<Id> processedIds = new Set<Id> ();
        for (integer position=0; position <  objectHierarchy.size(); position++) {
            String objName = objectHierarchy[position];
            if (position == 0) {
                processedIds = firstLevelShareDelete(objName, getLookUpFieldName(objName));
            } else {
                processedIds = nextLevelShareDelete (processedIds, objName, getLookUpFieldName(objName));
            }
        }
    }

    private String getLookUpFieldName(String objectName) {
        return accountPlanHierarchy.getFieldName(objectName);
    }


    private void handleAccountTeamMember(List<SObject> objectList ) {
        processAccountTeamMembers(objectList);
        processHierarchy();
    }

    private void processAccountTeamMembers(List<SObject> objectList) {

        // this is the list of account team members that come in when account team members are deleted
        List<String> accountPlanToUserIds = new List<String> ();
        for (SObject teamMember : objectList) {
            if ((Id) teamMember.get('Account_Plan_vod__c') != null) {
                accountPlanIds.add((Id) teamMember.get('Account_Plan_vod__c'));
            }
            if ((Id) teamMember.get('Team_Member_vod__c') != null ) {
                userIds.add((Id) teamMember.get('Team_Member_vod__c'));
            }
            String externalId = (String) teamMember.get('Account_Plan_vod__c') + (String) teamMember.get('Team_Member_vod__c');
            accountPlanToUserIds.add(externalId);
        }
        if (accountPlanIds.size() > 0   &&  userIds.size() > 0) {
            accountPlanShareTableDelete(accountPlanToUserIds);
        }
    }


    private void accountPlanShareTableDelete(List<String> externalIds) {

       if (Schema.getGlobalDescribe().get('Account_Plan_vod__Share') != null) {
            List<SObject> accountPlanShares = Database.query('SELECT Id, ParentId, UserOrGroupId, RowCause FROM Account_Plan_vod__Share WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND ParentId IN : accountPlanIds AND UserOrGroupId IN : userIds' );
            for (SObject shareRec : accountPlanShares) {
                // pick the right account plan and user to
                String externalId  = (String) shareRec.get('ParentId') + (String) shareRec.get('UserOrGroupId');
                if (externalIds.contains(externalId)) {
                    toDeleteObjects.add(shareRec);
                }
            }
       }
    }

    private Set<Id> getParentIds(List<SObject> objectList) {
        Set<Id> currentObjectIds = new Set<Id> ();
        for (SObject obj : objectList) {
            currentObjectIds.add((Id) obj.get('ParentId'));
        }
        return currentObjectIds;

    }


    private Set<Id> nextLevelShareDelete(Set<Id> previousLookupIds, String currentObjectName, String lookupFieldName) {

        String shareTableName = currentObjectName.replace('__c', '__share');
        List<SObject> nextLevelDeleteObjects = null;

        if (Schema.getGlobalDescribe().get(shareTableName) != null) {
            String selectString = ' SELECT  Id, ParentId, UserOrGroupId, Parent.' + lookupFieldName + ', RowCause FROM  ' + shareTableName ;
            String whereClause = ' WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND Parent.' + lookupFieldName + ' IN : previousLookupIds AND  UserOrGroupId IN : userIds' ;
            nextLevelDeleteObjects = Database.Query(selectString + whereClause) ;
            toDeleteObjects.addAll(nextLevelDeleteObjects);
        }
        return getParentIds(nextLevelDeleteObjects);
    }


    private Set<Id> firstLevelShareDelete (String currentObjectName, String lookupFieldName) {


        String shareTableName = currentObjectName.replace('__c', '__share');
        List<SObject> firstLevelDeleteObjects = null;

        if (Schema.getGlobalDescribe().get(shareTableName) != null) {
            String selectString = ' SELECT  Id, ParentId, UserOrGroupId, Parent.' + lookupFieldName + ', RowCause FROM  ' + shareTableName ;
            String whereClause = ' WHERE RowCause = \'Veeva_Account_Plan_Sharing_vod__c\' AND Parent.' + lookupFieldName + ' IN : accountPlanIds  AND  UserOrGroupId IN : userIds' ;

            firstLevelDeleteObjects = Database.query(selectString + whereClause);
            toDeleteObjects.addAll(firstLevelDeleteObjects);
        }
        return getParentIds(firstLevelDeleteObjects);
    }


    private void deleteAll() {

        if (toDeleteObjects.size() > 0) {
            List<Database.DeleteResult> deleteResults = Database.delete(toDeleteObjects, false);
            for (Database.DeleteResult result : deleteResults) {
                if (!result.isSuccess()) {
                    system.debug('delete error: ' + result.getErrors()[0]);
                }
            }

        }
    }


}