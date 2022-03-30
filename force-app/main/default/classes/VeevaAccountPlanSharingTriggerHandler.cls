public virtual without sharing class VeevaAccountPlanSharingTriggerHandler {

    private VeevaAccountPlanHierarchy acctHierarchy;
    public VeevaAccountPlanSharingTriggerHandler() {
        acctHierarchy = new VeevaAccountPlanHierarchy();
    }

    public void onAfterInsert(List<SObject> newSObjects,  String objectName) {
        if (isSharingEnabled(objectName)) {
            calculateSharing(newSObjects, objectName, false);
        }
    }

    public void onAfterUpdate( List<SObject> newSObjects, String objectName, Map<Id, SObject> oldMap ) {
        if (isSharingEnabled(objectName)) {
            calculateSharing(modifiedShareRecords(newSObjects, oldMap, objectName), objectName, deleteShareRecordsDuringUpsert(objectName));
        }
    }

    public void onAfterDelete(List<SObject> oldSObjects) {
        if (isSharingEnabled('Account_Team_Member_vod__c')) {
            deleteSharing(oldSObjects);
        }
    }


    private boolean isSharingEnabled(String objectName ) {
        if (VeevaKamUtils.isVeevaAccountPlanShareEnabled()) {
            if (acctHierarchy.isValidHierarchy() &&
                    (acctHierarchy.isObjectInAccountHierarchy(objectName) || objectName == 'Account_Team_Member_vod__c')) {
                return true;
            }
        }
        return false;
    }


    private void calculateSharing(List<SObject> newSObjects, String objectName, boolean toDelete) {
        VeevaAccountPlanSharingLogic sharingLogic = new VeevaAccountPlanSharingLogic(acctHierarchy);
        sharingLogic.calculateSharingRules(newSObjects, objectName, toDelete);
    }

    private void deleteSharing(List<SObject> oldSObjects) {
        // delete will be called only form account team member after delete
        VeevaAccountPlanSharingDeleteLogic sharingDeleteCls = new VeevaAccountPlanSharingDeleteLogic(acctHierarchy);
        sharingDeleteCls.deleteSharingRules(oldSObjects);
    }

    private  List<SObject> modifiedShareRecords (List<SObject> newSObjects, Map<Id, SObject> oldMap, String objectName) {
        List<SObject> changedRecords = new List<SObject> ();
        String firstLevelObjectName = acctHierarchy.getObjectName(0);
        if (objectName == 'Account_Team_Member_vod__c') {
            changedRecords = calculateSharingForAccountMember(newSObjects, oldMap);
        } else if (objectName == firstLevelObjectName) {
            changedRecords = calculateSharingForFirstLevel(newSObjects, oldMap, objectName);
        } else {
            // second or later level hierarchies if the look up field has not changed do nothing
            changedRecords = calculateSharingNextLevel(newSObjects, oldMap, objectName);
        }
        return changedRecords;
    }

    private List<SObject> calculateSharingForAccountMember(List<SObject> newSObjects, Map<Id, SObject> oldMap ) {

        List<SObject> changedRecords = new List<SObject> ();
        for(SObject sObj : newSObjects ) {
            SObject atm = oldMap.get((Id) sObj.get('Id'));
            if (atm != null) {
                String role = (String) sObj.get('Role_vod__c');
                String access = (String) sObj.get('Access_vod__c');
                Id accountPlan = (Id) sObj.get('Account_Plan_vod__c');
                Id teamMember = (Id) sObj.get('Team_Member_vod__c');
                if (role != (String) atm.get('Role_vod__c') || access != (String) atm.get('Access_vod__c')
                        || accountPlan != (Id) atm.get('Account_Plan_vod__c') || teamMember != (Id) atm.get('Team_Member_vod__c')) {
                    changedRecords.add(sObj);
                }
            }
        }
        return changedRecords;
    }

    private List<SObject> calculateSharingForFirstLevel(List<SObject> newSObjects, Map<Id, SObject> oldMap , String objectName) {
        // first level if the look up changed or the share with changed
        List<SObject> changedRecords = new List<SObject> ();
        for(SObject sObj : newSObjects ) {
            SObject firstLevel = oldMap.get((Id) sObj.get('Id'));
            if (firstLevel != null) {
                String shareWith = (String) sObj.get('Share_With_vod__c');
                String lookUpFieldName = acctHierarchy.getFieldName(objectName);
                Id lookupField = (Id) sObj.get(lookUpFieldName);
                if (shareWith != firstLevel.get('Share_With_vod__c') || lookupField != firstLevel.get(lookUpFieldName)) {
                    changedRecords.add(sObj);
                }
            }
        }
        return changedRecords;
    }

    private List<SObject> calculateSharingNextLevel(List<SObject> newSObjects, Map<Id, SObject> oldMap , String objectName) {
        List<SObject> changedRecords = new List<SObject> ();
        for(SObject sObj : newSObjects ) {
            SObject nextLevel = oldMap.get((Id) sObj.get('Id'));
            if (nextLevel != null) {
                String lookUpFieldName = acctHierarchy.getFieldName(objectName);
                Id lookUpField = (Id) sObj.get(lookUpFieldName);
                if (lookUpField != (Id) nextLevel.get(lookUpFieldName)) {
                    changedRecords.add(sObj);
                }
            }
        }
        return changedRecords;
    }

    private boolean deleteShareRecordsDuringUpsert(String objectName) {
        // no need to delete the share records for the second and more levels of the hierarchy
        return (objectName == 'Account_Team_Member_vod__c' || objectName == acctHierarchy.getObjectName(0));
    }



}