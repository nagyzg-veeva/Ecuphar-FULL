public inherited sharing class VeevaOrderLineAggregator {
    private static List<String> AMOUNT_FIELDS = new List<String> {'Quantity_vod__c', 'List_Amount_vod__c', 'Net_Amount_vod__c'};
    
    private final boolean aggregateManually;
    private final Contract_vod__c contract;   
    private final Set<Id> accountIds;
    
    public VeevaOrderLineAggregator(Contract_vod__c contract, Set<Id> accountIds, boolean aggregateManually) {
        this.aggregateManually = aggregateManually;
        this.contract = contract;
        this.accountIds = accountIds;
    }
    
    public Map<Id, Map<String, Decimal>> getAggregateMap() {
        if (aggregateManually) {
            return getManualAggregateMap();
        }
        return getSOQLAggregateMap();
    }
    
    private Map<Id, Map<String, Decimal>> getSOQLAggregateMap() {
        Map<Id,Map<String, Decimal>> aggregateMap = new Map<Id, Map<String, Decimal>>();
        
        AggregateResult[] aggregateList = [SELECT Product_vod__c,
                SUM(Quantity_vod__c) Quantity_vod__c,
                SUM(List_Amount_vod__c) List_Amount_vod__c,
                SUM(Net_Amount_vod__c) Net_Amount_vod__c
            FROM Order_Line_vod__c
            WHERE Order_vod__r.Contract_vod__c = :contract.Id AND
            Order_vod__r.Account_vod__c IN :accountIds AND
            Order_vod__r.Status_vod__c = 'Submitted_vod' AND
            Order_vod__r.Order_Date_vod__c >= :contract.Start_Date_vod__c AND
            Order_vod__r.Order_Date_vod__c <= :contract.End_Date_vod__c AND
            Order_vod__r.Delivery_Order_vod__c = false
            GROUP BY Product_vod__c];
        
        for(AggregateResult ar : aggregateList) {
            Id productId = (Id) ar.get('Product_vod__c');
            Map<String, Decimal> amountsMap = aggregateMap.get(productId);
            if (amountsMap == null) {
                amountsMap = new Map<String, Decimal>();
                aggregateMap.put(productId, amountsMap);
            }
            for (String fld : AMOUNT_FIELDS) {
                amountsMap.put(fld, (Decimal) ar.get(fld));
            }
        }        
            
        return aggregateMap;
    }

    private Map<Id, Map<String, Decimal>> getManualAggregateMap() {
        Map<Id,Map<String, Decimal>> aggregateMap = new Map<Id, Map<String, Decimal>>();
        for (Order_Line_vod__c line: [SELECT Product_vod__c,
                Quantity_vod__c,
                List_Amount_vod__c,
                Net_Amount_vod__c
            FROM Order_Line_vod__c
            WHERE Order_vod__r.Contract_vod__c = :contract.Id AND
            Order_vod__r.Account_vod__c IN :accountIds AND
            Order_vod__r.Status_vod__c = 'Submitted_vod' AND
            Order_vod__r.Order_Date_vod__c >= :contract.Start_Date_vod__c AND
            Order_vod__r.Order_Date_vod__c <= :contract.End_Date_vod__c AND
            Order_vod__r.Delivery_Order_vod__c = false]) {
            
            Id productId = (Id) line.get('Product_vod__c');
            Map<String, Decimal> amountsMap = aggregateMap.get(productId);
            if (amountsMap == null) {
                amountsMap = new Map<String, Decimal>();
                aggregateMap.put(productId, amountsMap);
            }

            for (String fld : AMOUNT_FIELDS) {
                if(line.get(fld) != null) {
                    amountsMap.put(fld, getDecimalWithNullCheck(amountsMap, fld) + (Decimal) line.get(fld));
                }
            }            
        }
        return aggregateMap;
    }

    private Decimal getDecimalWithNullCheck(Map<String, Decimal> amountsMap, String fieldName) {
        Decimal currentAmount = amountsMap.get(fieldName);
        return currentAmount != null ? currentAmount : 0;
    }
}