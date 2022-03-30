public without sharing class VeevaSurveyTargetTriggerHandler {

    public void handleBeforeUpsert(List<Survey_Target_vod__c> newSurveyTargets, Map<Id, Survey_Target_vod__c> oldSurveyTargetsMap) {
        Set<Id> surveyIds = VEEVA_SURVEY_UTILS.getSurveyIds(newSurveyTargets);
        Map<Id, Survey_vod__c> surveyMap = new Map<Id, Survey_vod__c>([SELECT Id, Segment_vod__c, Target_Type_vod__c, Name FROM Survey_vod__c WHERE Id IN :surveyIds]);
        Map<Id, List<VEEVA_SURVEY_UTILS.Segment>> surveyIdToSegmentsMap = VEEVA_SURVEY_UTILS.createSurveyIdToSegmentsMap(surveyMap);
        Schema.DescribeFieldResult subDatetimeFld = Schema.SObjectType.Survey_Target_vod__c.fields.Submitted_DateTime_vod__c;
        Id userSurveyTargetRecordTypeId;
        DescribeSObjectResult surveyTargetDescribe = Survey_Target_vod__c.sObjectType.getDescribe();
        if (surveyTargetDescribe != null && surveyTargetDescribe.getRecordTypeInfosByDeveloperName().get('User_Survey_vod') != null) {
            userSurveyTargetRecordTypeId = surveyTargetDescribe.getRecordTypeInfosByDeveloperName().get('User_Survey_vod').getRecordTypeId();
        }

        Map<Survey_Target_vod__c, Id> targetToAccountIdMap = new Map<Survey_Target_vod__c, Id>();
        List<String> childAcctExtIds = new List<String>();
        List<Survey_Target_vod__c> surveyTargetsToProcess = new List<Survey_Target_vod__c>();
        for (Survey_Target_vod__c surveyTarget : newSurveyTargets) {
            // if an Entity_Reference_Id_vod exists, stamp the Account field with it
            if (surveyTarget.Entity_Reference_Id_vod__c != null && surveyTarget.Entity_Reference_Id_vod__c != '') {
                surveyTarget.Account_vod__c = surveyTarget.Entity_Reference_Id_vod__c;
                // clear Entity Refernce after being used
                surveyTarget.Entity_Reference_Id_vod__c = null;
            }

            if (userSurveyTargetRecordTypeId != null && userSurveyTargetRecordTypeId.equals(surveyTarget.RecordTypeId) && surveyMap.get(surveyTarget.Survey_vod__c) != null) {
                surveyTarget.Account_Display_Name_vod__c = (String) surveyMap.get(surveyTarget.Survey_vod__c).get('Name');
            }

            if (String.isNotEmpty(surveyTarget.Location_Entity_Reference_Id_vod__c)) {
                surveyTarget.Location_vod__c = surveyTarget.Location_Entity_Reference_Id_vod__c;
                surveyTarget.Location_Entity_Reference_Id_vod__c = null;
            }

            // Create a map of Survey Target to Account Id for filling out Account_Display_Name_vod__c
            if (surveyTarget.Account_vod__c != null) {
                targetToAccountIdMap.put(surveyTarget, surveyTarget.Account_vod__c);
            }

            surveyTarget.Segment_vod__c = null;
            Survey_Target_vod__c oldTarget = null;
            if (oldSurveyTargetsMap != null) {
                oldTarget = oldSurveyTargetsMap.get(surveyTarget.Id);
            }

            if (VEEVA_SURVEY_UTILS.isSubmittedStatus(surveyTarget.Status_vod__c)) {
                // Assign Segment
                List<VEEVA_SURVEY_UTILS.Segment> segments = surveyIdToSegmentsMap.get(surveyTarget.Survey_vod__c);
                if (segments != null && !segments.isEmpty() && surveyTarget.Score_vod__c != null) {
                    for (VEEVA_SURVEY_UTILS.Segment segment : segments) {
                        if (segment.containsScore(surveyTarget.Score_vod__c)) {
                            surveyTarget.Segment_vod__c = segment.getName();
                            break;
                        }
                    }
                }

                if (oldTarget == null || !VEEVA_SURVEY_UTILS.isSubmittedStatus(oldTarget.Status_vod__c)) {
                    // Logic for deciding between Submitted_vod and Late_Submission_vod statuses
                    if (surveyTarget.End_Date_vod__c < Date.today()) {
                        surveyTarget.Status_vod__c = 'Late_Submission_vod';
                    } else {
                        surveyTarget.Status_vod__c = 'Submitted_vod';
                    }

                    //Logic for setting Submitted_DateTime_vod field
                    if (subDatetimeFld != null && subDatetimeFld.isUpdateable() && surveyTarget.Submitted_DateTime_vod__c == null) {
                        Datetime submittedNow = Datetime.now();
                        surveyTarget.Submitted_DateTime_vod__c = submittedNow;
                    }
                }
            } else if (oldTarget != null && VEEVA_SURVEY_UTILS.isSubmittedStatus(oldTarget.Status_vod__c)) {
                //survey target change from submitted to not submitted, so clear submitted datetime
                surveyTarget.Submitted_DateTime_vod__c = null;
            }

            // Logic for getting child accounts based on account/location pairing for child account stamping
            if (surveyMap.get(surveyTarget.Survey_vod__c) != null) {
                surveyTarget.Target_Type_vod__c = (String) surveyMap.get(surveyTarget.Survey_vod__c).get('Target_Type_vod__c');
                if ('Child_Accounts_vod'.equals(surveyMap.get(surveyTarget.Survey_vod__c).get('Target_Type_vod__c'))) {
                    if (String.isEmpty(surveyTarget.Location_vod__c) || String.isEmpty(surveyTarget.Account_vod__c)) {
                        surveyTarget.addError('No Child Account matches the Account and Location pair.');
                        continue;
                    }
                    childAcctExtIds.add(surveyTarget.Location_vod__c + '__' + surveyTarget.Account_vod__c);
                    surveyTargetsToProcess.add(surveyTarget);
                }
            }
        }

        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Formatted_Name_vod__c FROM Account WHERE Id IN :targetToAccountIdMap.values()]);
        for(Survey_Target_vod__c target : targetToAccountIdMap.keySet()) {
            if (userSurveyTargetRecordTypeId == null || !userSurveyTargetRecordTypeId.equals(target.RecordTypeId)) {
                target.Account_Display_Name_vod__c = accounts.get(target.Account_vod__c).Formatted_Name_vod__c;
            }
        }

        // Stamp survey target child account field
        if (childAcctExtIds.size() > 0) {
            List<Child_Account_vod__c> childAccounts = [SELECT Id, External_ID_vod__c, Parent_Child_Furigana_vod__c FROM Child_Account_vod__c WHERE External_ID_vod__c IN :childAcctExtIds];
            Map<String, Child_Account_vod__c> externalIdToChildAcct = new Map<String, Child_Account_vod__c>();
            for (Child_Account_vod__c childAccount : childAccounts) {
                externalIdToChildAcct.put(childAccount.External_ID_vod__c, childAccount);
            }
            for (Survey_Target_vod__c surveyTarget : surveyTargetsToProcess) {
                String childAcctExtId = surveyTarget.Location_vod__c + '__' + surveyTarget.Account_vod__c;
                if (externalIdToChildAcct.get(childAcctExtId) != null) {
                    surveyTarget.Child_Account_vod__c = externalIdToChildAcct.get(childAcctExtId).Id;
                    surveyTarget.Account_Display_Name_vod__c = externalIdToChildAcct.get(childAcctExtId).Parent_Child_Furigana_vod__c;
                } else {
                    surveyTarget.addError('No Child Account matches the Account and Location pair.');
                }
            }
        }
    }
}