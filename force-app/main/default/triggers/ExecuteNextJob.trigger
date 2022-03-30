/*********************************************************
When a job is finished  and its  status  is updated to
COMPLETED  this  trigger  calculates the next pair  of
Current/Next  job  and sends an emaill with  this info
The email  is handled  by a dedicated class  and initiates
a new job
This trigger is not supposed  to change.
*********************************************************/
trigger ExecuteNextJob on V2OK_Batch_Job__c (after update) 
{
    
      for (V2OK_Batch_Job__c batchJob : Trigger.new)         
      {
      	//
        Data_Connect_Setting__c connectSettings = Data_Connect_Setting__c.getInstance('ToEmailService');
        String veeva2OKBatchEndpoint = connectSettings.Value__c; 
        String strSubject = '';
        
        if(batchJob.Process_Name__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_ADDRESS &&
            batchJob.Status__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_COMPLETED && 
            batchJob.Next_Batch_Process__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS)
        {
            //Kick Off the next set of Jobs - Current Job : Next Job
            //2012.;09.21 ORIGINAL strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_CLEAN_UP_ADDRESS;       
            strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS_EXT;  
            System.Debug('CSAABA: ' + strSubject);
        }
        /********************************** 2012.09.21. ************************************************/ 
         else if(batchJob.Process_Name__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS &&
                 batchJob.Status__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_COMPLETED && 
                 batchJob.Next_Batch_Process__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS_EXT)
        {
            //strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS_EXT + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_CLEAN_UP_ADDRESS;
            strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS_EXT + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.VEEVA_BATCH_ONEKEY_DELETE_INACTIVE_ADDR;
        } 
         else if(batchJob.Process_Name__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_SYNCH_INDVIDUAL_ADDRESS_EXT &&     
                 batchJob.Status__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_COMPLETED && 
                 batchJob.Next_Batch_Process__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.VEEVA_BATCH_ONEKEY_DELETE_INACTIVE_ADDR)
        {
            strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.VEEVA_BATCH_ONEKEY_DELETE_INACTIVE_ADDR + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_CLEAN_UP_ADDRESS;
        } 

         else if(batchJob.Process_Name__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.VEEVA_BATCH_ONEKEY_DELETE_INACTIVE_ADDR &&
                 batchJob.Status__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_COMPLETED && 
                 batchJob.Next_Batch_Process__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_CLEAN_UP_ADDRESS)
        {
            strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_CLEAN_UP_ADDRESS + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_RUN_DELETES;
        }               
        /********************************** 2012.09.21 *************************************************/
        else if(batchJob.Process_Name__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_CLEAN_UP_ADDRESS &&
                 batchJob.Status__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_COMPLETED && 
                 batchJob.Next_Batch_Process__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_RUN_DELETES)
        {    
           strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_RUN_DELETES + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_DCR_RESP; //2012.03.24.    
        }
         //CSABA 2012.03.24.  add the DataChangeRequest Response batch to the chain
         else if(batchJob.Process_Name__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_RUN_DELETES &&
                 batchJob.Status__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_COMPLETED && 
                 batchJob.Next_Batch_Process__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_DCR_RESP)
         {           
         //2012.05.08. strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_DCR_RESP + ':';  
         strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_DCR_RESP + ':' + VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_UPDATE_DMMY_WKP_NAME;
         }  
         //CSABA 2012.05.08.  add the JOB_PROCESS_UPDATE_DMMY_WKP_NAME batch to the chain
         else if(batchJob.Process_Name__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_DCR_RESP &&
                 batchJob.Status__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.STATUS_COMPLETED && 
                 batchJob.Next_Batch_Process__c == VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_UPDATE_DMMY_WKP_NAME)
         {             
         strSubject = VEEVA_BATCH_ONEKEY_BATCHUTILS.JOB_PROCESS_UPDATE_DMMY_WKP_NAME + ':';  
         }         
               

         
        //if the string is not empty send an email. The email service handler class will create new JOB record
        //and BATCH UTILITY class will run again upon BAtchJOB insert
        
        System.Debug('NEXT JOB: ' + strSubject);
        
        if(strSubject != '')
        {
            VEEVA_BATCH_ONEKEY_BATCHUTILS.sendEmail(veeva2OKBatchEndpoint, strSubject);
        }   
        
        
      }//end of for
      
      

}