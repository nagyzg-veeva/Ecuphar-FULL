/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-25-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   11-25-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class PA_TRIGGER_Order {

    public static void sapIdOrderLine(List<Order_vod__c> newList){
        list<Order_line_vod__c> orderLineToUpdate = new List<Order_Line_vod__c>();
        map<Id,String> orderMap = new map<Id,String>();
        for(Order_vod__c orderItem:newList){
            orderMap.put(orderItem.id,orderItem.EP_External_ID__c);
        }

        for(Order_Line_vod__c orderLineItem:[Select id, order_vod__c, product_vod__r.External_ID_vod__c from Order_line_vod__c where order_vod__c in:OrderMap.keySet()]){
            orderLineItem.EP_External_ID__c = orderMap.get(orderLineItem.order_vod__c) + '_' + orderLineItem.product_vod__r.External_ID_vod__c;
            orderLineToUpdate.add(orderLineItem);
        }
        if(orderLineToUpdate.isEmpty()){
            update orderLineToUpdate;
        }
    }

    public static void updateTotalAmount(List<Order_vod__c> newList){
        Set<Id> setAccount = new Set<Id>();
        for(Order_vod__c orderItem:[Select account_vod__c from Order_vod__c where ID in:newList]){
            setAccount.add(orderItem.Account_vod__c);
        }
        List<Order_vod__c> ordersSubmitted = [Select id, Account_vod__c,Order_Net_Amount_vod__c  from Order_vod__c where Account_vod__c in:setAccount AND Status_vod__c='Submitted_vod' AND Order_Date_vod__c = THIS_YEAR];
        Map<Id,Decimal> mapOrderSum = new Map<Id,Decimal>();
        List<Account> listToUpdate = new List<Account>();
        
        if(!ordersSubmitted.isEmpty()){
            for(Order_vod__c orderItem:ordersSubmitted){
                Decimal summaryOrders=0;
                If(orderItem.Order_Net_Amount_vod__c != null){
                    if(mapOrderSum.containsKey(orderItem.Account_vod__c)){
                        Decimal summaryOrder = 0;
                        Decimal totalSummary ;
                        if(mapOrderSum.get(orderItem.account_vod__c) != null)                        {
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
        }
        for(Account accountItem: [Select id,PA_Total_Trasfer_Order_Amount__c from Account where id in:mapOrderSum.keySet()]){
            if(accountItem.PA_Total_Trasfer_Order_Amount__c == null){
                accountItem.PA_Total_Trasfer_Order_Amount__c = 0;
            }
             accountItem.PA_Total_Trasfer_Order_Amount__c += mapOrderSum.get(accountItem.id);
            listToUpdate.add(accountItem);
        }
        
        if(!listToUpdate.isEmpty()){
            update listToUpdate;
        }
    }
}