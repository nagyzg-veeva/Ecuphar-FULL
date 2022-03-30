/* @Author : Agimenez
    Description: This class makes a SOAP call to SAP sending the Order corresponding to the ID
    it receives as a parameter.


*/
global with sharing class PA_SendOrderService {
        public static final Id folderID = [SELECT ID FROM Folder WHERE DeveloperName = 'SAP_WS'].Id;
        private static final Map<string,string> mapCountries = new Map<string,string> {'IT'=>'6100','ES'=>'6000','PT'=>'6200'};

      /*  //Method with hardcoded data for service testing purposes
        public static PA_WSCli_SendOrderSAP.ZSD_CREATE_SALESORDERResponse_element sendOrderWithTestData() {
        PA_WSCli_SendOrderSAP.BAPISDHD1 orderHeaderIn = new PA_WSCli_SendOrderSAP.BAPISDHD1();
        orderHeaderIn.DOC_TYPE = 'ZOR';
        orderHeaderIn.SALES_ORG = '6100';
        orderHeaderIn.DISTR_CHAN = '01';
        orderHeaderIn.DIVISION = '01';

        PA_WSCli_SendOrderSAP.BAPISDITM orderItem = new PA_WSCli_SendOrderSAP.BAPISDITM();
        List<PA_WSCli_SendOrderSAP.BAPISDITM> orderItems = new List<PA_WSCli_SendOrderSAP.BAPISDITM>();
        orderItem.ITM_NUMBER = '000010';
        orderItem.MATERIAL = 'SE403993';
        orderItems.add(orderItem);
        PA_WSCli_SendOrderSAP.TABLE_OF_BAPISDITM orderItemTable = new PA_WSCli_SendOrderSAP.TABLE_OF_BAPISDITM();
        orderItemTable.item = orderItems;

        PA_WSCli_SendOrderSAP.BAPIPARNR partner = new PA_WSCli_SendOrderSAP.BAPIPARNR();
        List<PA_WSCli_SendOrderSAP.BAPIPARNR> partners = new List<PA_WSCli_SendOrderSAP.BAPIPARNR>();
        partner.PARTN_ROLE = 'AG';
        partner.PARTN_NUMB = '0000015395';
        partners.add(partner);
        PA_WSCli_SendOrderSAP.TABLE_OF_BAPIPARNR partnersTable = new PA_WSCli_SendOrderSAP.TABLE_OF_BAPIPARNR();
        partnersTable.item = partners;

        PA_WSCli_SendOrderSAP.BAPISCHDL schedule = new PA_WSCli_SendOrderSAP.BAPISCHDL();
        List<PA_WSCli_SendOrderSAP.BAPISCHDL> schedules = new List<PA_WSCli_SendOrderSAP.BAPISCHDL>();
        schedule.ITM_NUMBER = '000010';
        schedule.SCHED_LINE = '0001';
        schedule.REQ_DATE = '2018-08-31';
        schedule.REQ_QTY = '10';
        schedules.add(schedule);
        PA_WSCli_SendOrderSAP.TABLE_OF_BAPISCHDL scheduleTable = new PA_WSCli_SendOrderSAP.TABLE_OF_BAPISCHDL();
        scheduleTable.item = schedules;
        return placeOrder(orderHeaderIn, orderItemTable, partnersTable, scheduleTable,'0001109621');
    
    }*/
    /*
        Auxiliar Class to wrap all the information related to oRderLInes && Schedule Lines, This will help
        on splitted schedule Orders.
    */
    private class ScheduledLine {
        private integer intNumber;
        private Date reqDate;
        private decimal quantity;
        private decimal freeGoods;
        private string material;
        private decimal netPrice;
        private decimal listPrice;
        private string currencyLine;

        ScheduledLine(Order_Line_vod__c orderLine, Order_vod__c parentOrder,integer intNumber){
            this.intNumber =intNumber;
            reqDate = parentOrder.Delivery_Date_vod__c;
            quantity = orderLine.Quantity_vod__c;
            freeGoods = orderLine.Free_Goods_vod__c;
            material = orderLine.Product_vod__r.EP_Material__c;
            netPrice = orderLine.Net_Price_vod__c;
            listPrice = orderLine.List_Price_Rule_vod__c;
            currencyLine = orderLine.CurrencyIsoCode;
        }
    }

    public static ResponseWrapper sendOrder(Id orderId) {
        Order_vod__c parentOrder = new Order_vod__c();
        parentOrder = [SELECT Id,Master_Order_vod__c,Ship_to_address_vod__r.Name,Billing_address_vod__r.Name,EP_External_ID__c,Billing_Address_vod__r.Account_vod__r.PA_SAP_Code__c,Account_vod__r.PA_SAP_Code__c,LastModifiedDate,Wholesaler_vod__r.External_ID_vod__c,Ship_To_Address_vod__r.Account_vod__r.PA_SAP_Code__c, Name,Order_Date_Vod__c,Delivery_Date_vod__c,Account_vod__r.Country_Code__c, EP_CORE_Payment_Terms__c FROM Order_vod__c WHERE Id = :orderId];
        List<Order_Line_vod__c> orderLines;
        Map<id,Order_vod__c> childrenOrders;
        List<ScheduledLine> scheduledLines = new List<ScheduledLine> ();
        if(parentOrder.Master_Order_vod__c){
            childrenOrders = new Map<id,Order_vod__c> ([SELECT Id,Master_Order_vod__c,Ship_to_address_vod__r.Name,Billing_address_vod__r.Name,EP_External_ID__c,Billing_Address_vod__r.Account_vod__r.PA_SAP_Code__c,Account_vod__r.PA_SAP_Code__c,LastModifiedDate,Wholesaler_vod__r.External_ID_vod__c,Ship_To_Address_vod__r.Account_vod__r.PA_SAP_Code__c, Name,Order_Date_Vod__c,Delivery_Date_vod__c,Account_vod__r.Country_Code__c, EP_CORE_Payment_Terms__c FROM Order_vod__c WHERE Parent_Order_vod__c = :orderId]);
        }
        integer intNumber = 10; // Standard SAP offset
        Map<string,integer> mapMaterialPosicion = new Map<string,integer> ();
        //Transform Order lines into Scheduled Lines
        for(Order_Line_vod__c orderLine: (parentOrder.Master_Order_vod__c)? [SELECT id,Name,Product_vod__r.EP_Material__c,Quantity_vod__c,Order_vod__c, Free_Goods_vod__c,List_Price_Rule_vod__c,CurrencyIsoCode,Net_Price_vod__c FROM Order_Line_vod__c WHERE Order_vod__c in: childrenOrders.keyset()]:[SELECT Id,Order_vod__c,Name, Product_vod__r.EP_Material__c,Quantity_vod__c, Free_Goods_vod__c,List_Price_Rule_vod__c,CurrencyIsoCode,Net_Price_vod__c FROM Order_Line_vod__c WHERE Order_vod__c = :orderId]){
                if(!mapMaterialPosicion.containsKey(orderLine.Product_vod__r.EP_Material__c)){
                    mapMaterialPosicion.put(orderline.Product_vod__r.EP_Material__c,intNumber);
                    intNumber = intNumber + 10;                
                }
                integer actualnumber = mapMaterialPosicion.get(orderline.Product_vod__r.EP_Material__c); 
                scheduledLines.add(new ScheduledLine(orderLine,
                                                    (orderLine.Order_vod__c==orderId)?parentOrder:childrenOrders.get(orderLine.Order_vod__c),
                                                    actualnumber));
        }    
        return sendOrder(parentOrder, scheduledLines,parentOrder.EP_External_ID__c);
    }

    global class ResponseWrapper {
        public PA_WSCli_SendOrderSAP.ZSD_CREATE_SALESORDERResponse_element sapResponse;
        public Exception excep;
        ResponseWrapper(PA_WSCli_SendOrderSAP.ZSD_CREATE_SALESORDERResponse_element sapResponse){
            this.sapResponse = sapResponse;
        }
        ResponseWrapper(Exception e){
            excep = e;
        }
    }
    public class NullResponseException extends Exception {

    }

    //TODO: method accepting parentOrder header, parentOrder line, etc
    public static ResponseWrapper sendOrder(Order_vod__c parentOrder, List<ScheduledLine> scheduledLines,String externalId){
        PA_WSCli_SendOrderSAP.BAPISDHD1 orderHeaderIn = new PA_WSCli_SendOrderSAP.BAPISDHD1();
        List<PA_WSCli_SendOrderSAP.BAPISDITM> orderItems = new List<PA_WSCli_SendOrderSAP.BAPISDITM>();
        List<PA_WSCli_SendOrderSAP.BAPICOND> conditionItems = new List<PA_WSCli_SendOrderSAP.BAPICOND>();
        PA_WSCli_SendOrderSAP.TABLE_OF_BAPISDITM orderItemTable = new PA_WSCli_SendOrderSAP.TABLE_OF_BAPISDITM();
        PA_WSCli_SendOrderSAP.TABLE_OF_BAPICOND conditionsItemTable = new PA_WSCli_SendOrderSAP.TABLE_OF_BAPICOND();
        PA_WSCli_SendOrderSAP.BAPISCHDL schedule = new PA_WSCli_SendOrderSAP.BAPISCHDL();
        PA_WSCli_SendOrderSAP.TABLE_OF_BAPISCHDL scheduleTable = new PA_WSCli_SendOrderSAP.TABLE_OF_BAPISCHDL();
        List<PA_WSCli_SendOrderSAP.BAPISCHDL> schedules = new List<PA_WSCli_SendOrderSAP.BAPISCHDL>();
        orderHeaderIn.DOC_TYPE = 'ZOR';
        orderHeaderIn.SALES_ORG = mapCountries.get(parentOrder.Account_vod__r.Country_code__c);
        orderHeaderIn.DISTR_CHAN = '01';
        orderHeaderIn.DIVISION = '01';
        orderHeaderIn.DOC_DATE = String.valueOf(parentOrder.Order_Date_Vod__c);
        orderHeaderIn.REQ_DATE_H = String.valueOf(parentOrder.Delivery_Date_vod__c);
        orderHeaderIn.PURCH_DATE = String.valueOf(parentOrder.Order_Date_Vod__c);
        orderHeaderIn.PURCH_NO_C = 'CRM_'+ parentOrder.Name;
        orderHeaderIn.PMNTTRMS = parentOrder.EP_CORE_Payment_Terms__c;
        orderHeaderIn.DLV_BLOCK = '99';

        //parentOrder Items
        if (scheduledLines.size() > 0) {
            for (ScheduledLine scheduledLine : scheduledLines) {
                PA_WSCli_SendOrderSAP.BAPISDITM orderItem = new PA_WSCli_SendOrderSAP.BAPISDITM();
                //orderItem.ITM_NUMBER = schedule.ITM_NUMBER = String.valueOf(scheduledLine.quantity); //DAC El int number debería ser unico por producto
                orderItem.ITM_NUMBER = schedule.ITM_NUMBER = String.valueOf(scheduledLine.intNumber);
                orderItem.MATERIAL = scheduledLine.material;
                orderItem.ITEM_CATEG = 'ZSTP';
                orderItems.add(orderItem);

                schedule.SCHED_LINE = '0001';
                schedule.REQ_DATE = String.valueOf(scheduledLine.reqDate);
                schedule.REQ_QTY = String.valueOf(scheduledLine.quantity);
                schedules.add(schedule);

                //DAC Add FreeGoods
                if(scheduledLine.freeGoods != null){
                    PA_WSCli_SendOrderSAP.BAPISDITM orderItemBoni = new PA_WSCli_SendOrderSAP.BAPISDITM();
                    
                    orderItemBoni.ITM_NUMBER = String.valueOf(scheduledLine.intNumber+1);
                    orderItemBoni.MATERIAL = scheduledLine.material;
                    orderItemBoni.ITEM_CATEG = 'ZSFP';
                    orderItems.add(orderItemBoni);

                    schedule = new PA_WSCli_SendOrderSAP.BAPISCHDL();
                    schedule.SCHED_LINE = '0001';
                    schedule.ITM_NUMBER = String.valueOf(scheduledLine.intNumber+1);
                    schedule.REQ_DATE = String.valueOf(scheduledLine.reqDate);
                    schedule.REQ_QTY = String.valueOf(scheduledLine.freeGoods);
                    schedules.add(schedule);
                }
                schedule = new PA_WSCli_SendOrderSAP.BAPISCHDL();
                //END FreeGoods


                //@Amartinez add conditions
                if(scheduledLine.netPrice != scheduledLine.listPrice){
                    PA_WSCli_SendOrderSAP.BAPICOND conditionItem = new PA_WSCli_SendOrderSAP.BAPICOND();
                    conditionItem.ITM_NUMBER = String.valueOf(scheduledLine.intNumber);
                    conditionItem.COND_TYPE = 'ZSP';
                    conditionItem.COND_VALUE = String.valueOf(scheduledLine.netPrice);
                    conditionItem.CURRENCY_x = scheduledLine.currencyLine;
                    conditionItem.COND_UNIT = 'ST';
                    conditionItem.COND_P_UNT = '1';
                    conditionItems.add(conditionItem);
                }

            }
            orderItemTable.item = orderItems;
            scheduleTable.item = schedules;
            conditionsItemTable.item = conditionItems;
        }
        //partner
        PA_WSCli_SendOrderSAP.BAPIPARNR partner = new PA_WSCli_SendOrderSAP.BAPIPARNR();
        List<PA_WSCli_SendOrderSAP.BAPIPARNR> partners = new List<PA_WSCli_SendOrderSAP.BAPIPARNR>();
        PA_WSCli_SendOrderSAP.TABLE_OF_BAPIPARNR partnersTable = new PA_WSCli_SendOrderSAP.TABLE_OF_BAPIPARNR();
        
        //Sold to (Account)
        partner.PARTN_ROLE = 'AG';
        partner.PARTN_NUMB = parentOrder.Account_vod__r.PA_SAP_Code__c; 
        partners.add(partner);

        //Ship To (Ship To Address)
        partner = new PA_WSCli_SendOrderSAP.BAPIPARNR();
        partner.PARTN_ROLE = 'WE';
        System.debug('\n\n*** isBlank(Ship_To_Address_vod__r): ' + String.isBlank(parentOrder.Ship_To_Address_vod__r.Account_vod__r.PA_SAP_Code__c));
        if(!String.isBlank(parentOrder.Ship_To_Address_vod__r.Account_vod__r.PA_SAP_Code__c)){
            partner.PARTN_NUMB = parentOrder.Ship_To_Address_vod__r.Account_vod__r.PA_SAP_Code__c;
        }else{
            partner.PARTN_NUMB = parentOrder.Account_vod__r.PA_SAP_Code__c;
        }
        partners.add(partner);

        //Bill-to(Billing Address)
        partner = new PA_WSCli_SendOrderSAP.BAPIPARNR();
        partner.PARTN_ROLE = 'RE';
        System.debug('\n\n*** isBlank(Billing_Address_vod__r): ' + String.isBlank(parentOrder.Billing_Address_vod__r.Account_vod__r.PA_SAP_Code__c));
        if(!String.isBlank(parentOrder.Billing_Address_vod__r.Account_vod__r.PA_SAP_Code__c)){
            partner.PARTN_NUMB = parentOrder.Billing_Address_vod__r.Account_vod__r.PA_SAP_Code__c;
        }else{
            partner.PARTN_NUMB = parentOrder.Account_vod__r.PA_SAP_Code__c;
        }
        partners.add(partner);

        partnersTable.item = partners;
        //schedule
        return placeOrder(orderHeaderIn, orderItemTable, conditionsItemTable, partnersTable, scheduleTable,externalId);
    }
    //Makes call
    private static ResponseWrapper placeOrder(PA_WSCli_SendOrderSAP.BAPISDHD1 orderHeaderIn, PA_WSCli_SendOrderSAP.TABLE_OF_BAPISDITM orderItemTable,PA_WSCli_SendOrderSAP.TABLE_OF_BAPICOND conditionsItemTable, PA_WSCli_SendOrderSAP.TABLE_OF_BAPIPARNR partnersTable, PA_WSCli_SendOrderSAP.TABLE_OF_BAPISCHDL scheduleTable, String externalId) {
        PA_WSCli_SendOrderSAP.ZSD_CREATE_SALESORDER port = new PA_WSCli_SendOrderSAP.ZSD_CREATE_SALESORDER();
    PA_WSCli_SendOrderSAP.ZSD_CREATE_SALESORDERResponse_element response;
    try {    
        
         response = port.ZSD_CREATE_SALESORDER(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,conditionsItemTable,null,
                                                                                                            orderHeaderIn,null,
                                                                                                            orderItemTable,null,null,
                                                                                                            partnersTable, 
                                                                                                            scheduleTable,null,null,null,null,null,null,null);
                                                                                                                                                                                                                                                                                                            
        if(General_Settings__c.getInstance('Standard').Save_request_order_ws__c) {
            PA_UtilDocsModel.CreateDoc('Request SAP Order WS'+System.now(), 'Request:\n'+orderHeaderIn+','+orderItemTable+','+conditionsItemTable+','+partnersTable+','+scheduleTable,folderID);
        } 
        if (response != null){
            return new ResponseWrapper(response);
        }
        else {
            throw new NullResponseException('Reponse received by Order WS was null');
        }
        //On exceptions we just Create the doc with the corresponsing error
    } Catch(Exception e){
        return new ResponseWrapper(E);
    }
    }
}