trigger VOD_CONSENT_TYPE_AFTER_INSUPDDEL on Consent_Type_vod__c (after insert, after update, after delete) {   
    
    Boolean errorFound = false;
    List<Consent_Type_vod__c> cts = new List<Consent_Type_vod__c> ();
    Set<String> contextHeaderIds = new Set<String>();

    String errorTextNull = VOD_VEEVA_MESSAGE.getMsgWithDefault('DOUBLE_OPT_IN_NULL_CONSENT_ERROR', 'ConsentCapture', 'Default Consent cannot be null when enabling Double Opt in.');
    String errorText = VOD_VEEVA_MESSAGE.getMsgWithDefault('DOUBLE_OPT_IN_NON_EMAIL_SOURCE_ERROR', 'ConsentCapture', 'Reference fields only of type Email in Channel_Source_vod to enable Double Opt in.');


    if (Trigger.isInsert || Trigger.isUpdate) {
        cts = Trigger.New;
        for(Consent_Type_vod__c ct : Trigger.New) {
            contextHeaderIds.add(ct.Consent_Header_vod__c);
            if (ct.Double_Opt_In_vod__c) {
                //if double opt in is selected and the Default Consent Type is null vod then add an error
                if (ct.Default_Consent_Type_vod__c == null) {
                    ct.addError(errorTextNull, false);
                }
                // get the fields map to validate the email type fields in case of double opt in
                Map<String, Schema.SObjectField> accountFieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
                Map<String, Schema.SObjectField> addressFieldsMap = Schema.getGlobalDescribe().get('Address_vod__c').getDescribe().fields.getMap();

                if (ct.Channel_Source_vod__c != null) {
                    String[] fieldsData = ct.Channel_Source_vod__c.split(';;');
                    if (fieldsData != null) {                        
                        for (String name : fieldsData) {
                            List<String> objFieldName = name.split('\\.');
                            if (objFieldName != null && objFieldName.size()== 2) {
                                String objectName = objFieldName.get(0);
                                String fieldName= objFieldName.get(1); 
                                if (objectName.equals('Account')) {    
                                    // validate account fields
                                    if (accountFieldsMap.get(fieldName) != null) {                                
                                        Schema.DisplayType fielddataType = accountFieldsMap.get(fieldName).getDescribe().getType(); 
                                        if(fielddataType != Schema.DisplayType.Email) {
                                            // throw error here
                                            ct.addError(errorText , false);   
                                        } 
                                    } else {
                                        // invalid field
                                        ct.addError(errorText , false);                                    
                                    }                                                                
                                } else if (objectName.equals('Address_vod__c')) {
                                    // validate address fields
                                    if (addressFieldsMap.get(fieldName) != null) {
                                        Schema.DisplayType fielddataType = addressFieldsMap.get(fieldName).getDescribe().getType();   
                                        if(fielddataType != Schema.DisplayType.Email) {
                                            // throw error here
                                            ct.addError(errorText , false);   
                                        } 
                                    } else {
                                        ct.addError(errorText , false); 
                                    }                                                                                              
                                } else {
                                    // invalid value
                                    ct.addError(errorText , false);      
                                }                                
                            } else {
                                ct.addError(errorText , false);  
                            }
                        }                 
                        
                    } else {
                        // if the fields are empty are not write format
                        ct.addError(errorText , false);                 
                    }                    
                } else {
                    // the channel source can not be empty if its double opt in
                    ct.addError(errorText , false);                 
                }          
            }               
        }
          
    } else if (Trigger.isDelete) {
        cts = Trigger.Old; 
        for(Consent_Type_vod__c ct : Trigger.Old) {
               contextHeaderIds.add(ct.Consent_Header_vod__c);
        }   
    
    }
    
    for(Consent_Header_vod__c chr : [SELECT Id, Name, Status_vod__c FROM Consent_Header_vod__c Where Id IN :contextHeaderIds]){        
        if (chr.Status_vod__c == 'Active_vod') {
            errorFound = true;     
            break;        
        }
    }     
    
    if (errorFound) {
         // fetch the error message to be thrown
        List<Message_vod__c> messages = [Select Text_vod__c From Message_vod__c WHERE Name='ACTIVE_HEADER_UPDATE' AND Category_vod__c='ConsentCapture' AND Active_vod__c=true AND Language_vod__c=:userInfo.getLanguage()];
        String errorText;
        if(messages.size() != 0){
            errorText = messages[0].Text_vod__c;
        } else { // default to english hardcoded
            errorText = 'No records can be created, updated or deleted when Consent Header record is active.';    
        }
        
        
        for(Consent_Type_vod__c ct : cts ){
            ct.addError(errorText, false);        
        }   
    }
}