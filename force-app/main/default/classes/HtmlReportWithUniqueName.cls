public with sharing class HtmlReportWithUniqueName implements Comparable {
    private final String uniqueName;
    private final HTML_Report_vod__c report;

    public HtmlReportWithUniqueName(String uniqueName, HTML_Report_vod__c report) {
        if (uniqueName == null) {
            this.uniqueName = '';
        } else {
            this.uniqueName = uniqueName;
        }
        this.report = report;
    }

    public String getUniqueName() {
        return uniqueName;
    }

    public HTML_Report_vod__c getReport() {
        return report;
    }


    public Integer compareTo(Object obj) {
        if (obj != null && obj instanceof HtmlReportWithUniqueName) {
            HtmlReportWithUniqueName other = (HtmlReportWithUniqueName) obj;
            return this.uniqueName.toLowerCase().compareTo(other.uniqueName.toLowerCase());
        } else {
             // we will say the other object is less than us if it is null or not a type of HtmlReportWithUniqueName
            return 1;
        }
    }
}