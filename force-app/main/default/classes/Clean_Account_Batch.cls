global class Clean_Account_Batch implements Database.batchable<sObject>
 
{

    
    global final String query;

    

    global final List<Account> deleteAccList; 

    

    global Clean_Account_Batch(String q)

     {

        this.query = q;

    }




    global Database.QueryLocator start(Database.BatchableContext BC)

    {

        return Database.getQueryLocator(query);
 
    }




    global void execute(Database.BatchableContext BC, List<Account> scope)

    {

        delete scope;

    }




    global void finish(Database.BatchableContext BC)
 
    {

    }

}