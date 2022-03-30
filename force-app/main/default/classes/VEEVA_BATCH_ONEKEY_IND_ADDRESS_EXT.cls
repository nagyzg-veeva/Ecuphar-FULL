/*********************************************************************************************************
Class calculate the address of an INDIVIDUAL for those without recent ACTIVITY  **************************
*********************************************************************************************************/
global without sharing class VEEVA_BATCH_ONEKEY_IND_ADDRESS_EXT implements Database.Batchable<SObject> 
{
    private Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();   
    private static String constSELECT = 'SELECT ';
 
    private final Id jobId;
    private final Datetime lastRunTime; 
    
    private final Integer TestBatchsize;  
    
    /********** Empty constructor ************/
    public VEEVA_BATCH_ONEKEY_IND_ADDRESS_EXT() 
    {
    
      
    }
    
    /************************** Constructor *******************************/
    public VEEVA_BATCH_ONEKEY_IND_ADDRESS_EXT(Id JobId,Datetime lastRunTime) 
    {
       this();
       this.jobId = JobId;
       this.lastRunTime = lastRunTime;
       
       System.Debug('CONSTRUCTOR BATCH VEEVA_BATCH_ONEKEY_UPDATE_IND_ADDRESS'); 
       
        Data_Connect_Setting__c dcSettings = Data_Connect_Setting__c.getInstance('TestBatchsize');
        TestBatchsize = Integer.valueOf(dcSettings.Value__c);       
    }
      
    
    /***************************************************************
    
    ***************************************************************/  
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {	
     
    String selStmt=' ';
    String sAddressStage = 'OK_STAGE_ADDRESS__c';
    String sAddressStageRel = 'OK_STAGE_ADDRESS__r';
    String sAddressRel = 'OK_STAGE_ADDRESS_INT__c';
    
    /************************** Create base query *********************************************************/
    Map <String, Schema.SObjectField> fieldMap = schemaMap.get(sAddressStage).getDescribe().fields.getMap();
    Map <String,String> StageFieldMap = new Map <String,String>();
   
    for(Schema.SObjectField sfield : fieldMap.Values())
    {
            schema.describefieldresult dfield = sfield.getDescribe();
            if(!dfield.getName().equals('null') || dfield.getName() != null)
            {
                selStmt = selStmt + sAddressStageRel + '.' + dfield.getName() + ','; 
            }         
    }
    /************************** Create base query *********************************************************/
             
    //Complete SOQL
    //Remove the last comma
    selStmt = constSELECT + selStmt + 'OK_Process_Code__c,External_Id__c, OK_Stage_Workplace__r.Home__c,OK_Stage_Workplace__c, OK_Stage_Workplace__r.Workplace_External_Id__c, OK_Stage_Workplace__r.Workplace_Name__c ';
    selStmt = selStmt + ', OK_Stage_Workplace__r.External_Id__c, OK_Stage_Workplace__r.Individual_Account__c, OK_Stage_Workplace__r.Individual_Account__r.External_ID_vod__c, Primary__c,Billing__c,Mailing__c,Business__c,OK_End_Date__c ';   //CSABA 20121.02.09  ,added OK_End_Date__c

    //CSABA 2012.09.20.  selStmt = selStmt + 'FROM  ' + sAddressRel + ' where LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') + '  ORDER BY OK_Process_Code__c ASC Limit 10 ';  //2012.07.18.  50000000
    
    //selStmt = selStmt + 'FROM  ' + sAddressRel + ' where LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') + ' OR OK_STAGE_ADDRESS__r.LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') + '  ORDER BY OK_Process_Code__c ASC Limit 50000000 ';
    selStmt = selStmt + 'FROM  ' + sAddressRel + ' where OK_STAGE_ADDRESS__r.LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') + '  ORDER BY OK_Process_Code__c ASC  ';
    selStmt = selStmt + ' Limit ' + TestBatchsize + ' ';  
    //selStmt = selStmt + ' Limit 0 ';      
                
    System.Debug('SQLU: ' + selStmt);  
      
    return Database.getQueryLocator(selStmt);   
  }
 
 
   /*********************************************************************
   Execute main logic  of the batch.  Collect all WKP IDs from the batch.
   Collect all OLD ctivities  for these WKPs.  
   *********************************************************************/  
   global void execute(Database.BatchableContext BC, List<sObject> batch) 
   {

      List<OK_STAGE_ADDRESS_INT__c> addressStageRecords = (List<OK_STAGE_ADDRESS_INT__c>) batch;
      
      system.debug('BatchSize = ' + addressStageRecords.size());
      
    
      
      Set<Id> StageWkpIds = new Set<Id>();     	
									 
	  for (OK_STAGE_ADDRESS_INT__c WARu : addressStageRecords)
	  {
	  StageWkpIds.add(WARu.OK_Stage_Workplace__c);	
	  }	
	  							 
							 		 
      OK_Stage_Activity__c[] activityStageRecords = [Select Stage_Workplace__r.External_Id__c, OK_Process_Code__c,External_Id__c,Stage_Workplace__c,
                                                     Do_Not_Mail__c, Individual_External_Id__c, Mailing__c, Primary__c ,Active_Status__c, ACT_CORE_OK_Activity_ID__c,OK_Act_Phone__c,OK_Act_Fax__c 
                                                     FROM  OK_Stage_Activity__c
				                                     where 
				                                     LastModifiedDate < :lastRunTime  //to exclude the ones already processed
				                                     and
				                                     Stage_Workplace__c in: StageWkpIds
				                                     and Active_Status__c != 'Invalid'
				                                     Order by Individual_External_Id__c, Primary__c
				                                    ]; 
 	
   	   system.Debug('Batch execute 1: activityStageRecords size = ' + activityStageRecords.size());
   	   
       //2013.03.09.  Must detect Existing child account  in order to Rebuild Mario's  childAccount lookup on Addresses
       set<String> SetStageAct_ExtID = new Set<String>(); 
       set<String> setExistingCA_ID = new Set<String>(); 
       Map<String,ID> MapExistingCAs = new Map<String,ID>(); 

       //Will need both the individual id and wkpid
       for(OK_Stage_Activity__c anAct :activityStageRecords)
       {            
            String CA_extID = anAct.External_Id__c.split('_')[1];  //2013.03.09.            
            SetStageAct_ExtID.add(CA_extID);                       //2013.03.09.
       } 

       /************ collect the Existing child Accoccunts corresponding  to Stage Act records 2013.03.09. ***********
       List<Child_Account_vod__c> Active_CAs = [Select id,ACT_CORE_OK_Id__c from Child_Account_vod__c 
                                                where ACT_CORE_OK_Id__c in: SetStageAct_ExtID];   
       for(Child_Account_vod__c CA :Active_CAs)
       {
       	setExistingCA_ID.add(CA.ACT_CORE_OK_Id__c);   
       	MapExistingCAs.put(CA.ACT_CORE_OK_Id__c,CA.id);
       }    
       system.Debug('CSABA: Map size = ' + MapExistingCAs.size());                                     
       ************ collect the Existing child Accoccunts corresponding  to Stage Act records 2013.03.09. ***********/                         
       //2013.03.09.  Must detect Existing child account  in order to Rebuild Mario's  childAccount lookup on Addresses    	   
       
       List<Address_vod__c> addressRecs = new List<Address_vod__c>();  //Address to UPSERTS
       Map<String,Address_vod__c> mapAddress = new Map<String,Address_vod__c>();
                       
       //iterate  through  all ACTIVITY  records  from the above list.
       for(OK_Stage_Activity__c actvStageRecord : activityStageRecords)
       {
            //For each record, pull out the addresses
            if(actvStageRecord.Individual_External_Id__c != null)
            {
            	  system.Debug('Batch execute 4');
            	
                  for(OK_STAGE_ADDRESS_INT__c aStageAddressRel : addressStageRecords)
                  {
                  	
                  	   system.Debug('Batch execute 5');
                       if(aStageAddressRel.OK_Stage_Workplace__c ==  actvStageRecord.Stage_Workplace__c)
                       {
                       	system.Debug('Batch execute 6');
                       	
                        Account acct = new Account(OK_ExternalID__c = actvStageRecord.Individual_External_Id__c);  //TAKE CARE OF THE ExternalId  naming  convention. (here: ACT_CORE_OK_Id__c)

                        
                        //Find the list of addresses associated to the workplace
                        Address_vod__c address = new Address_vod__c(Name = aStageAddressRel.OK_STAGE_ADDRESS__r.Name,
                                                            Brick_vod__c = aStageAddressRel.OK_STAGE_ADDRESS__r.Brick_vod__c,                                                          
                                                            City_vod__c = aStageAddressRel.OK_STAGE_ADDRESS__r.City_vod__c,
                                                            Country_vod__c = aStageAddressRel.OK_STAGE_ADDRESS__r.Country_vod__c,
                                                            Zip_vod__c = aStageAddressRel.OK_STAGE_ADDRESS__r.Zip_vod__c,   
                                                            State_vod__c = aStageAddressRel.OK_STAGE_ADDRESS__r.State_vod__c, 
                                                            //ACT_CORE_County__c = aStageAddressRel.OK_STAGE_ADDRESS__r.County__c,                                                     
                                                            RecordTypeId = aStageAddressRel.OK_STAGE_ADDRESS__r.RecordTypeId__c, 
                                                            Account_vod__r = acct,
                                                            //2013.02.08. Primary_vod__c = actvStageRecord.Primary__c,  //not true!!
                                                            OK_Integrationtime__c = system.now(),   
                                                            OK_ExternalID__c = aStageAddressRel.OK_STAGE_ADDRESS__r.External_ID_vod__c + actvStageRecord.Individual_External_Id__c,  //2012.07.21.                                      
                                                            OK_Process_Code__c =  actvStageRecord.Active_Status__c == 'Invalid' ?  'D10' : aStageAddressRel.OK_Process_Code__c  
                                                            );           
                                                                
     
                       address.Billing_vod__c = aStageAddressRel.Billing__c;
                       address.Mailing_vod__c = aStageAddressRel.Mailing__c;
                       address.Business_vod__c = aStageAddressRel.Business__c;
     
                       /**************************************************************/
                       //2012.09.15. NL speccific
                       address.Phone_vod__c = actvStageRecord.OK_Act_Phone__c;
                       address.Fax_vod__c = actvStageRecord.OK_Act_Fax__c;
                        
                       
                       //some  customers need  to create  only the primary addresses belonging  to INDIVIDUAL's primary parent!                  	                      
	                       if (actvStageRecord.Primary__c == false)
	                       {//non-primary parent
	                       	//2013.02.08. address.Primary_vod__c = false;
	                       	address.Primary_vod__c = false;             //non-primary parent
	                       	if (address.OK_Process_Code__c <> 'D10')
	                       	   address.OK_Process_Code__c = 'D11';  //will be delete later
	                       }
	                       else
	                       {//primary  parent
	                       	if (aStageAddressRel.Primary__c == true)
	                       	{
	                       	//2013.02.08. address.Primary_vod__c = true;	
	                       	address.Primary_vod__c = true;             //primary parent primary address
	                       	}
	                       	else
	                       	{
	                       	//2013.02.08.address.Primary_vod__c = false;
	                       	address.Primary_vod__c = false;            //primary parent  non-primary address
	                       	if (address.OK_Process_Code__c <> 'D10')
	                       	   address.OK_Process_Code__c = 'D22';
	                       	}
	                       }                     
                       //some  customer  need  to create  only the primary addresses belonging  to INDIVIDUAL's primary parent!
                       
                       
   						//2012.06.21.  Handle  here the situation where the WKP addresses  became INACTIVE
  						if (aStageAddressRel.OK_End_Date__c == 'Inactive')
  						{
  						address.OK_PROCESS_CODE__c = 'D20';	
  						}
  						//2012.06.21.  Handle  here the situation where the WKP addresses  became INACTIVE    
  						
  						//2012.09.21 *******************************************************
  						if (address.OK_PROCESS_CODE__c <> 'D10' && 
  						    address.OK_PROCESS_CODE__c <> 'D11' &&
  						    address.OK_PROCESS_CODE__c <> 'D22' &&
  						    address.OK_PROCESS_CODE__c <> 'D20'
  						    )
  						    {
  						    address.OK_PROCESS_CODE__c = address.OK_PROCESS_CODE__c  + '99';	
  						    }                    
                       //2012.09.21 *******************************************************
     
                        mapAddress.put(aStageAddressRel.OK_STAGE_ADDRESS__r.External_ID_vod__c + actvStageRecord.Individual_External_Id__c,address);
                           
                           
                       system.Debug('New ADDR: ' + address.Name + ' ProcessCODE: ' + address.OK_Process_Code__c + ' ActStatus: ' + actvStageRecord.Active_Status__c); 
                           
                              //I guess just to avoid to many upsertable addresses
                             if(mapAddress.size() > 9000)
                             {
                                //Loop Through to pull address
                                /**
                                for(String addrExternalId:mapAddress.keyset()){
                                     addressRecs.add(mapAddress.get(addrExternalId));
                                 } 
                                 */
                                 for(Address_vod__c myaddress:mapAddress.values())
                                 {
                                     addressRecs.add(myaddress);
                                 } 
                                
                                //Run the upsert
                                UpserResults(addressRecs);
                                //Reset the list
                                addressRecs = new List<Address_vod__c>();
                                mapAddress = new Map<String,Address_vod__c>();                         
                             }     
                       }
                  }  
            }
       }
       
        //Upsert the last batch
       if(!mapAddress.isEmpty())
       {
                 /**
                 for(String addrExternalId:mapAddress.keyset()){
                       addressRecs.add(mapAddress.get(addrExternalId));
                  } 
                  */
                  for(Address_vod__c myaddress:mapAddress.values())
                  {
                             addressRecs.add(myaddress);
                  }   
                 
                 UpserResults(addressRecs);         
        }        
   }
   
   
   /**********************************************************
   Upsert the addresses passes as parameter in the List obj.
   **********************************************************/
   private void UpserResults(List<Address_vod__c> addressRecs)
   {
       //Upsert Addr.  Identify the existing addresses based on the Address_vod__c.External_ID_vod__c  field.
       //TAKE CARE OF THE NAMING  CONVENTION OF THE EXTERNAL ID
       Database.Upsertresult[] results = Database.upsert(addressRecs,Address_vod__c.OK_ExternalID__c,false);  
       
  
                String ErrorMessage = '';
                if(results != null)
                {
                    
                    for(Database.Upsertresult result : results)
                    {
                        if(!result.isSuccess()){
                             Database.Error[] errs = result.getErrors();
                             for(Database.Error err: errs)
                             {
                                ErrorMessage = ErrorMessage + err.getStatusCode() + ' : ' + err.getMessage() + '\r';
                             }      
                        }
                    }   
                }
                
            if(ErrorMessage.length() > 1)
            {   
                 setErrorMessage(jobId, ErrorMessage);              
            }   
   }     
   
   
   /***********************************************
   
   ***********************************************/
   global void finish(Database.BatchableContext BC)
   {
          //VEEVA_BATCH_ONEKEY_BATCHUTILS.setCompleted(jobId,lastRunTime);
          setCompleted(jobId,lastRunTime);
   }   

