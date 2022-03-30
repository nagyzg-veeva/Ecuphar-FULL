public with sharing class EmEventController {
    @AuraEnabled
    public static List<EM_Event_Configuration_Country_vod__c> getEventCountryConfigs(
        List<String> recordTypeDeveloperNames
    ) {
        try {
            Date currentDate = System.now().dateGmt();
            List<EM_Event_Configuration_Country_vod__c> result = new List<EM_Event_Configuration_Country_vod__c>();

            // Using Dynamic SOQL, as inline SOQL gives error due to aliasing lookup field
            String soqlQuery =
                'SELECT Id, Country_vod__c, Country_vod__r.Country_Name_vod__c, toLabel(Country_vod__r.Country_Name_vod__c) LabelAlias, ' +
                    'Event_Configuration_vod__c, External_ID_vod__c ' +
                'FROM EM_Event_Configuration_Country_vod__c ' +
                getWhereClause() +
                'ORDER BY Country_vod__r.Country_Name_vod__c ASC';

            return Database.query(soqlQuery);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<String> getRecordTypesWithEventCountryConfigs(
        List<String> recordTypeDeveloperNames
    ) {
        try {
            List<String> result = new List<String>();
            Date currentDate = System.now().dateGmt();

            String soqlQuery =
                'SELECT Event_Configuration_vod__r.Event_Type_vod__c ' +
                'FROM EM_Event_Configuration_Country_vod__c ' +
                getWhereClause() +
                'GROUP BY Event_Configuration_vod__r.Event_Type_vod__c';

            List<AggregateResult> ars = Database.query(soqlQuery);

            for (AggregateResult ar : ars) {
                result.add((String) ar.get('Event_Type_vod__c'));
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getUserPreferenceCountryConfig() {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<Preferences_vod__c> userPreferenceList = [
                SELECT Id, Event_Country_Config_vod__c
                FROM Preferences_vod__c
                WHERE User_vod__c = :currentUserId
                AND Event_Country_Config_vod__c != ''
                LIMIT 1
            ];
            return !userPreferenceList.isEmpty()
                ? userPreferenceList[0].Event_Country_Config_vod__c
                : '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    static String getWhereClause() {
        return 
        'WHERE ' +
            'Country_vod__c != null ' +
            'AND Event_Configuration_vod__r.Event_Type_vod__c IN :recordTypeDeveloperNames ' +
            'AND Event_Configuration_vod__r.Start_Date_vod__c <=: currentDate ' +
            'AND Event_Configuration_vod__r.End_Date_vod__c >=: currentDate ';
    }

    @AuraEnabled(cacheable=true)
    public static String getTeamMemberGroupLabel(String groupDevName) {
        try {
            String result = groupDevName;
            Group publicGroup = [SELECT Name, DeveloperName FROM Group WHERE DeveloperName = :groupDevName AND Type IN ('Queue', 'Regular') LIMIT 1];
            if (publicGroup != null) {
                result = publicGroup.Name;
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}