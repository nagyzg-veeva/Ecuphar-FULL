public without sharing class VeevaImplicitFilterTriggerHandler extends VeevaTriggerHandler {
    private List<Implicit_Filter_vod__c> newImplicitFilters;
    private List<Implicit_Filter_vod__c> oldImplicitFilters;
    private Map<Id, Implicit_Filter_vod__c> newImplicitFiltersMap;
    private Map<Id, Implicit_Filter_vod__c> oldImplicitFiltersMap;
    private String duplicateFilterError;
    
    protected override String sObjectType() {
        return 'Implicit_Filter_vod__c';
    }
    
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        newImplicitFilters = (List<Implicit_Filter_vod__c>) triggerNew;
        oldImplicitFilters = (List<Implicit_Filter_vod__c>) triggerOld;
        newImplicitFiltersMap = (Map<ID, Implicit_Filter_vod__c>) triggerNewMap;
        oldImplicitFiltersMap = (Map<ID, Implicit_Filter_vod__c>) triggerOldMap;
        duplicateFilterError = VOD_VEEVA_MESSAGE.getMsgWithDefault('GAS_DUPLICATE_FILTERS_ERROR', 'Global Account Search', 'You cannot create more than one filter with the same Location, Applies To, and Inclusion values.');
    }

    protected override void beforeInsert() {
        allowUpsertOfNonIdenticalFilters();
    }
    
    protected override void beforeUpdate() {
        allowUpsertOfNonIdenticalFilters();
    }

    private void allowUpsertOfNonIdenticalFilters() {
        Set<String> newImplicitFilterLocations = getNewImplicitFilterLocations();
        Set<String> newImplicitFilterAppliesToValues = getNewImplicitFilterAppliesToValues();
        Set<Boolean> newImplicitFilterInclusionValues = getNewImplicitFilterInclusionValues();
        List<Implicit_Filter_vod__c> existingFilters = [SELECT Id, Location_vod__c, Applies_To_vod__c, Inclusion_vod__c FROM Implicit_Filter_vod__c
            WHERE Location_vod__c in :newImplicitFilterLocations
                AND (Applies_To_vod__c in :newImplicitFilterAppliesToValues OR Applies_To_vod__c = null)
                AND (Inclusion_vod__c in :newImplicitFilterInclusionValues)
        ];
        for (Implicit_Filter_vod__c filter : newImplicitFilters) {
            if (doesFilterExist(filter, existingFilters)) {
                filter.addError(duplicateFilterError);
            }
        }
    }

    private boolean doesFilterExist(Implicit_Filter_vod__c filter, List<Implicit_Filter_vod__c> existingFilters) {
        boolean filterExists = false;
        for (Implicit_Filter_vod__c existingFilter : existingFilters) {
            filterExists = existingFilter.Id != filter.Id
                && existingFilter.Location_vod__c == filter.Location_vod__c
                && existingFilter.Applies_To_vod__c == filter.Applies_To_vod__c
                && existingFilter.Inclusion_vod__c == filter.Inclusion_vod__c;
            if (filterExists) {
                break;
            }
        }
        return filterExists;
    }

    private Set<String> getNewImplicitFilterLocations() {
        Set<String> newImplicitFilterLocations = new Set<String>();
        for (Implicit_Filter_vod__c filter : newImplicitFilters) {
            newImplicitFilterLocations.add(filter.Location_vod__c);
        }
        return newImplicitFilterLocations;
    }

    private Set<String> getNewImplicitFilterAppliesToValues() {
        Set<String> newImplicitFilterAppliesToValues = new Set<String>();
        for (Implicit_Filter_vod__c filter : newImplicitFilters) {
            if (filter.Applies_To_vod__c != null) {
                newImplicitFilterAppliesToValues.add(filter.Applies_To_vod__c);
            }
        }
        return newImplicitFilterAppliesToValues;
    }

    private Set<Boolean> getNewImplicitFilterInclusionValues() {
        Set<Boolean> newImplicitFilterInclusionValues = new Set<Boolean>();
        for (Implicit_Filter_vod__c filter : newImplicitFilters) {
            newImplicitFilterInclusionValues.add(filter.Inclusion_vod__c);
        }
        return newImplicitFilterInclusionValues;
    }
}