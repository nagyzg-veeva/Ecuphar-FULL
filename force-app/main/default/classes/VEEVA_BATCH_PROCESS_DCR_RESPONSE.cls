/*************************************************************************************************
Batch job  collects  info  about the Validation Respnses  ans send email  to admin and to the
users who created  the Data change response
Functionality not needed by all customers!!
*************************************************************************************************/
global with sharing class VEEVA_BATCH_PROCESS_DCR_RESPONSE implements Database.Batchable<SObject>
{
	 
 private final Id jobId;
 private final Datetime lastRunTime;
 	
/***************************************

***************************************/
global VEEVA_BATCH_PROCESS_DCR_RESPONSE()      
{
	    
}	




/***********************************************************************
Constructor  called from the BATCH_UTILS 
***********************************************************************/
public VEEVA_BATCH_PROCESS_DCR_RESPONSE(Id JobId,Datetime lastRunTime) 
{
    this();
    this.jobId = JobId;
    this.lastRunTime = lastRunTime;
}

/***************************************************************
Return all addresses where Person Accounts has inherited Ext.ID
***************************************************************/
global Database.QueryLocator start(Database.BatchableContext BC)
{

    //2012.09.23. ORIGINAL String selStmt = 'Select RecordType.Name, Data_Request_Response__c, LastModifiedDate FROM V2OK_Data_Change_Request__c where Data_Request_Response__c != NULL and LastModifiedDate >=' + lastRunTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.\'000Z\'') +  ' order by LastModifiedDate asc';
    String selStmt = 'Select RecordType.Name, Data_Request_Response__c, LastModifiedDate FROM V2OK_Data_Change_Request__c where Data_Request_Response__c != NULL and LastModifiedDate >= today order by LastModifiedDate asc';

    system.Debug('SQLU: ' + selStmt);
    
    return Database.getQueryLocator(selStmt);	
}

/*********************************************************************
get only the LastModifiedDate from the Queryressult set.  
for the real data we use an aggregate query.  
*********************************************************************/
global void execute(Database.BatchableContext BC, List<sObject> batch)
{
	System.Debug('Start VEEVA_BATCH_PROCESS_DCR_RESPONSE  Execute()');
	
	//2012.09.18 Read  custom settings   AdminEmail  and SendDCRtoUser *************************************
	Data_Connect_Setting__c connectSettingsADMINEMAIL = Data_Connect_Setting__c.getInstance('AdminEmail');
    String AdminEmail = connectSettingsADMINEMAIL.Value__c;
    
	Data_Connect_Setting__c connectSettingsDCRtoUser = Data_Connect_Setting__c.getInstance('SendDCRtoUser');
    String emailtoUSer = connectSettingsDCRtoUser.Value__c;
	//2012.09.18 Read  custom settings   AdminEmail  and SendDCRtoUser ************************************* 	
	
	String MailBody = '';
	String AdminMailBody = '';
	
    List<V2OK_Data_Change_Request__c> DCRs = (List<V2OK_Data_Change_Request__c>) batch;	
    //just get the lastmodified Date
    Datetime responseDate = DCRs[0].LastModifiedDate;
     
    List<AggregateResult> ARs = [Select Count(ID) totalrecords,             
                                 RecordType.Name RTN, 
    							 Data_Request_Response__c DCRR,
    							 CreatedById USERU 
                                 FROM V2OK_Data_Change_Request__c 
                                 where Data_Request_Response__c != NULL 
                                 and LastModifiedDate >= :lastRunTime
                                 group by RecordType.Name , Data_Request_Response__c, CreatedById
                                 order by CreatedById, RecordType.Name
                                 ];
      
    System.Debug('Start VEEVA_BATCH_PROCESS_DCR_RESPONSE  Execute() for ' + ARs.size() + ' results.');
    
    //Iterate first through the ARs and collect the UserID
    List<ID> Users = new List<ID>();
    ID curUseru = null;
    ID prevUseru = null;
    for(AggregateResult theAR : ARs)
    {
    	curUseru = String.valueOf(theAR.get('USERU'));
    	System.Debug('Current USERU: ' + curUseru);
		if (prevUseru == NULL || curUseru != prevUseru)
		{
			Users.add(curUseru);
			
			prevUseru = curUseru;
		}
    }
    
    
     boolean skip = false;  //2012.09.18.  to send  admin mail only once !!!    
     for (ID theUser :Users) 
     {
     	 MailBody = '';
     	 
     	 ID curU = null;
     	      	 
	     for(AggregateResult theAR : ARs)
	     { 
	     	if (emailtoUSer == 'true')
	     	{
	     	curU = String.valueOf(theAR.get('USERU'));
	     	System.Debug('curU: ' + curU);
	     	if (theUser == curU)
	     		{
	     		System.Debug('MailBODY for User: ' + theUser);	
	     		MailBody = MailBody + '\r\n' +  String.format('{0}	Requests of type: 	{1}were : {2}',
	     	                                              new String[]{String.valueOf(theAR.get('totalrecords'))
	     		                                                       ,FormatValue(String.valueOf(theAR.get('RTN')))
	     		                                                       ,String.valueOf(theAR.get('DCRR'))
	     		                                                      }
	     		                                          );	     		
	     		}	     		
	     	}
	     	
           if(skip == true)
				continue;

	        //set the Body for ADMIN
     	    AdminMailBody = AdminMailBody + '\r\n' +  String.format('{0}	Requests of type: 	{1}were : {2}',
     	                                                            new String[]{String.valueOf(theAR.get('totalrecords'))
     		                                                                     ,FormatValue(String.valueOf(theAR.get('RTN')))
     		                                                                     ,String.valueOf(theAR.get('DCRR'))
     		                                                       }
     		                                            );	     		

	     } //end inner for. AR    	
	       
	 if (skip == false)
	 {
	 AdminMailBody = AdminMailBody + '\r\n' + '\r\n'   + '\r\n' +  'Please check Org for details  for responses received after: .' + responseDate;
     System.Debug('SENDING EMAIL TO ADMIN: ' + AdminEmail + '  BODY: ' + AdminMailBody);
	 }    
	 
	 skip = true;  //for thre next loop do not collect Admin data again	     
     
     //Send the email after each User
     if (MailBody != '' && emailtoUSer == 'true')  
     	{         
     	User u = [Select Username, Email, Id from User where Id = :theUser];
     	System.Debug('USERU: ' + u.UserName + '  BODY: ' + MailBody);
     	MailBody = MailBody + '\r\n' + '\r\n'   + '\r\n' +  'Please check Org for details  for responses received after: .' + responseDate;
     	//get the email address for the user.
     	VEEVA_BATCH_ONEKEY_BATCHUTILS.sendEmail(u.Email, MailBody);             	
     	}
	
     }//end User  for  loop
     //now send the mail to admin   
     System.Debug('USERU: CSABA.  BODY: ' + AdminMailBody);
     //always  send  email to ADMIN  and me
     VEEVA_BATCH_ONEKEY_BATCHUTILS.sendEmail(AdminEmail, AdminMailBody);     
     VEEVA_BATCH_ONEKEY_BATCHUTILS.sendEmail('Csaba.Matyas-Peter@veevasystems.com', AdminMailBody);  
	
}

/*************************************

*************************************/
global string  FormatValue(string val)
{
	while (val.length() < 25)
	{
		val = val + ' ';
	}
	
	return val;
	
}


/**********************************************

**********************************************/
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