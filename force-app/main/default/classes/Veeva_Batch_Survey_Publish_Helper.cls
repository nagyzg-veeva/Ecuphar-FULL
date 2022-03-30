public with sharing class Veeva_Batch_Survey_Publish_Helper {
    public static void populateGroupIdCollections(Map<String,Set<String>> acctToGroupIdsToPopulate, Set<String> groupIdSetToPopulate,
                                                  Set<String> acctList, TerritoryManagement tm) {
        try {
            for (AccountShare acctShare : tm.getAccounts(idValuesOf(acctList), true)) {
                Set<String> groupIds = acctToGroupIdsToPopulate.get(acctShare.AccountId);
                if (groupIds == null) {
                    groupIds = new Set<String>();
                    acctToGroupIdsToPopulate.put(acctShare.AccountId,groupIds);
                }
                groupIds.add(acctShare.UserOrGroupId);
                groupIdSetToPopulate.add(acctShare.UserOrGroupId);
            }
        } catch (StringException e) {
            System.debug(LoggingLevel.WARN, 'Bad Id found; skipping populating group id collections: ' + e);
        }
    }

    public static void populateUserIdCollections(Set<Id> allUserIdsToPopulate, Map<String,List<String>> acctToUserIdsToPopulate,
                                                 Set<String> terrIdSet, Map<String, Set<String>> acctToTerrIds,
                                                 TerritoryManagement tm) {
        try {
            Map<Id, Map<String, String>> userTerritories = tm.getUserTerritories(null, idValuesOf(terrIdSet));
            for (Map<String, String> ut : userTerritories.values()) {
                for (String acctId : acctToTerrIds.KeySet()) {
                    List<String> userIds = acctToUserIdsToPopulate.get(acctId);
                    if (userIds == null) {
                        userIds = new List<String>();
                        acctToUserIdsToPopulate.put(acctId, userIds);
                    }
                    if (acctToTerrIds.get(acctId).contains(ut.get('territoryId'))) {
                        userIds.add(ut.get('UserId'));
                        allUserIdsToPopulate.add(ut.get('UserId'));
                    }
                }
            }
        } catch(StringException e) {
            System.debug(LoggingLevel.WARN, 'Bad Id found; skipping populating user id collections: ' + e);
        }

    }

    public static Set<String> getUsersInSurveyTerritories(Set<Id> allUserIds, Set<String> surveyTerritoryIds,
                                                          TerritoryManagement tm) {
        Set<String> userTerritoriesSvy = new Set<String>();
        if (surveyTerritoryIds != null && surveyTerritoryIds.size() > 0) {
            try {
                Map<Id, Map<String, String>> userTerrs = tm.getUserTerritories(allUserIds, idValuesOf(surveyTerritoryIds));
                for (Map<String, String> ut :userTerrs.values()) {
                    userTerritoriesSvy.add(ut.get('UserId'));
                }
            } catch (StringException e) {
                System.debug(LoggingLevel.WARN, 'Bad Id found; skipping getting survey territory users: ' + e);
            }
        }

        return userTerritoriesSvy;
    }

    public static Set<Id> idValuesOf(Set<String> idStrs) { //throws StringException
        Set<Id> toReturn = new Set<Id>();
        try {
            for (String idStr : idStrs) {
                toReturn.add(Id.valueOf(idStr));
            }
        } catch (StringException e) {
            throw new StringException(e.getMessage());
        }
        return toReturn;
    }
}