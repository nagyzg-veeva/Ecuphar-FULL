public with sharing class VeevaGlobalAccountSearchConfiguration {
    public static List<Map<String, Object>> getLocationsWithAppliesTo() {
        List<Map<String, Object>> locationsWithAppliesTo = new List<Map<String, Object>>();
        for (Schema.PicklistEntry entry : Implicit_Filter_vod__c.Location_vod__c.getDescribe().getPicklistValues()) {
            Map<String, Object> locationWithAppliesTo = new Map<String, Object>();
            locationWithAppliesTo.put('label', entry.getLabel());
            locationWithAppliesTo.put('value', entry.getValue());
            List<Map<String, String>> appliesToValues = getAppliesToValuesFor(entry.value);
            locationWithAppliesTo.put('appliesTo', appliesToValues);
            locationWithAppliesTo.put('requiresAppliesToValue', appliesToValues.size() > 0);
            locationsWithAppliesTo.add(locationWithAppliesTo);
        }
        return locationsWithAppliesTo;
    }

    private static List<Map<String, String>> getAppliesToValuesFor(String locationValue) {
        List<Map<String, String>> appliesToValues;
        if (locationValue == 'Profile_vod') {
            appliesToValues = getProfileAppliesToValues();
        } else if (locationValue == 'Territory_vod') {
            appliesToValues = getTerritoryAppliesToValues();
        } else {
            appliesToValues = new List<Map<String, String>>();
        }
        return appliesToValues;
    }

    private static List<Map<String, String>> getProfileAppliesToValues() {
        List<Map<String, String>> appliesToValues = new List<Map<String, String>>();
        for (Profile prof :[SELECT Id, Name FROM Profile ORDER BY Name]) {
            Map<String, String> profileAppliesToValue = new Map<String, String>();
            profileAppliesToValue.put('label', prof.Name);
            profileAppliesToValue.put('value', prof.Id);
            appliesToValues.add(profileAppliesToValue);
        }
        return appliesToValues;
    }

    private static List<Map<String, String>> getTerritoryAppliesToValues() {
        List<Map<String, String>> appliesToValues = new List<Map<String, String>>();
        for (Territory2 terr :[SELECT Id, Name FROM Territory2 ORDER BY Name]) {
            Map<String, String> territoryAppliesToValue = new Map<String, String>();
            territoryAppliesToValue.put('label', terr.Name);
            territoryAppliesToValue.put('value', terr.Id);
            appliesToValues.add(territoryAppliesToValue);
        }
        return appliesToValues;
    }
}