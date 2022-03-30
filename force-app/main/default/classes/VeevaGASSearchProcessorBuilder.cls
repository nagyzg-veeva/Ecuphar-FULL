public inherited sharing class VeevaGASSearchProcessorBuilder {

    private final List<VeevaGASSearchCondition> searchConditions;

    private String platform;
    private VeevaGASImplicitFilterChecker filterChecker;
    private VeevaGASQuerySortCondition sortCondition;

    public VeevaGASSearchProcessorBuilder() {
        this.searchConditions = new List<VeevaGASSearchCondition>();
        this.platform = 'Online';
        this.filterChecker = new VeevaGASImplicitFilterChecker();
    }

    public VeevaGASSearchProcessorBuilder withPlatform(String platformToSet) {
        if (platformToSet != null) {
            this.platform = platformToSet;
        }
        return this;
    }

    public VeevaGASSearchProcessorBuilder withUserFilters(List<Map<String, Object>> userFilters) {
        if (userFilters != null) {
            this.searchConditions.addAll(createSearchConditions(userFilters));
        }
        return this;
    }

    public VeevaGASSearchProcessorBuilder withSortConditions(Map<String, String> sortConditionInfo) {
        if (sortConditionInfo != null && sortConditionInfo.size() > 0) {
            String sortColumn = sortConditionInfo.get('sortColumn');
            String sortDirection = sortConditionInfo.get('sortDirection');
            if (String.isNotBlank(sortColumn) && String.isNotBlank(sortDirection)) {
                this.sortCondition = new VeevaGASQuerySortCondition(sortColumn, sortDirection);
            }
        }
        return this;
    }

    public VeevaGlobalAccountSearchProcessor build() {
        searchConditions.addAll(getSearchConditions(filterChecker));
        VeevaGASSearchClause searchClause = new VeevaGASSearchClause(searchConditions);
        VeevaGASUserAccess userAccess = new VeevaGASUserAccess();
        return new VeevaGlobalAccountSearchProcessor(platform, searchClause, sortCondition, userAccess);
    }

    private static List<VeevaGASSearchCondition> getSearchConditions(VeevaGASImplicitFilterChecker filterChecker) {
        List<Implicit_Filter_vod__c> filters = filterChecker.userSpecificImplicitFilters();
        Map<Id, Implicit_Filter_vod__c> filtersById = new Map<Id, Implicit_Filter_vod__c>(filters);
        List<Implicit_Filter_Condition_vod__c> conditions = [SELECT Id, Object_Name_vod__c, Field_Name_vod__c, Criteria_vod__c, Implicit_Filter_vod__c FROM Implicit_Filter_Condition_vod__c WHERE Implicit_Filter_vod__c IN :filtersById.keySet()];

        List<VeevaGASSearchCondition> searchConditions = new List<VeevaGASSearchCondition>();
        for (Implicit_Filter_Condition_vod__c condition : conditions) {
            searchConditions.add(new VeevaGASSearchCondition(condition, filtersById.get(condition.Implicit_Filter_vod__c)));
        }
        return searchConditions;
    }

    private static List<VeevaGASSearchCondition> createSearchConditions(List<Map<String,Object>> userFilters) {
        List<VeevaGASSearchCondition> userFilterSearchConditions = new List<VeevaGASSearchCondition>();
        for (Map<String, Object> userFilter : userFilters) {
            Object objectApiNameObject = userFilter.get('objectApiName');
            Object fieldApiNameObject = userFilter.get('fieldApiName');
            Object selectedOptions = userFilter.get('selectedOptions');
            String objectApiName = objectApiNameObject != null ? objectApiNameObject.toString() : null;
            String fieldApiName = fieldApiNameObject != null ? fieldApiNameObject.toString() : null;

            if (String.isNotBlank(objectApiName) && String.isNotBlank(fieldApiName)
                 && selectedOptions != null && ((List<Object>) selectedOptions).size() > 0) {
                for (Object selectedOption : (List<Object>) selectedOptions) {
                    VeevaGASSearchCondition searchCondition = new VeevaGASSearchCondition(objectApiName, fieldApiName, selectedOption.toString());
                    userFilterSearchConditions.add(searchCondition);
                }
            }
        }
        return userFilterSearchConditions;
    }
}