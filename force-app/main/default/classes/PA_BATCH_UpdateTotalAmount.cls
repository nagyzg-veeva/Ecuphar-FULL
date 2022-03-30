/*  @Author             :   Rubén Cortés 
*   @Created            :   05 Ene 2021
*   @Description        :   Batch que actualiza la el total transfer amount de las cuentas en función de los pedidos que tenga
*
*   Modification Log
*   ----------------------------------------------------------------------------------------------------------------------------
*   #       Developer               Date                    Description
*   ----------------------------------------------------------------------------------------------------------------------------    
*   1       Rubén Cortés    		05 Ene 2021             Creation
*   ----------------------------------------------------------------------------------------------------------------------------      
*/

global class PA_BATCH_UpdateTotalAmount implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    String query;
    
    global PA_BATCH_UpdateTotalAmount () {
        query='Select id, Account_vod__c,Order_Net_Amount_vod__c from Order_vod__c where Status_vod__c=\'Submitted_vod\' AND Order_Date_vod__c = THIS_YEAR'; 
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query); 
    }
    
    global void execute(SchedulableContext sc){
        database.executebatch(new PA_BATCH_UpdateTotalAmount(),10); 
    }  
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id,Decimal> mapOrderSum = new Map<Id,Decimal>();
        List<Account> listToUpdate = new List<Account>();
        
        if(!scope.isEmpty()){
            List<Order_vod__c> listOrder = scope;
            for(Order_vod__c orderItem : listOrder){
                Decimal summaryOrders=0;
                If(orderItem.Order_Net_Amount_vod__c != null){
                    if(mapOrderSum.containsKey(orderItem.Account_vod__c)){
                        Decimal summaryOrder = 0;
                        Decimal totalSummary ;
                        if(mapOrderSum.get(orderItem.account_vod__c) != null){
                            summaryOrder = mapOrderSum.get(orderItem.account_vod__c);
                            totalSummary = orderItem.Order_Net_Amount_vod__c + summaryOrder;
                            mapOrderSum.put(orderItem.Account_vod__c,totalSummary);
                        }else{
                            totalSummary = orderItem.Order_Net_Amount_vod__c;
                            mapOrderSum.put(orderItem.Account_vod__c,totalSummary);
                        }
                        
                    }else{
                        summaryOrders += orderItem.Order_Net_Amount_vod__c;
                        mapOrderSum.put(orderItem.Account_vod__c,summaryOrders);
                    }
                }
            }
            
            
            for(Account accountItem: [Select id,PA_Total_Trasfer_Order_Amount__c from Account where id in:mapOrderSum.keySet()]){
                if(accountItem.PA_Total_Trasfer_Order_Amount__c == null){
                    accountItem.PA_Total_Trasfer_Order_Amount__c = 0;
                }
                accountItem.PA_Total_Trasfer_Order_Amount__c = mapOrderSum.get(accountItem.id);
                listToUpdate.add(accountItem);
            }
            
            if(!listToUpdate.isEmpty()){
                update listToUpdate;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}