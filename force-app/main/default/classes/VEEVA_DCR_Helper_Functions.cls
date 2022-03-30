public with sharing class VEEVA_DCR_Helper_Functions {
    
    //Check that account record type is a cegedim enabled account 
    public Boolean isDCRAccountRecordType(String recordType){
        //get enabled recrod types from CS
        DCR_Settings__c settings = DCR_Settings__c.getInstance('CCRMS');
        List<String> enabledRTWithCountryList = new List<String>();
        if(settings == null){
            String SerrMsg = recordType + ' Custom setting not set. See at: BHC_UPA_provisional_account_settings__c';
            System.debug(SerrMsg);
            return null;
        }else{      
            //Parse Veeva Message content format: (rt1:country;;rt2:country) and check if there is any hit for record type name
             
            enabledRTWithCountryList = getVeevaMsgByName(settings.DCR_Prov_Acc_RT_Names__c).split(';;');
            if(enabledRTWithCountryList.size()>0){
                for(String item : enabledRTWithCountryList){
                    List<String> rtCountry = item.split(':');
                    system.debug('####### DCR-Help: RT Parse: ' + rtCountry[0] +' <-> '+ recordType +': '+(rtCountry[0].equals(recordType)));
                    if(rtCountry[0].deleteWhitespace() == recordType.deleteWhitespace()){
                        return true;
                    }                    
                }
            } 
            else if ((enabledRTWithCountryList = (settings.DCR_Prov_Acc_RT_Names__c).split(';;')).size()>0){
                for(String item : enabledRTWithCountryList){
                    List<String> rtCountry = item.split(':');
                    if(rtCountry[0].equals(recordType)){
                        return true;
                    }                    
                }

            }          
            return false;
        }       
    } 

    //Check that record type is an enabled RT 
    public Boolean isDCRRecordType(String recordType){
        //get enabled recrod types from CS
        DCR_Settings__c settings = DCR_Settings__c.getInstance('CCRMS');
        List<String> enabledRTWithCountryList = new List<String>();
        if(settings == null){
            String SerrMsg = recordType + ' Custom setting not set. See at: BHC_UPA_provisional_account_settings__c';
            System.debug(SerrMsg);
            return null;
        }else{      
            //Parse Veeva Message content format: (rt1:country;;rt2:country) and check if there is any hit for record type name
             
            enabledRTWithCountryList = getVeevaMsgByName(settings.DCR_Prov_Acc_RT_Names__c).split(';;');
            if(enabledRTWithCountryList.size()>0){
                for(String item : enabledRTWithCountryList){
                    List<String> rtCountry = item.split(':');
                    system.debug('####### DCR-Help: RT Parse: ' + rtCountry[0] +' <-> '+ recordType +': '+(rtCountry[0].equals(recordType)));
                    if(rtCountry[0].deleteWhitespace() == recordType.deleteWhitespace()){
                        return true;
                    }                    
                }
            } 
            else if ((enabledRTWithCountryList = (settings.DCR_Prov_Acc_RT_Names__c).split(';;')).size()>0){
                for(String item : enabledRTWithCountryList){
                    List<String> rtCountry = item.split(':');
                    if(rtCountry[0].equals(recordType)){
                        return true;
                    }                    
                }

            }          
            return false;
        }       
    } 
    
    //Check that DCR is rejected by Cegedim
    public Boolean isDCRRejected(String status){
        //get enabled recrod types from CS
        DCR_Settings__c settings = DCR_Settings__c.getInstance('CCRMS');
        if(settings == null){
            String SerrMsg = status + ' Custom setting not set. See at: BHC_UPA_provisional_account_settings__c';
            System.debug(SerrMsg);
            return null;
        }else{      
            String cgmValue = settings.Cegedim_DCR_Reject_Response__c;          
            return cgmValue == status;
        }       
    } 
    
    
    //get DCr statuses from Custom Settings 
    //Available options: valid, invalid, provisional
    public String getStatusCustomSetting(String status){
         
        
        DCR_Settings__c settings = DCR_Settings__c.getInstance('CCRMS');
        if(settings == null){
            String SerrMsg = status + ' Custom setting not set. See at: DCR_Settings__c';
            System.debug(SerrMsg);
            return null;
        }else{
            if(status == 'provisional'){
                return settings.Provisional_Status__c;
            }else if(status == 'invalid'){
                return settings.Invalid_Status__c;
            }else if(status == 'valid'){
                return settings.Valid_Status__c;
            }else{
                //invalid status
                return null;
            }
        }
        //return null;    
    }  
    
    
    //Returns a veeva message text by given name
    public String getVeevaMsgByName(String VeevaMsgName){
        Message_vod__c veevaMsg = [SELECT Name, Text_vod__c FROM Message_vod__c WHERE Active_vod__c = true AND Name = :VeevaMsgName];
        String text = veevaMsg.Text_vod__c;
        text = text.trim();
        return text;
    }
    
    
    //Returns a Record Type map for given Object containing RT Id, Name, DeveloperName
    public Map<ID, RecordType> mapRecordTypeDeveloperNamesForObject(String objectName){
        RecordType[] rts = [SELECT Id, Name, DeveloperName  FROM RecordType WHERE SObjectType = :objectName];
        
        Map<ID, RecordType> rtDevNames = new Map<Id, RecordType>();
        if(rts.size() >0){
            for(RecordType rt:rts){
                rtDevNames.put(rt.Id, rt);
            }
        }    
        return rtDevNames;
    } 

    public Map<ID, RecordType> mapRecordTypeDeveloperNames(){
        RecordType[] rts = [SELECT Id, Name, DeveloperName, SObjectType  FROM RecordType];
        
        Map<ID, RecordType> rtDevNames = new Map<Id, RecordType>();
        if(rts.size() >0){
            for(RecordType rt:rts){
                rtDevNames.put(rt.Id, rt);
            }
        }    
        return rtDevNames;
    } 
    
    //Check if object field can be added when creating object, or can't be modified so needs to excluded
    public Boolean isFieldExcluded(String fieldApiName, String objectName){
        Set<String> excludedFields = new Set<String>{'LastModifiedDate', 'LastModifiedById','CreatedDate','CreatedById'};
        Set<String> accountAdditionalFields = new Set<String>{'IsPersonAccount','Formatted_Name_vod__c','Customer_Master_Status_vod__c','OwnerId','Account_Search_FirstLast_vod__c','Account_Search_LastFirst_vod__c'};
        Set<String> addressAdditionalFields = new Set<String>{'Customer_Master_Status_vod__c','OwnerId','Entity_Reference_Id_vod__c'};
        Set<String> childAccountAdditionalFields = new Set<String>{'Primary_vod__c'};
        
        if(objectName == 'Account'){
            excludedFields.addAll(accountAdditionalFields);            
        }else if(objectName == 'Address_vod__c'){
            excludedFields.addAll(addressAdditionalFields); 
        }else if(objectName == 'Child_Account_vod__c'){
            excludedFields.addAll(childAccountAdditionalFields); 
        }
       
        if(excludedFields.contains(fieldApiName)){
            return true;
        }              
        return false;
    }
    
    
}