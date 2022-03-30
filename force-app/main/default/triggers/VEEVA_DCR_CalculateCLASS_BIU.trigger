/*************************************************************************************************
Calculate the default  value  for the fields  which  are needed by the DCR  object
Handle  scenarios  for the 3 Record types  and 2 Change type(Create.Update/Delete)
Get the default  values  from the INDIVIDUAL/WKP Accounts  and  from ChildAccount.
THIS trigger  is customer  specific.  The mandatory fileds whivch has to be defaulted might differ
from country  to country
*************************************************************************************************/
trigger VEEVA_DCR_CalculateCLASS_BIU on V2OK_Data_Change_Request__c (before insert, before update) 
{
		
	if (trigger.new[0].Request_sent__c == true)  
	{
		//2013.01.26. assure that user can no longer change the DCR  after  Request_set = true ** 
		if (trigger.isUpdate == true)
		{			
			String NewResponse = trigger.new[0].Data_Request_Response__c;  
			if (trigger.old[0].Request_sent__c == true && NewResponse == NULL)
			   trigger.new[0].addError('You can not change a request where Request Sent = true');  
		} 
		//2013.01.26. assure that user can no longer change the DCR  after  Request_set = true ** 		   
	    return;
	}
	
	//****************************** Handle ENTER in Text  2012.10.02. ********************************************************
	String Mydesc = trigger.new[0].Description__c;
	if (Mydesc != NULL)
	{
	String[] splitu = Mydesc.split('\n');   
	
	if (splitu.size() > 1)
		{
		trigger.new[0].Description__c.addError('do not use ENTER character in the Description. Type all text in 1 line!');
		return;	
		}		
	}
	//****************************** Handle ENTER in Text  2012.10.02. ********************************************************
	
	RecordType RT = [Select DeveloperName from RecordType where Id = :trigger.new[0].RecordTypeId];
	String RT_Name = RT.DeveloperName;	
	
	VEEVA_DCR_HLP HelperObj = new VEEVA_DCR_HLP();  //2012.12.14.
	
	//2012.10.11.  here just default the Addresses
	if (RT_Name == 'New_Professional_at_Exisiting_Workplace')
	{
		HelperObj.setWKP(trigger.new[0].Organisation_Account__c);  //2012.12.14.
		
		if (HelperObj.GetAdresses(trigger.new[0],true) == false)
		{
			trigger.new[0].adderror(HelperObj.errorMsg);   
			return;
		}
		
		if (HelperObj.PopulateWKPFields(trigger.new[0]) == false)   
		{   
			trigger.new[0].adderror(HelperObj.errorMsg);   
			return;			
		}		
	}
	
	if (RT_Name == 'Existing_Professional_at_New_Workplace')	
	{
		HelperObj.SetPerson(trigger.new[0].Professional__c); 
		HelperObj.PopulatePersonFields(trigger.new[0], RT_Name);  
	}
	                
	//in case of HIERARCHY   Default some values if missing
	if (RT_Name == 'Hierarchy')
	{	
		HelperObj.SetPerson(trigger.new[0].Professional__c);
		HelperObj.setWKP(trigger.new[0].Organisation_Account__c);
		
		//For Update We must be sure the IND and WKP are related *****************************
		if (trigger.new[0].Change_Type__c == 'Update' || trigger.new[0].Change_Type__c == 'Delete')
		{

		if(HelperObj.checkParentChild(trigger.new[0],false) == false)
			{
			trigger.new[0].Organisation_Account__c.addError(HelperObj.errorMsg);
		    return;			
			}                              
		}  
		//For Update We must be sure the IND and WKP are related *****************************		
		
		/*************************************************************************************************/
		if (trigger.new[0].Change_Type__c == 'Create')
		{
		//2012.12.14.  chec if the Parent/child  are not already related	
		if(HelperObj.checkParentChild(trigger.new[0],true) == false)
			{
			trigger.new[0].Organisation_Account__c.addError(HelperObj.errorMsg);
		    return;			
			}		
		}
		/*************************************************************************************************/

		//check its Organisation account. Get the workplace_class
        HelperObj.PopulateWKPFields(trigger.new[0]);
			
        HelperObj.PopulatePersonFields(trigger.new[0], RT_Name);//Collect Professional Account related fields ***********	  
		
	    /************************* Collect Primary Address Info **************************/
		if (HelperObj.GetAdresses(trigger.new[0],true) == false)
		{
			trigger.new[0].adderror(HelperObj.errorMsg);   
			return;
		} 					           
	    /************************* Collect Primary Address Info **************************/	    
	            	
		return;
	}//end HIERARCHY RecordType
	

	if (RT_Name == 'Professional_Update_Delete')
	{
		HelperObj.SetPerson(trigger.new[0].Professional__c);
		HelperObj.PopulatePersonFields(trigger.new[0],RT_Name);
		if(HelperObj.GetPrimaryParentData(trigger.new[0], RT_Name) == false)
		{
			trigger.new[0].adderror(HelperObj.errorMsg);   
			return;			
		}
		
		HelperObj.setWKP(trigger.new[0].Organisation_Account__c);
		if (HelperObj.GetAdresses(trigger.new[0],true) == false)
		{
			trigger.new[0].adderror(HelperObj.errorMsg);   
			return;
		}
		
		if (HelperObj.PopulateWKPFields(trigger.new[0]) == false)
		{   
			trigger.new[0].adderror(HelperObj.errorMsg);   
			return;			
		}
					
	}
	
	
	//Record Type is WORKPLACE 
    if (RT_Name == 'Workplaces')
	{
		if (trigger.new[0].Change_Type__c <> 'Create')
		{//for UPDATE/DELETE default some Data as : 
			
		if (trigger.new[0].Organisation_Account__c != NULL)			
			{	
			HelperObj.setWKP(trigger.new[0].Organisation_Account__c);

			HelperObj.PopulateWKPFields(trigger.new[0]);
	
  
	        /************************* Collect Primary Address Info ****************************/
			if (HelperObj.GetAdresses(trigger.new[0],false) == false)
			{
				trigger.new[0].adderror(HelperObj.errorMsg);   
				return;
			}						   
	        /************************* Collect Primary Address Info ****************************/	                
	        
			} //END ELSE Org Account == NULL     	
		}
	}//end recordType  WORKPLACE
}//end of trigger