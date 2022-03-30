public with sharing class TerritoryFeedbackSettings {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTerritoryFeedbackSettings() {
        Territory_Settings_vod__c territorySettings = Territory_Settings_vod__c.getInstance();
        Map<String, String> result = new Map<String, String>();
        result.put('alignServer', territorySettings.Align_Server_vod__c);
        result.put('alignVersion', territorySettings.Align_Version_vod__c);
        return result;
    }
}