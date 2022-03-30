public without sharing class VeevaGASImplicitFilterChecker {
    private static String TERRITORY = 'Territory_vod';
    private static String PROFILE = 'Profile_vod';
    private static String ORG_DEFAULT = 'Org_Default_vod';

    private TerritoryManagement territoryManagement;
    private Set<Id> userTerritories;

    public VeevaGASImplicitFilterChecker() {
        territoryManagement = TerritoryManagementFactory.getInstance();
        userTerritories = territoryManagement.getUserTerritories(UserInfo.getUserId());
    }

    public List<Implicit_Filter_vod__c> userSpecificImplicitFilters() {
        Map<Id, Map<String, String>> territoryMap = territoryManagement.getTerritoriesMap();
        List<Implicit_Filter_vod__c> implicitFilters = retrieveImplicitFilters(territoryMap);
        Map<String, List<Implicit_Filter_vod__c>> filtersByLocation = getImplicitFiltersByLocation(implicitFilters);
        List<Implicit_Filter_vod__c> territoryImplicitFilters = filtersByLocation.get(TERRITORY);
        List<Implicit_Filter_vod__c> profileImplicitFilters = filtersByLocation.get(PROFILE);
        List<Implicit_Filter_vod__c> orgDefaultImplicitFilters = filtersByLocation.get(ORG_DEFAULT);
        if (territoryImplicitFilters != null && !territoryImplicitFilters.isEmpty()) {
            return pickMostSpecificTerritoryImplicitFilters(territoryImplicitFilters, territoryMap);
        } else if (profileImplicitFilters != null && !profileImplicitFilters.isEmpty()) {
            return profileImplicitFilters;
        } else {
            return orgDefaultImplicitFilters != null ? orgDefaultImplicitFilters : new List<Implicit_Filter_vod__c>();
        }
    }

    private List<Implicit_Filter_vod__c> retrieveImplicitFilters(Map<Id, Map<String, String>> territoryMap) {
        Set<Id> territoryIdsRelatedToUser = getTerritoriesAndParentTerritoriesRelatedToUser(territoryMap);

        return [SELECT Id, Location_vod__c, Applies_To_vod__c, Inclusion_vod__c FROM Implicit_Filter_vod__c
                    WHERE (Location_vod__c = :ORG_DEFAULT AND Applies_To_vod__c = null)
                        OR (Location_vod__c = :PROFILE AND Applies_To_vod__c = :UserInfo.getProfileId())
                        OR (Location_vod__c = :TERRITORY AND Applies_To_vod__c in :territoryIdsRelatedToUser)];
    }

    private Set<Id> getTerritoriesAndParentTerritoriesRelatedToUser(Map<Id, Map<String, String>> territoryMap) {
        Set<Id> territoryIdsRelatedToUser = new Set<Id>();
        territoryIdsRelatedToUser.addAll(userTerritories);
        for (String userTerritory : userTerritories) {
            territoryIdsRelatedToUser.addAll(territoryManagement.getParentIdsByTerritoryId(userTerritory, territoryMap));
        }
        return territoryIdsRelatedToUser;
    }

    private List<Implicit_Filter_vod__c> pickMostSpecificTerritoryImplicitFilters(List<Implicit_Filter_vod__c> territoryImplicitFilters,  Map<Id, Map<String, String>> territoryMap) {
        Map<String, List<Implicit_Filter_vod__c>> territoryImplicitFiltersByAppliesTo = getImplicitFiltersByAppliesTo(territoryImplicitFilters);
        List<String> sortedUserTerritories = getTerritoryIdsSortedByTerritoryNames(new List<Id>(userTerritories), territoryMap);
        if (sortedUserTerritories.isEmpty()) {
            return new List<Implicit_Filter_vod__c>();
        }

        List<Implicit_Filter_vod__c> mostSpecificTerritoryImplicitFilters = new List<Implicit_Filter_vod__c>();
        Set<String> visitedTerritories = new Set<String>();
        for (String userTerritoryId : sortedUserTerritories) {
            visitedTerritories.add(userTerritoryId);
            mostSpecificTerritoryImplicitFilters = pickTerritoryImplicitFiltersFromTerrHierarchy(userTerritoryId, visitedTerritories, territoryImplicitFiltersByAppliesTo, territoryMap);
            if (!mostSpecificTerritoryImplicitFilters.isEmpty()) {
                break;
            }
        }
        return mostSpecificTerritoryImplicitFilters;
    }

    // Retrieves the list of Implicit Filters that match territoryId, if nothing is found for territoryId we will recursively
    // iterate through all of the Territories Parent Territories
    private List<Implicit_Filter_vod__c> pickTerritoryImplicitFiltersFromTerrHierarchy(String territoryId, Set<String> visitedTerritories, Map<String, List<Implicit_Filter_vod__c>> territoryImplicitFiltersByAppliesTo, Map<Id, Map<String, String>> territoryMap) {
        // When territoryId is empty this means that there is no more Territories to search
        if (String.isEmpty(territoryId)) {
            return new List<Implicit_Filter_vod__c>();
        }

        List<Implicit_Filter_vod__c> implicitFiltersForTerritoryId = territoryImplicitFiltersByAppliesTo.get(territoryId);
        if (implicitFiltersForTerritoryId != null) {
            return implicitFiltersForTerritoryId;
        }

        Map<String, String> territory = territoryMap.get(territoryId);
        // Note: TerritoryManagment class maps ParentTerritory2Id to ParentTerritoryId
        String parentTerritoryId = territory.get('ParentTerritoryId');
        if (visitedTerritories.contains(parentTerritoryId)) {
            // We have already "visited" this parent territory id and did not find any Implicit Filters that match
            // This means that we do not need to traverse the hierarchy again, and can return an empty list
            return new List<Implicit_Filter_vod__c>();
        } else {
            // Let's traverse this parent territory id and see if we can find an Implicit Filter that matches
            visitedTerritories.add(parentTerritoryId);
            return pickTerritoryImplicitFiltersFromTerrHierarchy(parentTerritoryId, visitedTerritories, territoryImplicitFiltersByAppliesTo, territoryMap);
        }
    }

    private List<String> getTerritoryIdsSortedByTerritoryNames(List<String> territoryIds, Map<Id, Map<String, String>> territoryMap) {
        // Populates Territory Names and Territory Name -> Territory Id mapping
        Map<String, String> territoryIdByName = new Map<String, String>();
        List<String> territoryNames = new List<String>();
        for (Id territoryId : territoryIds) {
            Map<String, String> territory = territoryMap.get(territoryId);
            if (territory != null) {
                String territoryName = territory.get('Name');
                territoryIdByName.put(territoryName, territoryId);
                territoryNames.add(territoryName);
            }
        }
        // Sorts the Territory Names
        territoryNames.sort();

        // Populates territoryId list using the sorted territory names
        List<String> sortedTerritoryIdsByName = new List<String>();
        for (String territoryName : territoryNames) {
            sortedTerritoryIdsByName.add(territoryIdByName.get(territoryName));
        }
        return sortedTerritoryIdsByName;
    }

    private Map<String, List<Implicit_Filter_vod__c>> getImplicitFiltersByLocation(List<Implicit_Filter_vod__c> implicitFilters) {
        Map<String, List<Implicit_Filter_vod__c>> implicitFiltersByLocation = new Map<String, List<Implicit_Filter_vod__c>>();
        for (Implicit_Filter_vod__c filter : implicitFilters) {
            List<Implicit_Filter_vod__c> filtersForLocation = implicitFiltersByLocation.get(filter.Location_vod__c);
            if (filtersForLocation == null) {
                filtersForLocation = new List<Implicit_Filter_vod__c>();
                implicitFiltersByLocation.put(filter.Location_vod__c, filtersForLocation);
            }
            filtersForLocation.add(filter);
        }
        return implicitFiltersByLocation;
    }

    private Map<String, List<Implicit_Filter_vod__c>> getImplicitFiltersByAppliesTo(List<Implicit_Filter_vod__c> implicitFilters) {
        Map<String, List<Implicit_Filter_vod__c>> implicitFiltersByAppliesTo = new Map<String, List<Implicit_Filter_vod__c>>();
        for (Implicit_Filter_vod__c filter : implicitFilters) {
            List<Implicit_Filter_vod__c> filtersForAppliesTo = implicitFiltersByAppliesTo.get(filter.Applies_To_vod__c);
            if (filtersForAppliesTo == null) {
                filtersForAppliesTo = new List<Implicit_Filter_vod__c>();
                implicitFiltersByAppliesTo.put(filter.Applies_To_vod__c, filtersForAppliesTo);
            }
            filtersForAppliesTo.add(filter);
        }
        return implicitFiltersByAppliesTo;
    }
}