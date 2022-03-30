public without sharing class VeevaWechatSuggestions{
    public static final String ACTIVE_SUGGESTION_SELECTION;
    public static final String ACTIVE_SUGGESTION_BASIC_CONDITION;
    public static final String MY_SETUP_PRODUCTS_SELECTION;
    static {
        ACTIVE_SUGGESTION_SELECTION = 'SELECT Id, OwnerId, CreatedDate,' +
            ' (SELECT Record_Type_Name_vod__c,' +
            ' Product_vod__r.Id, Product_vod__r.Restricted_vod__c,' +
            ' Detail_Group_vod__r.Id, Detail_Group_vod__r.Restricted_vod__c' +
            ' FROM Suggestion_Tags_vod__r)' + 
            ' FROM Suggestion_vod__c ';    
        ACTIVE_SUGGESTION_BASIC_CONDITION = 'WHERE Record_Type_Name_vod__c IN (\'WeChat_vod\', \'Call_vod\', \'Insight_vod\', \'WeChat_Call_vod\')' +
            ' AND (Dismissed_vod__c = 0 OR Dismissed_vod__c = null)' +
            ' AND (Actioned_vod__c = 0 OR Actioned_vod__c = null)' +
            ' AND (Marked_As_Complete_vod__c = 0 OR Marked_As_Complete_vod__c = null)' +
            ' AND (Expiration_Date_vod__c = null OR Expiration_Date_vod__c > Today)' + 
            ' AND Account_vod__r.Do_Not_Call_vod__c != \'Yes_vod\'';
        MY_SETUP_PRODUCTS_SELECTION = 'SELECT OwnerId, Product_vod__c FROM My_Setup_Products_vod__c';
    }
    
    public void fetchNewActiveSuggestions(Map<String, VeevaWechatSuggestionSummary.UserSuggestionSummary> userSuggestionMap, DateTime runTime, DateTime lastRunTime){
        if(userSuggestionMap == null || userSuggestionMap.isEmpty() || runTime == null){
            return;
        }

        Set<String> userIds = userSuggestionMap.keySet();
        String activeSuggestionCondition = ' AND OwnerId IN :userIds AND CreatedDate <= :runTime';
        if (lastRunTime != null) {
            activeSuggestionCondition = activeSuggestionCondition + ' AND CreatedDate > :lastRunTime';
        }
        // Get newly created active suggestions since last run
        List<Suggestion_vod__c> activeSuggestions = Database.query(ACTIVE_SUGGESTION_SELECTION + ACTIVE_SUGGESTION_BASIC_CONDITION + 
                                                                   activeSuggestionCondition);

        Map<String, Set<String>> userToProducts = getUserProducts(userIds);
        Set<String> products = new Set<String> ();
        Boolean valid = true;
        String ownerId;
        for (Suggestion_vod__c suggestion:activeSuggestions){
            ownerId = suggestion.OwnerId;
            products = userToProducts.get(ownerId);
            if (isValidSuggestion(suggestion, products)) {
                VeevaWechatSuggestionSummary.UserSuggestionSummary summary = userSuggestionMap.get(ownerId);
                summary.hasSuggestion = true;
                summary.count++;
            } 
        }
    }

    private Map<String, Set<String>> getUserProducts(Set<String> userIds){
        Map<String, Set<String>> results = new Map<String, Set<String>>();
        List<My_Setup_Products_vod__c> userProducts = Database.query(MY_SETUP_PRODUCTS_SELECTION + ' WHERE OwnerId IN :userIds');
        for (My_Setup_Products_vod__c mySetupProducts:userProducts) {
            Set<String> products = results.get(mySetupProducts.OwnerId);
            if (products == null) {
                products = new Set<String>();
                results.put(mySetupProducts.OwnerId, products);
            }
            products.add(mySetupProducts.Product_vod__c);
        }
        return results;
    }

    private Boolean isValidSuggestion(Suggestion_vod__c suggestion, Set<String> mySetupProducts) {
        String ownerId = suggestion.OwnerId;
        // check suggestion tags
        if (!suggestion.Suggestion_Tags_vod__r.isEmpty()) {
            List<Suggestion_Tag_vod__c> tags = suggestion.Suggestion_Tags_vod__r;
            for (Suggestion_Tag_vod__c tag: tags) {
                if(!isValidSuggestionTag(tag, mySetupProducts)){
                    return false;  
                }
            }
        }
        return true;
    }

    private Boolean isValidSuggestionTag(Suggestion_Tag_vod__c tag, Set<String> mySetupProducts){
        // 1. When Suggestion Tags Type is Product_vod, the product and detail group MUST be in My Setup Product; 
        // 2. Restricted_vod__c is unchecked.
        if (tag.Record_Type_Name_vod__c.equals('Product_vod') && !mySetupProducts.isEmpty()) {
            if (tag.Product_vod__c == null || !mySetupProducts.contains(tag.Product_vod__c)) {
                return false;
            }
            if (tag.Detail_Group_vod__c != null && !mySetupProducts.contains(tag.Detail_Group_vod__c)) {
                return false;
            }
        }  
        if(tag.Product_vod__c != null && tag.Product_vod__r.Restricted_vod__c){
            return false;
        }  
        return true;
    }
}