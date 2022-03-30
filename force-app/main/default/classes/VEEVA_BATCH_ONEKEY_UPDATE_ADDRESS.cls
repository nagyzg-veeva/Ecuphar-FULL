/****************************************************************************************************
This class  iterates through  the records  in the staging obj OK_STAGE_ADDRESS_INT__c  and calculates
the addresses  of the workplaces
Class  needs change.  Different customers  might need different  Address fileds  to integrate. 
Also  the OneKey  ExternalID  fileds  might be different  form customer to customer.   
****************************************************************************************************/
global without sharing class VEEVA_BATCH_ONEKEY_UPDATE_ADDRESS implements Database.Batchable<SObject> 
{
      
 private Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
 private static String constSELECT = 'SELECT ';
 
 private final Id jobId;
 private final Datetime lastRunTime;
 
 private final Integer TestBatchsize;   
 
    
    public VEEVA_BATCH_ONEKEY_UPDATE_ADDRESS()     
    {
   
    }
    
    public VEEVA_BATCH_ONEKEY_UPDATE_ADDRESS(Id JobId,Datetime lastRunTime) 
    {
       this();
       this.jobId = JobId;
       this.lastRunTime = lastRunTime;
       
        Data_Connect_Setting__c dcSettings = Data_Connect_Setting__c.getInstance('TestBatchsize');
        TestBatchsize = Integer.valueOf(dcSettings.Value__c);        
       
       System.Debug('CONSTRUCTOR BATCH VEEVA_BATCH_ONEKEY_UPDATE_ADDRESS');   
     
    }
    
      
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
     System.Debug('START BATCH VEEVA_BATCH_ONEKEY_UPDATE_ADDRESS');	//2012.02.25.
   
      String selStmt=' ';
      String sAddressStage = 'OK_STAGE_ADDRESS__c';
      String sAddressStageRel = 'OK_STAGE_ADDRESS__r';
      String sAddressRel = 'OK_STAGE_ADDRESS_INT__c';
    // Create base query
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
       
      //Complete SOQL
      //Remove the last comma
      selStmt = constSELECT + selStmt + 'OK_Process_Code__c,External_Id__c, OK_Stage_Workplace__r.Home__c,OK_Stage_Workplace__c, OK_Stage_Workplace__r.Workplace_External_Id__c, OK_Stage_Workplace__r.Workplace_Name__c ';
      selStmt = selStmt + ', OK_Stage_Workplace__r.External_Id__c, OK_Stage_Workplace__r.Individual_Account__c, OK_Stage_Workplace__r.Individual_Account__r.External_ID_vod__c, Primary__c,Billing__c,Mailing__c,Business__c ,OK_End_Date__c ';   //CSABA 20121.02.09  ,added OK_End_Date__c

      //CSABA 2012.09.20.  selStmt = selStmt + 'FROM  ' + sAddressRel + ' where LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') + '  ORDER BY OK_Process_Code__c ASC Limit 10 ';  //2012.07.18.  50000000

      selStmt = selStmt + 'FROM  ' + sAddressRel + ' where LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') + ' OR OK_STAGE_ADDRESS__r.LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') + '  ORDER BY OK_Process_Code__c ASC  ';        
      selstmt = selstmt + ' Limit ' + TestBatchsize + ' ';   
            
      System.Debug('SQLU: ' + selStmt);  //2012.02.25.  
      
 
    return Database.getQueryLocator(selStmt); 
  }
  
  
    global void execute(Database.BatchableContext BC, List<sObject> batch) 
    {  
      
    	 
       //Build a list based on the SQL from the previous method	   
       List<OK_STAGE_ADDRESS_INT__c> addressStageRecords = (List<OK_STAGE_ADDRESS_INT__c>) batch;
       
       System.Debug('EXECUTE BATCH VEEVA_BATCH_ONEKEY_UPDATE_ADDRESS bsize = ' + addressStageRecords.size());	
       
       
       
       List<Address_vod__c> addressRecs = new List<Address_vod__c>(); //Addresses to Upsert later.
       String AccountExtId;
       //Get the list of cegedim address Id's in the table
     
       for(OK_STAGE_ADDRESS_INT__c addressStageRecord : addressStageRecords)
       {       
            boolean bContinue = true;
            boolean isHome = false;   //CSABA 2012.05.07.  we ignore this filed.  AL WKPS  are treathed in the same way.
                       
            if(addressStageRecord.OK_Stage_Workplace__r.Home__c == TRUE &&  addressStageRecord.OK_Stage_Workplace__r.Individual_Account__c != null)
            {   //code never reach this point because Cegedim WorkPlace file does not contain Individual Account. We not even map this 
                AccountExtId = (String)addressStageRecord.OK_Stage_Workplace__r.Individual_Account__r.External_ID_vod__c; //
                isHome =  true;          
            }  
            else if(addressStageRecord.OK_Stage_Workplace__r.Workplace_External_Id__c != null 
                    //2012.10.21. && addressStageRecord.OK_Stage_Workplace__r.Workplace_Name__c != null 
                   )
            {   //2012.05.07.  since there will be no more EMPTY NAME   code always goes here  
                AccountExtId = (String) addressStageRecord.OK_Stage_Workplace__r.Workplace_External_Id__c; 
                System.Debug('ACCOUNT EXT ID= ' + AccountExtId);
            }
            else
            {                     
                bContinue = false; //Skip record no WKP Ext Id  or no Name.  2012.05.07.  NEVER REACH THIS part
                System.Debug('SKIP TRUE');
            }
        
        
            if(bContinue)
            {
            	System.Debug('Create Address record for: ' + addressStageRecord.OK_STAGE_ADDRESS__r.Name);  
                //Create the association to the Account

                Account acct = new Account(OK_ExternalID__c = AccountExtId);  //EXTERNAL ID NAME TO BE CHECKED. TAKE CARE TO USE THAT ExternalId  which holds  the OneKey ID  customer depenmdent 
                
                                        

                Address_vod__c address = new Address_vod__c(Name = addressStageRecord.OK_STAGE_ADDRESS__r.Name,
                                                            //Brick_vod__c = addressStageRecord.OK_STAGE_ADDRESS__r.Brick_vod__c, 
                                                            City_vod__c = addressStageRecord.OK_STAGE_ADDRESS__r.City_vod__c,                                                            
                                                            Country_vod__c = addressStageRecord.OK_STAGE_ADDRESS__r.Country_vod__c,
                                                            Zip_vod__c = addressStageRecord.OK_STAGE_ADDRESS__r.Zip_vod__c,
                                                            State_vod__c = addressStageRecord.OK_STAGE_ADDRESS__r.State_vod__c,   
                                                            RecordTypeId = addressStageRecord.OK_STAGE_ADDRESS__r.RecordTypeId__c, 
                                                            Account_vod__r = acct,
                                                            Primary_vod__c = addressStageRecord.Primary__c, 
                                                            OK_Process_Code__c = addressStageRecord.OK_End_Date__c == 'Active' ? addressStageRecord.OK_Process_Code__c : 'D',  //To clarify
                                                            Home_vod__c = isHome
                                                            ,OK_Integrationtime__c = system.now()    
                                                            );      
                                                            
                    //ADD HERE CODE  TO HANDLE DIFFEWRENT  ADDRESS TYPES(billing/Mailing/secondary/...).  CUSTOMER DEPENDENT 
                    address.Billing_vod__c = addressStageRecord.Billing__c;
                    address.Mailing_vod__c = addressStageRecord.Mailing__c;
                    address.Business_vod__c = addressStageRecord.Business__c;
                    
                    
                    if (addressStageRecord.Primary__c == false && address.OK_Process_Code__c <> 'D')
                    {
                    address.OK_Process_Code__c = 'D0';	 
                    }                                          
                    
                    //ADD HERE CODE  TO HANDLE DIFFERENT  ADDRESS TYPES(billing/Mailing/secondary/...).  CUSTOMER DEPENDENT  

                    System.Debug('Create Address: NAME: ' + address.Name + ' Primary: ' + address.Primary_vod__c);                              
                    
                     
                    //Calculate EXTERNAL ID.  Take  care that different  customers  might  
                    //use different  naming  convention for ExtID (ACT_CORE_OneKey_Id__c)   
                                         
                    //Split the External Id
                    String AddrRelExtId = (String) addressStageRecord.External_Id__c;
                    
                    if(AddrRelExtId != null && AddrRelExtId.contains('STAGE'))
                    {
                        //Split the records with the word Stage
                        List<String> extId = AddrRelExtId.split('_');
                        
                        address.OK_ExternalID__c = extId[extId.size()-1];  
                        address.OK_ExternalID__c = AddrRelExtId.substring(6);
                    }
                    else
                    {
                        address.OK_ExternalID__c = AddrRelExtId;         
                    }                                           
                    addressRecs.add(address);     
            }                           
       }
       
        //if we have items in the list do an upsert
        if(!addressRecs.isEmpty())
        {
        	   System.Debug('UPSERT Address_vod__c');
        	
                
                Database.Upsertresult[] results = Database.upsert(addressRecs,Address_vod__c.OK_ExternalID__c,false);  //TAKE CARE TO USE THAT EXTERNAL ID WHICH HOLDS  THE ONEKEY IDs
                
                String ErrorMessage = '';
                if(results != null)
                {    
                    for(Database.Upsertresult result : results)
                    {
                        if(!result.isSuccess())
                        {
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
                
    }
    
    /***********************************************
    set status to completed  then send an email then
    trigger the next JOB.
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