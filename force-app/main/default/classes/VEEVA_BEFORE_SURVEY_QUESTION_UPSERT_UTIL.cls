public class VEEVA_BEFORE_SURVEY_QUESTION_UPSERT_UTIL {
    public static void validateSourceIdForSurveyQuestions(List<Survey_Question_vod__c> surveyQuestions) {
        String duplicateErrMsg = VOD_VEEVA_MESSAGE.getMsgWithDefault('MIGRATION_STATUS_DUPLICATE_FOUND', 'CLM', 'Duplicate of Survey Question') + ' ';
        Set<String> surveyIds = new Set<String>();
        Set<String> sourceIds = new Set<String>();
        Set<String> surveyQuestionIds = new Set<String>();
        //Using Survey_Question_vod__c as the value, instead of the Survey Question Id, because in the case of insert, Survey Questions won't have an Id, not even an intermediate one
        Map<String, Survey_Question_vod__c> compoundKeyToSurveyQuestions = new Map<String, Survey_Question_vod__c>();
        
        //check if any trigger survey questions are duplicates of each other
        for (Survey_Question_vod__c sQuestion : surveyQuestions) {
            String sourceId = sQuestion.Source_ID_vod__c;
            if (sourceId != null) {
                String compoundKey = sQuestion.Survey_vod__c + sourceId;
                Survey_Question_vod__c duplicate = compoundKeyToSurveyQuestions.get(compoundKey);
                if (duplicate != null) { 
                    String dupId = duplicate.Id;
                    String namedDuplicate = dupId != null ? dupId : compoundKey;
                    sQuestion.addError(duplicateErrMsg + namedDuplicate);
                } else {
                    surveyIds.add(sQuestion.Survey_vod__c);
                    sourceIds.add(sourceId);
                    if (sQuestion.Id != null) {
                        surveyQuestionIds.add(sQuestion.Id);
                    }
                    compoundKeyToSurveyQuestions.put(compoundKey, sQuestion);
                }
            }
        }
        //check if any trigger survey questions are duplicates of existing (non-trigger) survey questions
        for (Survey_Question_vod__c existingQuestion : [
                SELECT Id, Source_ID_vod__c, Survey_vod__c 
                FROM Survey_Question_vod__c 
                WHERE Survey_vod__c IN :surveyIds 
                AND Source_ID_vod__c IN :sourceIds 
                AND Id NOT IN :surveyQuestionIds]) {
            String compoundKey = existingQuestion.Survey_vod__c + existingQuestion.Source_ID_vod__c;
            Survey_Question_vod__c duplicate = compoundKeyToSurveyQuestions.get(compoundKey);
            if (duplicate != null) {
                duplicate.addError(duplicateErrMsg + existingQuestion.Id);
            }
            //Not adding existingQuestion to the map, because existing records should not be duplicates of each other, and thus we should only be concerned with checking trigger records for errors.
        }
    
    }

}