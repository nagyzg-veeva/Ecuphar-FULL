public without sharing class PA_TRIGGER_Account {
    public static void updateTotalAmount(List<Account> newList){
        Map<Id,Decimal> mapOrderSum = new Map<Id,Decimal>();
        List<Order_vod__c> listOrder = [Select account_vod__c, Order_Net_Amount_vod__c from Order_vod__c where account_vod__c in:newList AND Status_vod__c='Submitted_vod' AND Order_Date_vod__c = THIS_YEAR];
        if(!listOrder.isEmpty()){
            
            for(Order_vod__c orderItem:listOrder){
                Decimal summaryOrders=0;
                if(orderItem.Order_Net_Amount_vod__c != null){
                    if(mapOrderSum.containsKey(orderItem.Account_vod__c) ){
                        Decimal summaryOrder = mapOrderSum.get(orderItem.account_vod__c);
                        Decimal totalSummary = orderItem.Order_Net_Amount_vod__c + summaryOrder;
                        mapOrderSum.put(orderItem.Account_vod__c,totalSummary);
                    }else{
                        summaryOrders += orderItem.Order_Net_Amount_vod__c;
                        mapOrderSum.put(orderItem.Account_vod__c,summaryOrders);
                    }
                }
                
            }
            for(Account accItem:newList){
                if(mapOrderSum.containsKey(accItem.id)){
                    accItem.PA_Total_Trasfer_Order_Amount__c = mapOrderSum.get(accItem.id);
                }
                    
            }
        }
    }
}