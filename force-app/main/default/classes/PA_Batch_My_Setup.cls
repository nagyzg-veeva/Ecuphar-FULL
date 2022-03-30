/*  @Author             :   Stephanie Dos Santos 
*   @Created            :   26 Sep 2019
*   @Description        :   Batch que actualiza el my setup de los delegados según a que división pertenezcan.
*
*   Modification Log
*   ----------------------------------------------------------------------------------------------------------------------------
*   #       Developer               Date                    Description
*   ----------------------------------------------------------------------------------------------------------------------------    
*   1       Stephanie Dos Santos    26 Sep 2019             Creation
*   ----------------------------------------------------------------------------------------------------------------------------      
*/
global class PA_Batch_My_Setup implements Database.Batchable<SObject>, Schedulable,Database.Stateful{
    Map<String,set<id>> mapFavorite = new Map<String,set<id>>(); 
    String query;
    Boolean insertMySetup = false;
    List<My_Setup_Products_vod__c>  listMySetuptoDelete      = new List<My_Setup_Products_vod__c>();
    Date fechaHoy = System.today();
    List<String> listIntegration = new List<String>();

    global PA_Batch_My_Setup() {
        //query = 'Select ID,Product_Type_vod__c, Country_Code__c From Product_vod__c Where (Product_Type_vod__c = \'Detail\' OR Product_Type_vod__c = \'Detail Group\' OR Product_Type_vod__c =\'Detail Topic\')'; 
        query = 'select id,Product_vod__r.Parent_Product_vod__c,Product_vod__c, product_vod__r.Parent_Product_vod__r.Country_Code__c from Pricing_Rule_vod__c where Product_vod__c != null and recordtype.developername = \'List_Price_Rule_vod\' and Start_Date_vod__c <=: fechaHoy and End_Date_vod__c >= :fechaHoy';
        
        for(My_Setup_Products_vod__c msp:[ select id from My_Setup_Products_vod__c where Favorite_vod__c = false and (NOT (Product_vod__r.Name like '%OTHER%' OR Product_vod__r.Name like '%GDPR%')) limit 7000]){
            listMySetuptoDelete.add(msp);
        }
        System.debug('listMySetuptoDelete'+listMySetuptoDelete);
        if(!listMySetuptoDelete.isEmpty()){
            delete listMySetuptoDelete;
        }
        //Lista para guardar registros creados por integración y no macharlos a false si ya existen
        for(My_Setup_Products_vod__c msp:[ select PA_External_ID__c from My_Setup_Products_vod__c where  Favorite_vod__c = true limit 6000]){
            listIntegration.add(msp.PA_External_ID__c);
        }

    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

 
    global void execute(SchedulableContext sc){
        database.executebatch(new PA_Batch_My_Setup(),50); 
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<My_Setup_Products_vod__c>  listToInsert    = new List<My_Setup_Products_vod__c>();
        Map<String, String>         products        = new Map<String,String>();
        List<Id>                        listScopeProducts = new List<Id>();
        List<Id>                        listOrders      = new List<Id>();
        Map<String,Set<Id>>             favourites      = new Map<String,Set<Id>>();
        Map<String,String>              mapProductGroup = new Map<String,String>();
        list<Id>                        listProductWithOrders = new List<Id>();
        list<Id>                        listProductWithOutOrders = new List<Id>();

        
        for(sObject itemPricing : scope){
            Pricing_Rule_vod__c pricingTemp = (Pricing_Rule_vod__c) itemPricing;
            if(!products.containsKey(pricingTemp.Product_vod__r.Parent_Product_vod__c)){
                products.put(pricingTemp.Product_vod__r.Parent_Product_vod__c,pricingTemp.Product_vod__r.Parent_Product_vod__r.Country_Code__c);
            }
            //listScopeProducts.add(pricingTemp.Product_vod__r.Parent_Product_vod__c);
            System.debug('pricingTemp.Product_vod__r.Parent_Product_vod__c'+pricingTemp.Product_vod__r.Parent_Product_vod__c);
            System.debug('pricingTemp.product_vod__r.Parent_Product_vod__r.Country_Code__c'+pricingTemp.product_vod__r.Parent_Product_vod__r.Country_Code__c);

        }
        //Añadimos los detail groups para que aparezcan en el my setup
        for(Product_vod__c itemProduct: [Select id, Parent_Product_vod__c,Parent_Product_vod__r.Country_Code__c from product_vod__c where id in: products.keySet()]){
            products.put(itemProduct.Parent_Product_vod__c,itemProduct.Parent_Product_vod__r.Country_Code__c);
        }


        System.debug('mapFavorite : '+mapFavorite);
        System.debug('products : '+products);


        for(User itemUser : [Select ID, Country_Code_QS__c From User Where UserRole.Name != 'CEO' and IsActive = true and Country_Code_QS__c!=null]){
            for(Id itemProduct :products.keySet()){
                System.debug('****'+products.get(itemProduct));
                System.debug('*******'+itemUser);
                if(!listIntegration.contains(itemProduct+'_'+itemUser.Id)){//Si ya existen en el CRM y vienen por integración, no se duplican los registros unos a true(Talend) y otros a false
                    if(((products.get(itemProduct) != null && itemUser.Country_Code_QS__c != null && (products.get(itemProduct).contains(itemUser.Country_Code_QS__c) || itemUser.Country_Code_QS__c.contains(products.get(itemProduct))) ))){
                        listToInsert.add(new My_Setup_Products_vod__c(
                            Product_vod__c = itemProduct,
                            OwnerId = itemUser.Id,
                            PA_External_ID__c = itemProduct+'_'+itemUser.Id
                            )
                        ); 
                    }
                }
                
            }
        }
        

        
        System.debug('listToInsert'+listToInsert);
        System.debug('listToInsert'+listToInsert.size());
        if(!listToInsert.isEmpty()){
            upsert listToInsert PA_External_ID__c;
        }
    }

    
    global void finish(Database.BatchableContext BC) {

    }

}