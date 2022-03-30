public class Ecuphar_Order_Email_Wholesaler {
    
    public Id OId {get;set;}
    
    public List<Order_Line_vod__c> getOrderLinesList() { 
        
        List<Order_Line_vod__c> OLs;
        
        OLs = [
                SELECT Id, 
                Quantity_vod__c,
                Product_vod__c, 
                Product_vod__r.Name,
                EP_Total_Product_Score__c,
                Product_vod__r.EP_Material__c,
                Free_Goods_vod__c,
            	Line_Discount_vod__c
                FROM Order_Line_vod__c 
                WHERE Order_vod__c = :OId
            ];
      
        return OLs;
    }

}