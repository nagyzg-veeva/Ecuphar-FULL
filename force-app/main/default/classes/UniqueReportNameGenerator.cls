/**
 * UniqueHtmlReports is responsible for determining a Unique Name for each HTML Report.
 */
public with sharing class UniqueReportNameGenerator {
    private Map<String, List<HTML_Report_vod__c>> htmlReportsByName;
    private Map<String, List<HTML_Report_vod__c>> htmlReportsByNameAndRecordType;
    private Map<String, List<HTML_Report_vod__c>> htmlReportsByNameAndObjectRecordType;

    public UniqueReportNameGenerator() {
        this.htmlReportsByName = new Map<String, List<HTML_Report_vod__c>>();
        this.htmlReportsByNameAndRecordType = new Map<String, List<HTML_Report_vod__c>>();
        this.htmlReportsByNameAndObjectRecordType = new Map<String, List<HTML_Report_vod__c>>();
    }

    /**
     * Creates a map of a Unique Report Name to its HTML Report.
     * The unique report name is determined based on if one of the following is unique for the list of reports provided:
     *      - Report Name
     *      - Report Name (HTML Report Record Type)
     *      - Report Name (Object Record Type - Field Name Object_RecordType_vod__c)
     *      - Report Name (HTML Report Id)
     */
    public List<HtmlReportWithUniqueName> retrieveHtmlReportsWithUniqueNames(List<HTML_Report_vod__c> reports) {
        updateHtmlReportsByName(reports);
        updateHtmlReportsByNameAndRecordType(reports);
        updateHtmlReportsByNameAndObjectRecordType(reports);

        List<HtmlReportWithUniqueName> uniqueHtmlReportNameByHtmlReport = new List<HtmlReportWithUniqueName>();
        for (HTML_Report_vod__c report : reports) {
            String name = report.Name;
            List<HTML_Report_vod__c> htmlReportsWithName = htmlReportsByName.get(name);

            String nameAndRecordType = htmlReportNameAndRecordType(report);
            List<HTML_Report_vod__c> htmlReportsWithNameAndRecordType = htmlReportsByNameAndRecordType.get(nameAndRecordType);

            // This may be null because the HTML Report may have a null Object_RecordType_vod__c value
            String nameAndObjectRecordType = htmlReportNameAndObjectRecordType(report);
            List<HTML_Report_vod__c> htmlReportsWithNameAndObjectRecordType = htmlReportsByNameAndObjectRecordType.get(nameAndObjectRecordType);

            if (htmlReportsWithName.size() == 1) {
                uniqueHtmlReportNameByHtmlReport.add(new HtmlReportWithUniqueName(name, report));
            } else if (htmlReportsWithNameAndRecordType.size() == 1) {
                uniqueHtmlReportNameByHtmlReport.add(new HtmlReportWithUniqueName(nameAndRecordType, report));
            } else if (htmlReportsWithNameAndObjectRecordType != null && htmlReportsWithNameAndObjectRecordType.size() == 1) {
                uniqueHtmlReportNameByHtmlReport.add(new HtmlReportWithUniqueName(nameAndObjectRecordType, report));
            } else {
                String nameAndRecordId = String.format('{0} ({1})', new List<String>{name, report.Id});
                uniqueHtmlReportNameByHtmlReport.add(new HtmlReportWithUniqueName(nameAndRecordId, report));
            }

        }
        return uniqueHtmlReportNameByHtmlReport;
    }

    private void updateHtmlReportsByName(List<HTML_Report_vod__c> reports) {
        for (HTML_Report_vod__c report : reports) {
            String name = report.Name;
            List<HTML_Report_vod__c> htmlReportsForName = getOrCreateHtmlReportList(name, htmlReportsByName);
            htmlReportsForName.add(report);
        }
    }
    
    private void updateHtmlReportsByNameAndRecordType(List<HTML_Report_vod__c> reports) {
        for (HTML_Report_vod__c report : reports) {
            String nameAndRecordType = htmlReportNameAndRecordType(report);
            List<HTML_Report_vod__c> htmlReportsForNameAndRecordType = getOrCreateHtmlReportList(nameAndRecordType, htmlReportsByNameAndRecordType);
            htmlReportsForNameAndRecordType.add(report);
        }    
    }
    
    private void updateHtmlReportsByNameAndObjectRecordType(List<HTML_Report_vod__c> reports) {
        for (HTML_Report_vod__c report : reports) {
            // It is possible that we may get a null value when HTML_Report_vod__c.Object_RecordType_vod__c is null
            String nameAndObjectRecordType = htmlReportNameAndObjectRecordType(report);
            // We will explicitly not add this HTML Report if it has a null Object_RecordType_vod__c value
            if (nameAndObjectRecordType != null) {
                List<HTML_Report_vod__c> htmlReportsForNameAndObjectRecordType = getOrCreateHtmlReportList(nameAndObjectRecordType, htmlReportsByNameAndObjectRecordType);
                htmlReportsForNameAndObjectRecordType.add(report);
            }
        }
    }

    private List<HTML_Report_vod__c> getOrCreateHtmlReportList(String key, Map<String, List<HTML_Report_vod__c>> mapToCheck) {
        List<HTML_Report_vod__c> htmlReports = mapToCheck.get(key);
        if (htmlReports == null) {
            htmlReports = new List<HTML_Report_vod__c>();
            mapToCheck.put(key, htmlReports);
        }
        return htmlReports;
    }

    private String htmlReportNameAndRecordType(HTML_Report_vod__c report) {
        return String.format('{0} ({1})', new List<String>{report.Name, report.RecordType.Name});
    }

    // Returns a null value when HTML_Report_vod__c.Object_RecordType_vod__c is null
    private String htmlReportNameAndObjectRecordType(HTML_Report_vod__c report) {
        String objectRecordTypeName = report.Object_RecordType_vod__c;
        if (objectRecordTypeName != null) {
            return String.format('{0} ({1})', new List<String>{report.Name, objectRecordTypeName});
        } else {
            return null;
        }
    }

}