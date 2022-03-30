/************************************************************************************************
Cegedim migt send  WKPs  without names.  TRhis is not accepted i veeva.
during data load  we are loading  a dummy name.  this dummy name  is corrected here
************************************************************************************************/
global with sharing class VEEVA_BATCH_Update_DummyWKP_Name implements Database.Batchable<SObject>
{
 private final Id jobId;
 private final Datetime lastRunTime;
 
 private String testOnly;
 	
/***************************************

***************************************/
global VEEVA_BATCH_Update_DummyWKP_Name()    
{
	    
}	

 
/***********************************************************************
Constructor  called from the BATCH_UTILS 
***********************************************************************/
public VEEVA_BATCH_Update_DummyWKP_Name(Id JobId,Datetime lastRunTime) 
{
    this();
    this.jobId = JobId;
    this.lastRunTime = lastRunTime;
      
    Data_Connect_Setting__c dcSettings = Data_Connect_Setting__c.getInstance('TestBatchsize');
    testOnly = dcSettings.Value__c;    
}

/***************************************************************
Return all addresses where Person Accounts has inherited Ext.ID
***************************************************************/
global Database.QueryLocator start(Database.BatchableContext BC)
	{
    //to reduce the number of records to process we can add filter for Dumy Name
    String selStmt = 'Select Account_vod__c, Account_vod__r.Name, Name  from Address_vod__c where  Primary_vod__c = true and Account_vod__r.isPersonAccount = false and Account_vod__r.Name = \'DUMMY_WKP_NAME\' order by Account_vod__c  Limit 50000000  ';  //2012.07.18.  Remove Limit 50000000    
    system.Debug('SQLU: ' + selStmt);
    
    return Database.getQueryLocator(selStmt);	 
	}


/*********************************************************************

*********************************************************************/
global void execute(Database.BatchableContext BC, List<sObject> batch)
{
	
	List<Address_vod__c> DWKPAs = (List<Address_vod__c>) batch;
	List<Account> Acctoupdate = new List<Account>();
	
	for (Address_vod__c addr :DWKPAs)
	{
		if (addr.Account_vod__r.Name == 'DUMMY_WKP_NAME') 
		{
		addr.Account_vod__r.Name = 'Private Practice: ' + addr.Name;
		Acctoupdate.add(addr.Account_vod__r);
		//CSABA 2012.08.27. addr.Account_vod__r.Workplace_LongName__c = 'Private Practice: ' + addr.Name;
		}
		else
		{
		//CSABA 2012.08.27. addr.Account_vod__r.Workplace_LongName__c = addr.Account_vod__r.Name + '  ' + addr.Name;	
		}
		
			
		
	}
	
	if (Acctoupdate.size() >  0)
		update(Acctoupdate);	

	
}




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