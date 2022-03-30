trigger GASVisibilityConfigurationBefore on GAS_Visibility_Configuration__c (before insert, before update) {
	
	//NOTE::allValidEntities() also updates the Trigger.New for Entity Id
	if(!GASUtilities.allValidEntities(Trigger.new)){
			Trigger.new[0].addError('One or more Configuration objects in the batch have invalid Entity Name');		
	}

	Integer i = 0;
	for(GAS_Visibility_Configuration__c aGVC: Trigger.new){
		if(CustomVeevaUtilities.getSObjectType(aGVC.Object_API_Name__c) !=null){
				
			if(aGVC.Object_API_Name__c == 'Account' && aGVC.Account_Lookup_Field_API_Name__c != null){
				aGVC.Account_Lookup_Field_API_Name__c = null;
			}
			if(aGVC.Object_API_Name__c != 'Account' && aGVC.Account_Lookup_Field_API_Name__c == null){
				aGVC.addError(' Must have a valid value for Account_Lookup_Field_API_Name__c for non-Account Objects. GVC Entity Name: ' + aGVC.Name);						
			}
			if(aGVC.Account_Lookup_Field_API_Name__c!=null 
					&& CustomVeevaUtilities.getSObjectField(aGVC.Object_API_Name__c, aGVC.Account_Lookup_Field_API_Name__c)==null){
				aGVC.addError(aGVC.Account_Lookup_Field_API_Name__c + ' value for Account_Lookup_Field_API_Name__c on GVC with Entity Name ' + aGVC.Name + ' is Invalid');						
			}
			if(aGVC.Exclusive_criteria__c && aGVC.Entity_Type__c != 'User'){
				aGVC.addError('GVC with Entity Name ' + aGVC.Name + ' must be of Entity Type \'User\' to use Exclusive Criteria');						
			}
			aGVC.External_Id__c = aGVC.Entity_Id__c + aGVC.Object_API_Name__c;
			
		}
		else{
				aGVC.addError(aGVC.Object_API_Name__c + ' value for Object_API_Name__c on GVC with Entity Name ' + aGVC.Name + ' is Invalid');		
		}
		//check to ensure the Dynamic SOQL will work ok
     try{
            GASUtilities.getMatchingAccountIds(aGVC.Custom_Criteria__c, aGVC.Object_API_Name__c, aGVC.Account_Lookup_Field_API_Name__c, null);
        }catch(System.QueryException e){
            System.debug('Query Exception..ignore because this is just a compile check and having the exception means query compiled successfully');
            System.debug(e.getMessage());
        }
 	}
}