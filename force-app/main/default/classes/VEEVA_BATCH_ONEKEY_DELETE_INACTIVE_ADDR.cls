global without sharing class VEEVA_BATCH_ONEKEY_DELETE_INACTIVE_ADDR implements Database.Batchable<SObject>
{
  
 private Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
 private final Id jobId;
 private final Datetime lastRunTime;
 
  private final Integer TestBatchsize; 
 

    
    public VEEVA_BATCH_ONEKEY_DELETE_INACTIVE_ADDR() 
    {
       
    
    }
    public VEEVA_BATCH_ONEKEY_DELETE_INACTIVE_ADDR(Id JobId,Datetime lastRunTime) 
    {
       this();
       this.jobId = JobId;
       this.lastRunTime = lastRunTime;
       
       Data_Connect_Setting__c dcSettings = Data_Connect_Setting__c.getInstance('TestBatchsize');
       TestBatchsize = Integer.valueOf(dcSettings.Value__c);         
    }


    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    String selStmt = '';
    
    selStmt = 'Select ID,OK_PROCESS_CODE__c from Address_vod__c where OK_Process_Code__c like \'D%\' ';
    selStmt = selStmt + ' or Account_vod__r.OK_Status__c = \'STA.9\' ';  //2013.03.02.
    selstmt = selstmt + ' Limit ' + TestBatchsize + ' ';
    //selstmt = selstmt + ' Limit 0 ';    
    
    system.Debug('SQLU: ' + selstmt);
    
    return Database.getQueryLocator(selStmt);        	
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> batch) 
    {
       List<Address_vod__c> addressRecords = (List<Address_vod__c>) batch;
       System.Debug('Addr batch size = ' + batch.size());
      
       
       List<Address_vod__c> addressToDel = new List<Address_vod__c> ();

      Data_Connect_Setting__c dcSettings = Data_Connect_Setting__c.getInstance('OnlyPrimaryAddress');
      String OnlyPrimaryAddress = dcSettings.Value__c;   	
      system.Debug('OnlyPrimaryAddress = ' + OnlyPrimaryAddress); 
       
       for(Address_vod__c address : addressRecords)
         {
       	    if (OnlyPrimaryAddress == 'True')
       	    {
             if(address.OK_PROCESS_CODE__C == 'D' ||      //INACTIVR Addresses of Individuals
                address.OK_PROCESS_CODE__C == 'D1' ||     //non-primary parent primary addr
                address.OK_PROCESS_CODE__C == 'D2' ||     //non primary address of non-primary parent             
                address.OK_PROCESS_CODE__C == 'D3' ||     //non-primary parent secondary address
                address.OK_PROCESS_CODE__C == 'D0' ||     //Non-primary addresses of WKP 
                address.OK_PROCESS_CODE__C == 'D11' ||    //non-primary parent primary addr
                address.OK_PROCESS_CODE__C == 'D22' ||    //non primary address of non-primary parent
                address.OK_PROCESS_CODE__C == 'D33' ||    //non-primary parent secondary address
                address.OK_PROCESS_CODE__C == 'D20' ||      //IND addresses from INACTIVE Addresses of Workplaces 
                address.OK_PROCESS_CODE__C == 'D10'
                )           
                    addressToDel.add(address);     
                    integer iu = 0;          
       	    }
            else
            {
            if(address.OK_PROCESS_CODE__C == 'D' ||       //INACTIVE ADDRESSES
               address.OK_PROCESS_CODE__C == 'D20' ||       //IND addresses from INACTIVE Addresses of Workplaces 
               address.OK_PROCESS_CODE__C == 'D10'
               )            
                    addressToDel.add(address); 
                     integer iw = 0;             	     	    	
            }            	
            	
         }//end for loop  
              
        if(!addressToDel.isEmpty())
        {
  
         Database.DeleteResult[] delresults = Database.delete(addressToDel);
         String delErrorMessage = 'AddressToDelete:';
         if(delresults != null)
         {          
            for(Database.DeleteResult result : delresults)
            {
             if(!result.isSuccess())
                {
                 Database.Error[] errs = result.getErrors();
                 for(Database.Error err: errs)
                     {
                     delErrorMessage = delErrorMessage + err.getStatusCode() + ' : ' + err.getMessage() + '\r';
                     }      
                 }
                 else  //CSABA 2012.03.23.  clear the err str otherwise it will isert into Batch error object.
                    delErrorMessage = '';
            }
                    
          if(delErrorMessage.length() > 1)   
               setErrorMessage(jobId, delErrorMessage);    
          }
        }
    }  
  
    /*************************************************
    setting the job  as completed  will generate an 
    email  and a new job. 
    *************************************************/
    global void finish(Database.BatchableContext BC)
    {
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