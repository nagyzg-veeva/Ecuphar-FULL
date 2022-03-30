/**
 * MyInsightsHTMLReportOptions is responsible for retrieving HTML Report Options to show to a user
 * on the Lightning App Page. This is done by extending the VisualEditor.DynamicPickList Apex class.
 *
 * Any LWC that sets this Apex class as its datasource will be given the options that are returned
 * by the getValues() method, this Apex class does not set a default value in the getDefaultValue()
 * since null is a valid option when users choose to perform advance configurations around LWCs that
 * take HTML Reports as a property.
 */
public with sharing class MyInsightsHTMLReportOptions extends VisualEditor.DynamicPickList {

    private final VisualEditor.DesignTimePageContext context;
    private final MyInsightsVisualEditorConfiguration configuration;

    public MyInsightsHTMLReportOptions(VisualEditor.DesignTimePageContext context) {
       this.context = context;
       this.configuration = new MyInsightsVisualEditorConfiguration();
    }
  
    public override VisualEditor.DataRow getDefaultValue() {
        return null;
    }
  
    public override VisualEditor.DynamicPickListRows getValues() {
        List<HTML_Report_vod__c> reports = getHtmlReportOptions();
        UniqueReportNameGenerator uniqueReportNameGenerator = new UniqueReportNameGenerator();
        List<HtmlReportWithUniqueName> uniqueHtmlReportNameByHtmlReport = uniqueReportNameGenerator.retrieveHtmlReportsWithUniqueNames(reports);
        uniqueHtmlReportNameByHtmlReport.sort();
        List<HtmlReportWithUniqueName> sortedReports = uniqueHtmlReportNameByHtmlReport;
        
        VisualEditor.DynamicPickListRows  reportOptions = new VisualEditor.DynamicPickListRows();
        for (HtmlReportWithUniqueName htmlReportWithUniqueName : sortedReports) {
            HTML_Report_vod__c report = htmlReportWithUniqueName.getReport();
            VisualEditor.DataRow reportOption = new VisualEditor.DataRow(htmlReportWithUniqueName.getUniqueName(), String.valueOf(report.Id));
            reportOptions.addRow(reportOption);
        }
        return reportOptions;
    }

    private List<HTML_Report_vod__c> getHtmlReportOptions() {
        List<HTML_Report_vod__c> reports = new List<HTML_Report_vod__c>();
        if (userCanReadHtmlReports()) {
            String objectName = context.entityName;
            List<String> recordTypeNames = configuration.getRecordTypesNamesFor(objectName);
            if (context.pageType == 'RecordPage' && recordTypeNames != null && !recordTypeNames.isEmpty()) {
                reports = [SELECT Id, Name, RecordType.Name, Object_RecordType_vod__c FROM HTML_Report_vod__c WHERE RecordType.DeveloperName in :recordTypeNames AND Platform_vod__c includes ('Lightning_vod')];
            } else {
                List<String> defaultRecordTypeNames = configuration.getDefaultRecordTypeNames();
                reports = [SELECT Id, Name, RecordType.Name, Object_RecordType_vod__c FROM HTML_Report_vod__c WHERE RecordType.DeveloperName in :defaultRecordTypeNames AND Platform_vod__c includes ('Lightning_vod')];
            }
        }
        return reports;
    }

    private boolean userCanReadHtmlReports() {
        return HTML_Report_vod__c.getSObjectType().getDescribe().isAccessible();
    }
}