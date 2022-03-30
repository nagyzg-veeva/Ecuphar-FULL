/*******************************************************************************************
 * This email service provides an interface to the OneKey Batch Process
 * Apex batch job. The job can be started by sending an email with a specific subject
 * and body to a specific service email adress.
 *
 * @author matt.yeoh@veevasystems.com
 * @version 2011-11-09 
 
 after a jobv is finished  an email is sent  with the info about  the Current  and Next  job
 This  email handler  class  process the info  and insert a new record into V2OK_Batch_Job__c  
 object.  This will kick of th new job
 FRAMEWORK CLASS.  Not supposed to change            
 *******************************************************************************************/  
global class VEEVA_BATCH_ONEKEY_INEMAIL_EXECUTE_JOBS implements Messaging.InboundEmailHandler   
{  
       
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env)
  {
     
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
 
        Data_Connect_Setting__c connectSettings = Data_Connect_Setting__c.getInstance('AdminProfile');   
        String ProfileName = connectSettings.Value__c;
        
        String fromemailAddress = email.fromAddress;
        String strSubject = email.subject;
        
        System.Debug('EMAILSERVICE  FROM: ' + fromemailAddress + '  PROFILE: ' + ProfileName);  //2012.02.25.
        
        //Verify that it was sent from a system administrators account
        List<User> listUser = [Select Id from User where email=:fromemailAddress AND profile.Name=:ProfileName];
        
        if(listUser.size() > 0)
        {
            //Kick off next job
            //parse subject
            String[] instr = strSubject.split(':');
            if(instr.size()> 0) 
            {         
                integer theIndex = 0;
                //CSABA 2012.03.01.  WARNING!!  In case of Sandbox  the email add the string "Sandbox:"  before our subject
                if (instr[0].toUpperCase() == 'SANDBOX' )
                {
                    theIndex = theIndex + 1;
                }
                 
                //Get the second part
                String nextBatchJob = instr[theIndex].trim();
                
                String NextBatchProcess = '';
                if(instr.size() > 2)
                {
                    NextBatchProcess = instr[theIndex + 1]; 
                }
                
                if(instr.size() == 2 && instr[0].toUpperCase() != 'SANDBOX')
                {
                    NextBatchProcess = instr[theIndex + 1]; 
                }
                
                
                
                System.Debug('EMAAIL SERVICE.  CREATE NEXT JOB: ' + nextBatchJob + ' NEXT PROCESS: ' + NextBatchProcess);
                 
                V2OK_Batch_Job__c newBatchJob = new V2OK_Batch_Job__c(Process_Name__c = nextBatchJob,  
                                                                      Start_Time__c = Datetime.now(),
                                                                      Status__c = VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_STARTED,
                                                                      Next_Batch_Process__c=NextBatchProcess); 
                                                                            
                insert  newBatchJob;                          
            }
            else   //2012.02.25.  
            {
                System.Debug('Missing UserList');
            }
               
        }
 
    return result;
 
  }
}