public with sharing class VeevaDCRAccessController {    
    
    @AuraEnabled
    public static boolean hasDCRForAccount(String accountId, boolean auraComp) {
        String pathWithQueryStrings = '/api/v1/network/dcr/requirements?objectType=Account&recordId=' + accountId;
        return isDcrRequired(pathWithQueryStrings, auraComp);
    }

    @AuraEnabled
    public static boolean hasDCRForAddress(String addressId, boolean auraComp) {
        String pathWithQueryStrings = '/api/v1/network/dcr/requirements?objectType=Address_vod__c&recordId=' + addressId;
        return isDcrRequired(pathWithQueryStrings, auraComp);
    }

    private static boolean isDcrRequired(String pathWithQueryStrings, boolean auraComp) { 
        boolean dcrRequired;
        Map<Integer, String> statusToResponse = VeevaCRMRequestService.get(pathWithQueryStrings, null, auraComp);
        if (statusToResponse.containsKey(200)) {
            String stringResponse = statusToResponse.get(200);
            dcrRequired = getDcrRequiredFromResponse(stringResponse);
        } else if (statusToResponse.containsKey(400)) {
            String errorMessage = '';
            for (Integer key : statusToResponse.keySet()) {
                errorMessage += getErrorMessageFromBadRequest(statusToResponse.get(key));
            }
            throw new AuraHandledException(errorMessage);
        } else {
            throw new AuraHandledException('Could not get DCR Requirement from CRM Server ' + VeevaCRMRequestService.getCRMServer());
        }
        return dcrRequired;
    }

    private static String getErrorMessageFromBadRequest(String stringResponse) {
        String errorMesssage = '';
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(stringResponse);
        if (response != null && response.containsKey('message')) {
            errorMesssage += response.get('message');
        }
        return errorMesssage;
    }

    private static boolean getDcrRequiredFromResponse(String stringResponse) {
        boolean dcrRequired;
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(stringResponse);
        if (response != null && response.containsKey('data')) {
            Map<String, Object> data = (Map<String, Object>)response.get('data');
            dcrRequired = (boolean) data.get('dcrRequired');
        }
        return dcrRequired;
    }
}