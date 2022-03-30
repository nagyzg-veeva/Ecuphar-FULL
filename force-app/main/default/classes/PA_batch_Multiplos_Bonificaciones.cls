global class PA_batch_Multiplos_Bonificaciones implements Database.Batchable<SObject>, Schedulable, Database.Stateful{
    
    String  query;
    Id      orderCampaign;
    Map<String, List<Pricing_Subrule_vod__c>> subrulesMap;

    
    global PA_batch_Multiplos_Bonificaciones() {
        query = 'Select Id, Account_Group_vod__c, Chain_Rule_Operator_vod__c, Chain_Rule_vod__c, Active_vod__c,Comparison_Product_vod__c,Comparison_Type_vod__c,Cross_Product_Rule_vod__c,End_Date_vod__c,Free_Goods_Max_vod__c,Free_Goods_vod__c,';
        query += 'Limit_Bound_vod__c,Order_Campaign_vod__c,Product_Comparison_Type_vod__c,Product_vod__c,Quantity_Max_vod__c,';
        query += 'Quantity_Min_vod__c,RecordTypeId,Start_Date_vod__c, EP_Country_Code__c, Pricing_Group_vod__c, Rule_Description_vod__c, Suggestion_Text_vod__c From Pricing_Rule_vod__c Where RecordType.DeveloperName = \'Free_Goods_Rule_vod\'  And PA_Select__c = true';
        subrulesMap = new Map<String, List<Pricing_Subrule_vod__c>>();
    }
    
    global PA_batch_Multiplos_Bonificaciones(String pricingRuleId) {
        query = 'Select Id, Account_Group_vod__c, Chain_Rule_Operator_vod__c, Chain_Rule_vod__c, Active_vod__c,Comparison_Product_vod__c,Comparison_Type_vod__c,Cross_Product_Rule_vod__c,End_Date_vod__c,Free_Goods_Max_vod__c,Free_Goods_vod__c,';
        query += 'Limit_Bound_vod__c,Order_Campaign_vod__c,Product_Comparison_Type_vod__c,Product_vod__c,Quantity_Max_vod__c,';
        query += 'Quantity_Min_vod__c,RecordTypeId,Start_Date_vod__c, EP_Country_Code__c, Pricing_Group_vod__c, Rule_Description_vod__c, Suggestion_Text_vod__c From Pricing_Rule_vod__c Where id = \'' + pricingRuleId + '\'';
        subrulesMap = new Map<String, List<Pricing_Subrule_vod__c>>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }


    global void execute(SchedulableContext sc){
        database.executebatch(new PA_batch_Multiplos_Bonificaciones(),10); 
    }  

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Pricing_Rule_vod__c>           listToUpsert    = new List<Pricing_Rule_vod__c>();

        for(sObject s : scope){
            Pricing_Rule_vod__c a = (Pricing_Rule_vod__c) s;

            //List<Pricing_Subrule_vod__c>     currentSubRules = [Select Comparison_Type_vod__c,Max_Quantity_vod__c, Min_Quantity_vod__c, Product_vod__c,PA_Aplicar_Multiplos__c From Pricing_Subrule_vod__c Where Pricing_Rule_vod__c = :a.Id];

            for(Integer i = 2 ; i<=100; i++){
                Pricing_Rule_vod__c r = new Pricing_Rule_vod__c();
                r.Active_vod__c                         = a.Active_vod__c;
                r.Account_Group_vod__c                  = a.Account_Group_vod__c;
                r.Comparison_Product_vod__c             = a.Comparison_Product_vod__c;
                r.Comparison_Type_vod__c                = a.Comparison_Type_vod__c;
                r.Cross_Product_Rule_vod__c             = a.Cross_Product_Rule_vod__c;
                r.End_Date_vod__c                       = a.End_Date_vod__c;
                r.Free_Goods_Max_vod__c                 = a.Free_Goods_Max_vod__c != null ? a.Free_Goods_vod__c * i + (a.Free_Goods_Max_vod__c - a.Free_Goods_vod__c) : a.Free_Goods_Max_vod__c ;
                r.Free_Goods_vod__c                     = a.Free_Goods_vod__c * i;
                r.Limit_Bound_vod__c                    = a.Limit_Bound_vod__c;
                r.Order_Campaign_vod__c                 = a.Order_Campaign_vod__c;
                //r.PA_Select__c                        = true;
                r.EP_SAP_Code__c                        = a.Id + '_' + i;
                r.Product_Comparison_Type_vod__c        = a.Product_Comparison_Type_vod__c;
                r.Product_vod__c                        = a.Product_vod__c;
                r.Quantity_Max_vod__c                   = a.Quantity_Max_vod__c != null ? a.Quantity_Min_vod__c * (i + 1) - 1 : a.Quantity_Max_vod__c;
                r.Quantity_Max_vod__c                   = i == 100 ? null : r.Quantity_Max_vod__c;
                r.Quantity_Min_vod__c                   = a.Quantity_Min_vod__c * i;
                r.RecordTypeId                          = a.RecordTypeId;
                r.Start_Date_vod__c                     = a.Start_Date_vod__c;
                r.Chain_Rule_Operator_vod__c            = a.Chain_Rule_Operator_vod__c;
                r.Chain_Rule_vod__c                     = a.Chain_Rule_vod__c;
                r.Name                                  = Integer.valueOf(r.Quantity_Min_vod__c) + ' + ' + Integer.valueOf(r.Free_Goods_vod__c);
                r.EP_Country_Code__c                    = a.EP_Country_Code__c;
                r.Pricing_Group_vod__c                  = a.Pricing_Group_vod__c;
                r.Rule_Description_vod__c               = a.Rule_Description_vod__c;
                r.Suggestion_Text_vod__c                = a.Suggestion_Text_vod__c;
                
                System.debug('\n\nPricing Rule: ' + r);
                listToUpsert.add(r);
                subrulesMap.put(r.EP_SAP_Code__c, new List<Pricing_Subrule_vod__c>());

                /*
                for(Pricing_Subrule_vod__c sr : currentSubRules){
                    Integer mult = 1;
                    if(sr.PA_Aplicar_Multiplos__c){
                        mult = i;
                    }
                    Pricing_Subrule_vod__c newSubRule   = new Pricing_Subrule_vod__c();
                    newSubRule.Comparison_Type_vod__c   = sr.Comparison_Type_vod__c;
                    newSubRule.Max_Quantity_vod__c      = sr.Max_Quantity_vod__c != null && sr.PA_Aplicar_Multiplos__c ? sr.Min_Quantity_vod__c * (mult + 1) - 1 : sr.Max_Quantity_vod__c;
                    newSubRule.Max_Quantity_vod__c      = i == 100 ? null : newSubRule.Max_Quantity_vod__c;
                    newSubRule.Min_Quantity_vod__c      = sr.Min_Quantity_vod__c * mult;
                    newSubRule.Product_vod__c           = sr.Product_vod__c;
                    newSubRule.PA_ID_Externo__c         = r.PA_External_ID__c + '_' + newSubRule.Product_vod__c + '_' + newSubRule.Min_Quantity_vod__c;
                    subrulesMap.get(r.PA_External_ID__c).add(newSubRule); 
                }
                */

            }
        }

        System.debug('\n\nlistToUpsert.Size = ' + listToUpsert.size());

        if(!listToUpsert.isEmpty()){
            Schema.SObjectField externalId = Pricing_Rule_vod__c.Fields.EP_SAP_Code__c;
            List<Database.UpsertResult> sr = Database.upsert(listToUpsert, externalId, false);
            for(Database.UpsertResult s : sr){
                if(!s.isSuccess())
                    system.debug(LoggingLevel.Info, 'ERROR --> ' + s.getErrors()[0]);
            }
        }
    }

    
    global void finish(Database.BatchableContext BC){
        /*
        if(!subrulesMap.isEmpty())
            Database.executebatch(new PA_batch_Multiplos_Subrules(subrulesMap),200);
        else
            database.executebatch(new PA_batch_Assorment_Ofertas(),100); 
        */
            
    }
    
}