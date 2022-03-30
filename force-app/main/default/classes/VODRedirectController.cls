public with sharing class VODRedirectController {

    public VODRedirectController(ApexPages.StandardSetController controller) {
    }

    private static List<String> urlWith2000px =
        new List<String>
          {
            'Call_Report_From_Calls_vod', 'Call_Reports_from_Calls_Edit_vod',
            'Medical_Inquiry_Clone', 'Medical_Inquiry_Edit_vod', 'Medical_Inquiry_New_vod', 'Medical_Inquiry_View_vod',
            'Sample_Transactions_Clone', 'Sample_Transactions_Edit', 'Sample_Transactions_New', 'Sample_Transaction_View',
            'Sample_Inventory_View', 'Sample_Inventory_Edit', 'Sample_Inventory_New',
            'Sample_Orders_Edit_vod', 'Sample_Orders_View_vod',
            'VMobile_Config_Clone_vod', 'VMobile_Config_Edit_vod', 'VMobile_Config_New_vod', 'VMobile_Config_View_vod',
            'Call_from_Account_Tactic_vod', 'Call_Report_From_Account_Default', 'Call_Report_From_Contact_vod', 'Call_Report_From_Medical_Event',
            'Call_Report_Meeting_Brief_vod', 'Gener_Non_Accnt_Lookup_Record_Call_Tmpl', 'MultiChannel_Calendar_vod', 'My_Samples',
            'New_Any_Account_vod', 'New_Business_Account_vod', 'New_Hospital_Account_vod', 'New_Person_Account_vod', 'New_Professional_Account_vod',
            'New_Professional_vod'
          };

    private ApexPages.StandardController controller;
    public VODRedirectController(ApexPages.StandardController controller) {
        this.controller = controller;
    }

    public VODRedirectController() {
    }

    public String redirectURL { get; set; }

    public String contractRecordTypeData { get; set; }

    public static String getVodVersion() {
        return VOD_Common.VOD_VERSION;
    }

    public static String getVodUrl () {
        return VOD_Common.VOD_URL;
    }
    public static boolean getInMaintenance () {
        return VOD_Common.VOD_MAINT;
    }
    public static String getExcludedUsers () {
        return VOD_Common.VOD_EXCLUDED_USERS;
    }

    public static String getVodServerUrl() {
        return VOD_Common.VOD_SERVER_URL;
    }

    public static String getVodFtpUrl(){
        return VOD_Common.FTP_SERVER_URL;
    }
    public static String getVodContentUrl(){
        return VOD_Common.CONTENT_SERVER_URL;
    }

    public static String getIPadVersion() {
        return VOD_Common.IVERSION;
    }

    public static String getIRepAppId() {
        return VOD_Common.IREP_APP_ID;
    }

    //for MC Engine
    public static String getMcUrl(){
    	return VOD_Common.MC_SERVER + '/' + VOD_Common.MC_CONTEXT_ROOT;
    }
    public static String getMcVersion(){
        return VOD_Common.MC_CONTEXT_ROOT;
    }

    public String getPageSize() {

        String url = ApexPages.currentPage().getUrl();

        for(String checkUrl : urlWith2000px) {
            if(url.contains(checkUrl)) {
                return '2000px';
            }
        }

        if (url.contains('View_Cycle_Plan_vod')) {
            Integer targetCount = [select count() from Cycle_Plan_Target_vod__c where Cycle_Plan_vod__c = :ApexPages.currentPage().getParameters().get('id')];
            Integer height = 50*targetCount;
            if (height < 3000)
                height = 3000;
            return height+'px';
        } else if (url.contains('TSF_vod')) {
            return '600px';
        } else if (url.contains('Concur_Admin_vod')) {
            return '8000px';
        } else if (url.contains('Call_Edit_vod')) {
            return '2000px';
        }
        return '4000px';
    }

    public static String getScrolling() {
        String url = ApexPages.currentPage().getUrl();
        if (url.contains('View_Cycle_Plan_vod')) {
            return 'true';
        } else if (url.contains('TSF_vod')) {
            return 'true';
        } else if (url.contains('Call_Edit_vod')) {
            return 'true';
        } else if (url.contains('Medical_Inquiry_Edit_vod')) {
            return 'true';
        }
        return 'false';
    }

    public PageReference doRedirect() {
        PageReference redirect = new PageReference(redirectURL);
        redirect.setRedirect(true);
        return redirect;
    }

    private boolean isLocked(Contract_vod__c record) {
        return record.Lock_vod__c || (record.Product_Bound_vod__c && record.Agreement_vod__c);
    }

    private boolean isLocked(Contract_Line_vod__c record) {
        return record.Lock_vod__c || record.Contract_vod__r.Status_vod__c == 'Signed_vod' || (record.Contract_vod__r.Product_Bound_vod__c && record.Contract_vod__r.Agreement_vod__c);
    }

    private boolean isLocked(Contract_Partner_vod__c record) {
        return record.Lock_vod__c || (record.Status_vod__c == 'Signed_vod');
    }

    public Pagereference contractEditRedirect() {
        if (controller != null && controller.getRecord() != null) {
            Boolean locked = null;
            SObject record = controller.getRecord();
            if (controller.getRecord() instanceof Contract_vod__c) {
                Contract_vod__c contract = (Contract_vod__c)record;
                locked = isLocked(contract);
            }
            else if (controller.getRecord() instanceof Contract_Line_vod__c) {
                Contract_Line_vod__c contractLine = (Contract_Line_vod__c)record;
                locked = isLocked(contractLine);
            }
            else if (controller.getRecord() instanceof Contract_Partner_vod__c) {
                Contract_Partner_vod__c contractPartner = (Contract_Partner_vod__c)record;
                locked = isLocked(contractPartner);
            }
            if (locked != null && record.Id != null) {
                String url = '/' + record.Id;
                if (!locked) {
                    url += '/e?nooverride=1&retURL=/' + record.Id;
                }
                PageReference redirect = new PageReference(url);
                redirect.setRedirect(true);
                return redirect;
            }
        }
        return null;
    }

    public void getContractRelatedRecordTypeIds() {
        if (controller != null && controller.getRecord() != null) {
            SObject record = controller.getRecord();
            if (controller.getRecord() instanceof Contract_vod__c) {
                Contract_vod__c contract = (Contract_vod__c)record;
                String contractRecordTypeName = Schema.SObjectType.Contract_vod__c.getRecordTypeInfosById().get(contract.RecordTypeId).getDeveloperName();
                String contractLineRecordTypeId = Schema.SObjectType.Contract_Line_vod__c.getRecordTypeInfosByDeveloperName()
                      .get(contractRecordTypeName).getRecordTypeId();
                String contractPartnerRecordTypeId = Schema.SObjectType.Contract_Partner_vod__c.getRecordTypeInfosByDeveloperName()
                      .get(contractRecordTypeName).getRecordTypeId();
                contractRecordTypeData = '\'{"contractLineRT":"' + contractLineRecordTypeId + '","contractPartnerRT":"' + contractPartnerRecordTypeId + '"}\'';

            }
        }
    }
}