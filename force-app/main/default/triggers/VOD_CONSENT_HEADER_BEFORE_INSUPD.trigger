trigger VOD_CONSENT_HEADER_BEFORE_INSUPD on Consent_Header_vod__c (before insert, before update) {

    //Set<String> newRecordsUniqueKeys = new Set<String> ();
    Set<String> recordTypeIds = new Set<String> ();
    for(Consent_Header_vod__c ch :Trigger.New) {
        recordTypeIds.add(ch.recordTypeId);
    }

    // now query the consent header object for the record type ids in the set
    Set<String> existingRecordsUniqueKeys = new Set<String> ();
    Set<Id> consentHeaderActiveUniqueIds = new Set<Id>();
    Map<Id, Set<String>> typeIdCHPickListMap = new Map<Id, Set<String>> ();
    Map<Id, Set<String>> typeIdCHCountryPickListMap = new Map<Id, Set<String>>();


    for (Consent_Header_vod__c chdr : [SELECT Id, RecordTypeId, Country_vod__c, Language_vod__c, Approved_Email_Consent_Level_vod__c
                                   FROM Consent_Header_vod__c
                                   WHERE Status_vod__c = 'Active_vod' and RecordtypeId IN :recordTypeIds]) {
        String uniqueKey = chdr.recordTypeId + '_' + chdr.Country_vod__c + '_' + chdr.Language_vod__c;
        existingRecordsUniqueKeys.add(uniqueKey);
	consentHeaderActiveUniqueIds.add(chdr.Id);
        if (chdr.Approved_Email_Consent_Level_vod__c == 'Product_vod' || chdr.Approved_Email_Consent_Level_vod__c == 'Content_Type_vod') {
            String uniquePickValue = chdr.recordTypeId + '_' + chdr.Country_vod__c + '_' + chdr.Approved_Email_Consent_Level_vod__c;
            Set<String> countryAEPickValueUnique;
            Set<String> countryAEValues;
            if (typeIdCHPickListMap.containsKey(chdr.recordTypeId)) {
                countryAEPickValueUnique= typeIdCHPickListMap.get(chdr.recordTypeId);
                countryAEPickValueUnique.add(uniquePickValue );
                typeIdCHPickListMap.put(chdr.recordTypeId, countryAEPickValueUnique);
                countryAEValues = typeIdCHCountryPickListMap.get(chdr.recordTypeId);
                countryAEValues.add(chdr.Country_vod__c);
                typeIdCHCountryPickListMap.put(chdr.recordTypeId, countryAEValues);
            } else {
                countryAEPickValueUnique= new Set<String> ();

                // first time no need to check for error
                countryAEPickValueUnique.add(uniquePickValue);
                typeIdCHPickListMap.put(chdr.recordTypeId, countryAEPickValueUnique);

                countryAEValues = new Set<String>();
                countryAEValues.add(chdr.Country_vod__c);
                typeIdCHCountryPickListMap.put(chdr.recordTypeId, countryAEValues);
            }
        }

    }

    // fetch the error message to be thrown
    Map<String, String> errorMessages = getErrorMessages();

    for(Consent_Header_vod__c ch :Trigger.New) {
        String uniqueKey = ch.recordTypeId + '_' + ch.Country_vod__c + '_' + ch.Language_vod__c;
        if (ch.Status_vod__c == 'Active_vod') {
            if (consentHeaderActiveUniqueIds.contains(ch.Id)) {
                ch.addError(errorMessages.get('ACTIVE_HEADER_UPDATE'), false);
                continue;
            } else if (existingRecordsUniqueKeys.contains(uniqueKey)) {
                ch.addError(errorMessages.get('CONSENT_HEADER_UNIQUE_ERROR'), false);
                continue;
            }
        }

        // also check if there is any error to be thrown for pick list value
        String uniquePickValueErr = ch.recordTypeId + '_' + ch.Country_vod__c + '_' + ch.Approved_Email_Consent_Level_vod__c;
        if (ch.Status_vod__c == 'Active_vod' && typeIdCHPickListMap.containsKey(ch.RecordTypeId)) {
            Set<String> pickValueUnique = typeIdCHPickListMap.get(ch.RecordTypeId);
            Set<String> countrySet = typeIdCHCountryPickListMap.get(ch.RecordTypeId);
            if (countrySet.contains(ch.Country_vod__c) && !pickValueUnique.contains(uniquePickValueErr)) {
                ch.addError(errorMessages.get('DIFFERENT_AE_CONSENT_LEVEL'), false);
                continue;
            }
        }

        if(ch.Allow_Confirmation_by_Email_vod__c && ch.Signature_Required_On_Opt_Out_vod__c) {
            ch.addError(errorMessages.get('CONSENT_HEADER_OPTOUT_SIGNATURE_SUPPORT_ERROR'), false);
            continue;
        }

        // now if error was not thrown update the Inactive date time field
        if (ch.Status_vod__c == 'Inactive_vod') {
            ch.Inactive_Datetime_vod__c = System.now();
        }  else { // clear the inactive date time field
            ch.Inactive_Datetime_vod__c = NULL;
        }

    }

    private Map<String, String> getErrorMessageDefaults() {
        Map<String, String> errorMessagesDefaults = new Map<String, String>();
        errorMessagesDefaults.put('ACTIVE_HEADER_UPDATE', 'No records can be created, updated or deleted when Consent Header record is active.');
        errorMessagesDefaults.put('CONSENT_HEADER_UNIQUE_ERROR', 'Only one active record per country per language per recordtype');
        errorMessagesDefaults.put('DIFFERENT_AE_CONSENT_LEVEL', 'Approved_Email_Consent_Level has been set differently for Consent_Header_vod of same country.');
        errorMessagesDefaults.put('CONSENT_HEADER_OPTOUT_SIGNATURE_SUPPORT_ERROR', '"Signature Required on Opt-Out" is not supported when "Allow Confirmation by Email" is enabled');
        return errorMessagesDefaults;
    }

    private Map<String, String> getErrorMessageFromQuery(Set<String> messageNames) {
        List<Message_vod__c> errorMessages = [Select Name, Text_vod__c From Message_vod__c WHERE Name IN: messageNames AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
        Map<String, String> queryResults = new Map<String, String>();
        if(errorMessages != null && errorMessages.size() > 0) {
            for(Message_vod__c errorMessage : errorMessages) {
                String text = errorMessage.Text_vod__c;
                if(text != null && text.length() > 0) {
                    queryResults.put(errorMessage.Name, text);
                }
            }
        }
        return queryResults;
    }

    private Map<String, String> getErrorMessages () {
        Map<String, String> errorMessages = getErrorMessageDefaults();
        Map<String, String> queryResults = getErrorMessageFromQuery(errorMessages.keySet());
        errorMessages.putAll(queryResults);
        return errorMessages;
    }

}