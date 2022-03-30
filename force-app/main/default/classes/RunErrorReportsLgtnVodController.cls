public without sharing class RunErrorReportsLgtnVodController {
	@AuraEnabled
    public static Analytics_Files_vod__c getAnalyticsFile(Id analyticFileId) {
        // Perform isAccessible() checks here
        return [SELECT Id, Type_vod__c, Status_vod__c, File_Name_vod__c, Market_vod__c FROM Analytics_Files_vod__c WHERE Id = :analyticFileId];
    }

	@AuraEnabled
    public static Map<String, String> getVodInfo() {
        return SessionVod.getVodInfo();
    }

    @AuraEnabled
    public static Map<String, String> getDataMapList(Id analyticFileId) {
       	Analytics_Files_vod__c analyticsFile = [SELECT Id, Data_Map_Template_Id_vod__c FROM Analytics_Files_vod__c WHERE Id = :analyticFileId];
        String dataMapTemplateId = analyticsFile.Data_Map_Template_Id_vod__c;
        List<Data_Map_Template_Field_vod__c> dataMapTemplateList = [SELECT Id,Vod_Field_vod__c,Column_Number_vod__c FROM Data_Map_Template_Field_vod__c Where Data_Map_Template_vod__c = :dataMapTemplateId ORDER BY Column_Number_vod__c];
        Map<String, String> returnMap = new Map<String, String>();
        for (Data_Map_Template_Field_vod__c dataMap : dataMapTemplateList) {
            returnMap.put(dataMap.Vod_Field_vod__c, dataMap.Column_Number_vod__c);
        }
        return returnMap;
    }

}