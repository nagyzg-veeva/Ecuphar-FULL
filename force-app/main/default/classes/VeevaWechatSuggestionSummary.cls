/**
 * This class should organize UserSuggestionSummary data ONLY, and call other classes to fetch suggestion data from DB
 */
global inherited sharing class VeevaWechatSuggestionSummary {

    /* Used by batch process to fetch suggestion data without sharing rule */
    public List<UserSuggestionSummary> getNewlyCreatedSuggestions(List<UserSuggestionSummary> resultList, DateTime runTime, DateTime lastTime){
        if(resultList == null || resultList.isEmpty() || runTime == null ){
            return resultList;
        }

        Map<String, UserSuggestionSummary> userSuggestionMap = parseUserSuggestion(resultList);            
        VeevaWechatSuggestions suggestionRepository = new VeevaWechatSuggestions();
        suggestionRepository.fetchNewActiveSuggestions(userSuggestionMap, runTime, lastTime);
        return resultList;
    }
    
    /* One WeChat user ONLY map to one Salesforce user */
    private Map<String, UserSuggestionSummary> parseUserSuggestion(List<UserSuggestionSummary> userSuggestionList){
        Map<String, UserSuggestionSummary> results = new Map<String, UserSuggestionSummary>();
        for(UserSuggestionSummary uss : userSuggestionList){
            // Reset summary info
            uss.hasSuggestion = false;
            uss.count = 0;
            results.put(uss.userId, uss);
        }
        return results;
    }

    global class UserSuggestionSummary{
        public UserSuggestionSummary(){
            this.hasSuggestion = false;
            this.count = 0;
        }
        public UserSuggestionSummary(String wechatName, String userId){
            this.wechatName = wechatName;
            this.userId = userId;
            this.hasSuggestion = false;
            this.count = 0;
        }
        global String wechatName {get; set;}
        global String userId {get; set;}
        global boolean hasSuggestion {get; set;}
        global integer count {get; set;}
    }
}