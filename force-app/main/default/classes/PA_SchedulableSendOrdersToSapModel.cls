/* @Author : Agimenez
   Description: This class is the Schedulable&Batchable that checks all pending to send Orders that have been
   submitted and invokes the SendOrderService for each of those Orders(1by1 since SAP WS was built that way) 
*/

public with sharing class PA_SchedulableSendOrdersToSapModel implements Database.AllowsCallouts,Schedulable,Database.Batchable<sObject> {
    private static string sent = 'Submitted_vod';
    private static string country='IT';
    private static DateTime lastDay = System.now().addHours(-24);
    private static Set<String> ordersToExclude = new Set<String>{'Transfer_vod'};
    
    // THIS IS THE CORRECT QUERY
    private String query = 'SELECT Id,EP_External_ID__c,Name,Wholesaler_vod__r.External_ID_vod__c,Account_vod__r.Country_code__c,LastModifiedDate,LastModifiedBy.Name FROM Order_vod__c WHERE LastModifiedDate >= YESTERDAY AND Status_vod__c =:SENT AND Parent_Order_vod__c = NULL AND EP_External_ID__c = NULL and RecordType.DeveloperName NOT IN :ordersToExclude and Account_vod__r.Country_code__c =:country ';
    // ----------------
    //THIS IS FOR TESTING PURPOSES
    //private String query = 'SELECT Id,EP_External_ID__c,Name,Wholesaler_vod__r.External_ID_vod__c,Account_vod__r.Country_code__c,LastModifiedDate,LastModifiedBy.Name FROM Order_vod__c WHERE Status_vod__c =:SENT AND Parent_Order_vod__c = NULL AND EP_External_ID__c = NULL';
    //private String query = 'SELECT Id,EP_External_ID__c,Name,Wholesaler_vod__r.External_ID_vod__c,Account_vod__r.Country_code__c,LastModifiedDate,LastModifiedBy.Name FROM Order_vod__c WHERE id = \'a1F0X000008THE3\' ';
    //------------------
    
    private Map<id,Order_vod__c> orders;
    private Map<id,Order_line_vod__c> ordersLineToUpdate;
    private Map<id,Order_vod__c> ordersToUpdate;
    private static final string FOLDERNAME = 'SAP_WS';
    public static final Id FOLDERID = [SELECT ID FROM Folder WHERE DeveloperName =: FOLDERNAME].Id;

    public PA_SchedulableSendOrdersToSapModel (){

    }

    public PA_SchedulableSendOrdersToSapModel (String query){
        this.query = query;
    }

    //Schedulable Method
    public void execute(System.SchedulableContext thecontext) {
        Database.executeBatch(this);
    }


    /*This function creates a document with a line for each sent trade storing the following info:
        Order ID; Order NAme ; Order's Account Country code; SAP ID If success otherwise Error message.
    */
    private void logSchedulableResults(Map<id,PA_SendOrderService.ResponseWrapper> mapResults) {
        String docBody = '';
        boolean ko = false; // indicates if there's was at leas 1 failed sync
        String docTitle = 'Order:'+System.now()+':';    
        for(Id identifier: mapResults.keyset()){
            Order_vod__c o = Orders.get(identifier);
            docBody += o.id+';'+o.Name+';'+o.Account_vod__r.Country_code__c;
            PA_SendOrderService.ResponseWrapper response = mapResults.get(identifier);
            if(response.SAPResponse!=NULL){
            for(PA_WSCli_SendOrderSAP.BAPIRET2 item : response.SAPResponse.RETURN_x.item) {
                if(item.TYPE_x == 'E') {
                    docBody += ';Error : '+ item.MESSAGE;
                    ko = true;
                }
            }
            docBody+=(!String.isBlank(response.SAPResponse.SALESDOCUMENT))?
                ';External ID : '+response.SAPResponse.SALESDOCUMENT+'\n':'\n';
           }
           else {
               docBody+='Exception : '+Response.excep.getLineNumber()+':'+ response.excep.getMessage()+'\n';
               ko = true;
           }
        }
        //Store document && notify admin if there was any error
        Id docId = PA_UtilDocsModel.CreateDoc(docTitle,docBody,FOLDERID);
        if(ko) {
            PA_EmailUtilsModel.SendEmailToAdmin('Errors detected in Order WS with SAP',URL.getSalesforceBaseUrl().toExternalForm()+'/'+docId);
        } 
    }

    // Batch Methods
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        Orders = new Map<id,Order_vod__c> ((List<Order_vod__c>) scope);
        PA_SendOrderService.ResponseWrapper fullResponse;
      
        OrdersToUpdate = new Map<id,Order_vod__c> ();
        ordersLineToUpdate = new Map<id,Order_line_vod__c> ();

        Map<id,PA_SendOrderService.ResponseWrapper> mapResults = new Map<id,PA_SendOrderService.ResponseWrapper> ();
        String externalId;
        for(Order_vod__c o: Orders.values()){
            fullResponse = PA_SendOrderService.sendOrder(o.Id);
            System.debug('Test');
            System.debug('fullResponse.SAPresponse.SALESDOCUMENT'+fullResponse.SAPresponse.SALESDOCUMENT);
            externalId = fullResponse.SAPresponse.SALESDOCUMENT;      
                mapResults.put(o.id,fullResponse);
                if(String.isBlank(o.EP_External_ID__c) && fullresponse.excep==null && !String.isBlank(fullResponse.SAPresponse.SALESDOCUMENT)){
                    o.EP_External_ID__c = externalId;
                    o.override_lock_vod__c= true;
                    OrdersToUpdate.put(o.id,o);
                }
        }
        System.debug('externalId'+externalId);
        for(Order_Line_vod__c orderlineItem:[Select id, Order_vod__c,Order_vod__r.EP_External_ID__c, Product_vod__r.External_ID_vod__c, EP_External_ID__c from Order_Line_vod__c where order_vod__c in:Orders.keySet()]){
                System.debug('orderLineItem'+orderLineItem);
                orderLineItem.EP_External_ID__c = externalId + '_' + orderlineItem.Product_vod__r.External_ID_vod__c; 
                System.debug('orderLineItem.EP_External_ID__c '+orderLineItem.EP_External_ID__c );
                ordersLineToUpdate.put(orderlineItem.id,orderlineItem);
                System.debug('ordersLineToUpdate '+ordersLineToUpdate );
        }
        
        logSchedulableResults(mapResults);
        update OrdersToUpdate.values();
        update ordersLineToUpdate.values ();
    }

    public void finish(Database.BatchableContext bc){
        
    }
}