/******************************* 2012.11.21. ********************************************/
/* Add this here from batchutil class  only  to avoid cross-refference deployment error */
   /*******************************************
    Updates the job status to STATUS_COMPLETED 
    and populates the end time with the current
    system date/time.
    This  function will initiate a trigger which
    will  kick of the next  job  later
    *******************************************/
    public static void setCompleted(Id jobId, DateTime LRT) 
    {
        if (jobId != null) 
        {
            List<V2OK_Batch_Job__c> jobs = [SELECT Id FROM V2OK_Batch_Job__c 
                                            WHERE Id = :jobId
                                            ];
            if (!jobs.isEmpty()) 
            {
                V2OK_Batch_Job__c job = jobs.get(0);
                job.Status__c = 'Completed';
                job.End_Time__c = Datetime.now();
                job.LastRunTime__c = LRT;   
                update job;
            }
        }
    }
    
     /***********************************************************
     insert a record  into a custom object:   Batch_Job_Error__c
     ***********************************************************/
     public static void setErrorMessage(Id jobId, String Message) 
     {
        if (jobId != null) 
        {
            //Create an error message  
                Batch_Job_Error__c jobError = new Batch_Job_Error__c();
                jobError.Error_Message__c = Message;
                jobError.Veeva_To_One_Key_Batch_Job__c = jobId;
                jobError.Date_Time__c = Datetime.now();
                insert jobError;        
        }
    }
/* Add this here from batchutil class  only  to avoid cross-refference deployment error */    
/******************************* 2012.11.21. ********************************************/   
}