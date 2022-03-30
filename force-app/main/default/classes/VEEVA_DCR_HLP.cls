/**************************************
Helper class to default the DCR fields.
**************************************/
public with sharing class VEEVA_DCR_HLP 
{

public String errorMsg {get; set;}
ID PersonAccount = NULL;
ID WKP_Account = NULL;

public void SetPerson(ID theID)
{
	this.PersonAccount = theID;   
}

public void setWKP(ID theID)
{
	this.WKP_Account = theID;
}

public VEEVA_DCR_HLP()
{
	
}

/***********************************************************************

***********************************************************************/
public boolean GetAdresses(V2OK_Data_Change_Request__c DCR, Boolean TDF)
{
	  
	Address_vod__c[] addr = [Select ID, City_vod__c,Zip_vod__c,	                        
	                         Name,Country_vod__c 
	                         from Address_vod__c
	                         where primary_vod__c = true
	                         and Account_vod__c = :this.WKP_Account
	                        ];
	                        
	if (addr.size() == 0)
	{
		this.errorMsg = 'Missing primary address';
		return false;
	}
	
	if ( 
	    addr[0].Zip_vod__c == NULL ||
	    addr[0].Country_vod__c == NULL || 
	    addr[0].City_vod__c == NULL || addr[0].Name == NULL)
	{
		this.errorMsg = 'Address City/Country/zip/address Line  is missing. zip=' + addr[0].Zip_vod__c + '/Country=' + addr[0].Country_vod__c + '/City='+addr[0].City_vod__c + '/Street='+addr[0].Name;
		return false;
	}
	
	if (TDF == true)
	{
	DCR.Address__c = addr[0].id;
	DCR.Country__c = addr[0].Country_vod__c;
	DCR.City_vod__c = addr[0].City_vod__c;
	
	DCR.Zip_vod__c = addr[0].Zip_vod__c;
	DCR.New_Address_Line_1__c = addr[0].Name;
	}
	else
	{
	if(DCR.Country__c == NULL)
	   DCR.Country__c = addr[0].Country_vod__c;
	   
	if(DCR.City_vod__c  == NULL)
	   DCR.City_vod__c  = addr[0].City_vod__c;  	
	   	   

	if(DCR.Zip_vod__c == NULL)
	   DCR.Zip_vod__c = addr[0].Zip_vod__c;
	   
	if (DCR.New_Address_Line_1__c == NULL)
	   DCR.New_Address_Line_1__c = addr[0].Name;   
	}
	
	
	return true;                          
	
}

/********************************************************************************
get the role ffrom child account where IND/WKP belongs.
********************************************************************************/
public boolean checkParentChild(V2OK_Data_Change_Request__c DCR,boolean isCreate)
{
	Child_Account_vod__c[] CAs = [Select Id, OK_Role__c
	                              from Child_Account_vod__c
	                              where Child_Account_vod__c =:PersonAccount and 
	                              Parent_Account_vod__c = :WKP_Account    
	                             ];
	
	if (CAs.size() == 0 && isCreate == false)
	{
		this.errorMsg = 'No Parent/Child relationship for the selected Person Organisation';
		return false;
	}
	
	if(CAs.size() > 0 && isCreate == true)
	{
		this.errorMsg = 'the selected Person/Organisation are already related';
		return false;
	}
	
	if(isCreate == false)
	{   
		if(DCR.Role__c == NULL)
	       DCR.Role__c = CAs[0].OK_Role__c;      
	}
	
	
	return true;
}

/***********************************************************************************
Populate primary Parent  and Role
***********************************************************************************/
public Boolean GetPrimaryParentData(V2OK_Data_Change_Request__c DCR, String RT_Name)
{
	Child_Account_vod__c[] CAs = [Select Id, OK_Role__c, Parent_Account_vod__c
	                              from Child_Account_vod__c
	                              where Child_Account_vod__c =:PersonAccount 
	                              and (Primary_vod__c = 'Yes'   or Primary_vod__c = 'Sí' )   
	                             ];
	
	if (CAs.size() == 0)
	{
		this.errorMsg = 'The Selected account has no Primary Parent';
		return false;
	}
	
	DCR.Organisation_Account__c = CAs[0].Parent_Account_vod__c;	
	DCR.Role__c = CAs[0].OK_Role__c;   
		  
	return true;
}

/**********************************************************************************
If  RecordType is Hierarchy Or change Type Delete just Default
If RecordType is Professional  and cnage type is Update default
the missing fields
***********************************************************************************/
public boolean PopulatePersonFields(V2OK_Data_Change_Request__c DCR, String RT_Name)  
{

	Account[] Acc = [Select 
			         Specialty_1_vod__c, 
			         FirstName,
			         LastName,
			         isPersonAccount,    
			         PersonTitle,
			         Gender_vod__c,
			         Salutation
			         ,OK_ExternalID__c
					 from Account 
					 where ID = :PersonAccount
					 ];
						 	
						 	   
			if (DCR.Specialty_1_vod__c == NULL || DCR.Change_Type__c == 'Delete' || RT_Name == 'Hierarchy')
				DCR.Specialty_1_vod__c = Acc[0].Specialty_1_vod__c;
	 
			if (DCR.First_Name__c == NULL || DCR.Change_Type__c == 'Delete' || RT_Name == 'Hierarchy') 
				DCR.First_Name__c = Acc[0].FirstName;
		  
			if (DCR.Last_Name__c == NULL || DCR.Change_Type__c == 'Delete' || RT_Name == 'Hierarchy')
				DCR.Last_Name__c = Acc[0].LastName;	
				  
		    //some customer use Gender. depends on Individual load mapping		    			
		    if (DCR.Gender__c == NULL || DCR.Change_Type__c == 'Delete' || RT_Name == 'Hierarchy') 
		        DCR.Gender__c = Acc[0].Salutation;  
		        
		    //if (DCR.Individual_Class__c == NULL || DCR.Change_Type__c != 'Create' || RT_Name == 'Hierarchy')
		    //   DCR.Individual_Class__c = Acc[0].OK_Account_Class__c;   
	
	
	return true;
}

/****************************************************************
If change type is Delete  just Default
If change type is Update default the missing fields 
****************************************************************/
public boolean PopulateWKPFields(V2OK_Data_Change_Request__c DCR)
{
	
	Account[]  OrgAcc = [Select OK_Account_Class__c,Name,Phone
						,Specialty_1_vod__c
						,RecordType.Name
						,isPersonAccount 
						,OK_ExternalID__c 
			            from Account 
			            where Id =:WKP_Account
			            ];	
			            
	if (OrgAcc[0].OK_ExternalID__c == NULL)
	{
	this.errorMsg = 'Missing WKP OneKey ID.  Request denied  to avoid rejection!';
	return false;				
	}
	
	DCR.Workplace_Class__c = OrgAcc[0].OK_Account_Class__c; 

	//if user left epty fill it.                    
	if (DCR.New_Account_Name__c == NULL || DCR.Change_Type__c == 'Delete')
		DCR.New_Account_Name__c = OrgAcc[0].Name;
			 
	if (DCR.Phone__c == NULL || DCR.Change_Type__c == 'Delete')
		DCR.Phone__c = OrgAcc[0].Phone;
		    	
	if (DCR.Workplace_Specialty__c == NULL || DCR.Change_Type__c == 'Delete')
		DCR.Workplace_Specialty__c = OrgAcc[0].Specialty_1_vod__c;			
	
	return true;
}

public boolean GetWorkplaceClass(V2OK_Data_Change_Request__c DCR)
{

		    //get the WKP class
		    Account[]  OrgAc = [Select OK_Account_Class__c  
		                        ,OK_ExternalID__c
		                        from Account  
		                        where Id =:WKP_Account];	
		    

		    if(OrgAc[0].OK_ExternalID__c == NULL)
		    {
	      	this.errorMsg = 'OneKey ID missing for Organisation. Request  denied to avoid rejection!';
	 	  	return false;		    	
		    }

		                        
		    DCR.Workplace_Class__c = OrgAc[0].OK_Account_Class__c;	
		    if (DCR.Workplace_Class__c == NULL)
		    {
	      	this.errorMsg = 'Workplace class missing for Organisation. Request  denied to avoid rejection!';
	 	  	return false;			    	
		    }
		     
		    return true;
	
}

}