public class Survey_Target_Extension_vod {
    public Survey_Target_Extension_vod(ApexPages.StandardController stdCtrl) {
        List<String> queryFldNames = new List<String>();
        queryFldNames.add('RecordType.DeveloperName');
        queryFldNames.add('Report_Status_vod__c');
        queryFldNames.add('Employee_vod__c');
        stdCtrl.addFields(queryFldNames);
        this.surveyTarget = (Survey_Target_vod__c)stdCtrl.getRecord();
    }

    public String getQueryParamsStr() {
        Map<String, String> paramMap = ApexPages.currentPage().getParameters();
        System.PageReference pageReference = new System.PageReference('');
        pageReference.getParameters().putAll(paramMap);
        return pageReference.getUrl().substring(1);
    }

    public String getVeevaPageForEdit() {
        return canEditSurveyTarget() ? 'edit-survey-target' : 'view-survey-target';
    }

    private boolean canEditSurveyTarget() {
        if (surveyTarget.RecordType.DeveloperName == 'Coaching_Report_vod') {
            return (surveyTarget.Report_Status_vod__c == 'Under_Employee_Review_vod' && surveyTarget.Employee_vod__c == UserInfo.getUserId())
                || surveyTarget.Report_Status_vod__c == 'In_Progress_vod'
                || ApexPages.currentPage().getParameters().get('clone') == 'coachingReport';
        }
        return surveyTarget.Id == null || ApexPages.currentPage().getParameters().get('editAccess') == 'true';
    }

    private final Survey_Target_vod__c surveyTarget;
}