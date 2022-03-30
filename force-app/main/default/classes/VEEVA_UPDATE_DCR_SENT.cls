/*************************************************************************************
Update Request_Sent__c field in the DCR object.  Next time when DCR DL++  jobs starts
the already sent records are ignored.
*************************************************************************************/
global with sharing class VEEVA_UPDATE_DCR_SENT implements Database.Batchable<SObject>
{
 
 
 private final Id jobId;
 private final Datetime lastRunTime;	//not really needed
	
/*****************************
Empty constructor
*****************************/
global VEEVA_UPDATE_DCR_SENT()
{

}

/**********************************************************

**********************************************************/
public VEEVA_UPDATE_DCR_SENT(Id JobId,Datetime lastRunTime) 
{
       this();
       this.jobId = JobId;
       this.lastRunTime = lastRunTime;
}

/***************************************************************
Collect the record set
***************************************************************/
global Database.QueryLocator start(Database.BatchableContext BC)
{
	System.Debug('START method: start');
	 
	try
	{
	String selStmt = 'Select ID, Request_sent__c from V2OK_Data_Change_Request__c where Request_sent__c = false ';
	
	system.Debug('SQLU: ' + selStmt);	
	return Database.getQueryLocator(selStmt);
	
    }
	catch(Exception ex)
	{
	system.Debug('EXCEPTION OCCURED IN  Start: ' + ex.getMessage());
	return null;
	}
}

/*********************************************************************
Collect all non sent DCRs  and update them to sent.
*********************************************************************/
global void execute(Database.BatchableContext BC, List<sObject> batch)
{
	System.Debug('START method: Execute');
	try
	{
		    
	List<V2OK_Data_Change_Request__c> DCRs = (List<V2OK_Data_Change_Request__c>) batch;	  
	
	integer indexu = DCRs.size();
	
	system.debug('TOTAL UPDATE:  ' + indexu);
	
	for (integer i = 0; i < indexu; i++)
		{
			DCRs[i].Request_sent__c = true;
		}
	
	if (indexu > 0)	
       update DCRs;
		
	}
	catch(Exception ex)
	{
	//not sure try / catch  is neede. Let  salewsforce  catch them??  	
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