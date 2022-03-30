public class VEEVA_WEC_ACCOUNT_MSG_LIMIT_SCHEDULED implements Schedulable, Database.Batchable<Account> {

   public void execute(SchedulableContext SC){
      Id batchId = Database.executeBatch(this);
   }

   public Iterable<Account> start(Database.BatchableContext bc) {
       List<Account> accs = [SELECT Id From Account WHERE Total_Sent_Message_vod__c >:0];
       return accs;
   }

   public void execute(Database.BatchableContext bc, List<Account> records) {
       for(Account account: records) {
          account.Total_Sent_Message_vod__c = 0;
       }
       update records;
   }

   public void finish(Database.BatchableContext bc) {

   }
}