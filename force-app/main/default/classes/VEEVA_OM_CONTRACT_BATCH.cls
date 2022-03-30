global class VEEVA_OM_CONTRACT_BATCH implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    global void execute(SchedulableContext sc) {
        Database.Batchable<SObject> b = new VEEVA_OM_CONTRACT_BATCH();
        Database.executeBatch(b, 50);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String contractLineFields = 'Id, Product_vod__c, Product_vod__r.Product_Type_vod__c, OM_Quantity_Achieved_vod__c';
        if (MultiCurrencyUtil.isMultiCurrencyOrg()) {
            contractLineFields += ', CurrencyIsoCode';
        }

        return Database.getQueryLocator(
            'SELECT Id, Start_Date_vod__c, End_Date_vod__c, (SELECT ' + contractLineFields +
                    ' FROM Contract_Lines_vod__r) ' +
                'FROM Contract_vod__c ' +
                'WHERE RecordType.DeveloperName = \'Sales_vod\' AND ' +
                'Status_vod__c = \'Activated_vod\' AND ' +
                'Batch_vod__c = true'
        );
    }

    global void execute(Database.BatchableContext bc, List<Contract_vod__c> contracts) {
        addProductsDetailAndGroups(contracts);

        List<Contract_Line_vod__c> updatedContractLines = new List<Contract_Line_vod__c>();
        for(Contract_vod__c contract : contracts) {
            updateContract(contract, updatedContractLines);
        }

        Database.update(contracts);
        Database.update(updatedContractLines);

        /* This is no longer needed, because VEEVA_CONTRACT_BEFORE.trigger already sets override_lock_vod__c on contracts to false (see fixes for CRM-111001)
        for(Integer i = 0; i < contracts.size(); ++i) {
            contracts.set(i, new Contract_vod__c(Id = contracts.get(i).Id, Override_Lock_vod__c = false));
        }
        for(Integer i = 0; i < updatedContractLines.size(); ++i) {
            updatedContractLines.set(i, new Contract_Line_vod__c(Id = updatedContractLines.get(i).Id, Override_Lock_vod__c = false));
        }

        Database.update(updatedContractLines);
        Database.update(contracts);
        */
    }

    global void finish(Database.BatchableContext bc) {
    }

    private void addValueToMultiMap(Map<Id, Set<Id>> multimap, Id key, Id value) {
            Set<Id> groupSet = multimap.get(key);
            if(groupSet == null) {
                groupSet = new Set<Id>();
                multimap.put(key, groupSet);
            }
            groupSet.add(value);
    }

    private void addProductsDetailAndGroups(List<Contract_vod__c> contracts) {
        Set<Id> productDetailIds = new Set<Id>();
        Set<Id> productGroupIds = new Set<Id>();

        for(Contract_vod__c contract : contracts) {
            Contract_Line_vod__c[] contractLines = contract.getSObjects('Contract_Lines_vod__r');

            if(contractLines != null) {
                for(Contract_Line_vod__c contractLine : contractLines) {
                    if(contractLine.Product_vod__r.Product_Type_vod__c == 'Product Group') {
                        productGroupIds.add(contractLine.Product_vod__c);
                    } else if(contractLine.Product_vod__r.Product_Type_vod__c == 'Detail') {
                        productDetailIds.add(contractLine.Product_vod__c);
                    }
                }
            }
        }

        productGroupIds.removeAll(productGroupSets.keySet());
        productDetailIds.removeAll(productDetailSets.keySet());

        if(!productGroupIds.isEmpty()) {
            for(Product_Group_vod__c productGroup : [SELECT Product_Catalog_vod__c, Product_vod__c
                    FROM Product_Group_vod__c
                    WHERE Product_Catalog_vod__c IN :productGroupIds]) {
                addValueToMultimap(productGroupSets, productGroup.Product_Catalog_vod__c, productGroup.Product_vod__c);
            }
        }

        if(!productDetailIds.isEmpty()) {
            for(Product_vod__c product : [SELECT Id, Parent_Product_vod__c
                    FROM Product_vod__c
                    WHERE Parent_Product_vod__c IN :productDetailIds AND Product_Type_vod__c = 'Order']) {
                addValueToMultimap(productDetailSets, product.Parent_Product_vod__c, product.Id);
            }
        }
    }

    private void updateContract(Contract_vod__c contract, List<Contract_Line_vod__c> updatedContractLines) {
        Contract_Line_vod__c[] contractLines = contract.getSObjects('Contract_Lines_vod__r');

        if (contractLines != null) {
            Set<Id> accountIds = new Set<Id>();
            for (Contract_Partner_vod__c cPartner : [
                SELECT Account_vod__c
                FROM Contract_Partner_vod__c
                WHERE Contract_vod__c = :contract.Id
                AND Status_vod__c = 'Activated_vod']) {
                    accountIds.add(cPartner.Account_vod__c);
            }

            VeevaOrderLineAggregator aggregator = new VeevaOrderLineAggregator(contract, accountIds, hasNonOrgCurrencyOrderLine(contractLines, accountIds));
            Map<Id, Map<String, Decimal>> aggregateMap = aggregator.getAggregateMap();

            for(Contract_Line_vod__c contractLine : contractLines) {
                updateContractLine(contractLine, aggregateMap);
                updatedContractLines.add(contractLine);
            }
        }

        contract.Last_Batch_Datetime_vod__c = System.now();
        contract.Override_Lock_vod__c = true;
    }

    private void updateContractLine(Contract_Line_vod__c contractLine, Map<Id, Map<String, Decimal>> aggregateMap) {
        Id productId = contractLine.Product_vod__c;
        String productType = contractLine.Product_vod__r.Product_Type_vod__c;

        resetContractLine(contractLine);
        contractLine.Override_Lock_vod__c = true;

        Set<Id> products = null;
        if(productId == null) {
            // Order level
            products = aggregateMap.keySet();
        } else if(productType == 'Product Group') {
            // Group level
            products = productGroupSets.get(productId);
        } else if(productType == 'Detail') {
            // Brand level
            products = productDetailSets.get(productId);
        } else if(productType == 'Order') {
            // Line level
            products = new Set<Id>();
            products.add(productId);
        }

        if(products != null) {
            for(Id productIdIter : products) {
                accumulateFunction(contractLine, aggregateMap, productIdIter);
            }
        }
    }

    private void resetContractLine(Contract_Line_vod__c contractLine) {
        contractLine.OM_Quantity_Achieved_vod__c = 0;
        contractLine.OM_List_Amount_Achieved_vod__c = 0;
        contractLine.OM_Net_Amount_Achieved_vod__c = 0;
    }

    private void accumulateFunction(Contract_Line_vod__c contractLine, Map<Id, Map<String, Decimal>> aggregateMap, Id productId) {
        Map<String, Decimal> ar = aggregateMap.get(productId);
        if(ar != null) {
            if(ar.get('Quantity_vod__c') != null) {
                contractLine.OM_Quantity_Achieved_vod__c += (Decimal) ar.get('Quantity_vod__c');
            }
            if(ar.get('List_Amount_vod__c') != null) {
                contractLine.OM_List_Amount_Achieved_vod__c += (Decimal) ar.get('List_Amount_vod__c');
            }
            if(ar.get('Net_Amount_vod__c') != null) {
                contractLine.OM_Net_Amount_Achieved_vod__c += (Decimal) ar.get('Net_Amount_vod__c');
            }
        }
    }

    private boolean hasNonOrgCurrencyOrderLine(Contract_Line_vod__c[] lines, Set<Id> accountIds) {
        try {
            if (MultiCurrencyUtil.isMultiCurrencyOrg()) {
                SObject corporateCurrencyObj = Database.query('SELECT IsoCode FROM CurrencyType WHERE IsActive = true AND IsCorporate = true LIMIT 1');
                String corpCurrency = corporateCurrencyObj != null ? (String) corporateCurrencyObj.get('IsoCode') : null;
                if (corpCurrency != null) {
                    for (Contract_Line_vod__c line : lines) {
                        String lineCurrency = (String) line.get('CurrencyIsoCode');
                        if (lineCurrency == null || lineCurrency == corpCurrency) {
                            //go with default aggregate behavior if at least one contract line has the same currency as the org
                            //this is to prevent regressions
                            return false;
                        }
                    }
                    return true;
                }
            }
        } catch (Exception e) {
            System.debug('Error while checking contract line currencies; assuming all contract lines have corporate currency: ' + e.getMessage());
        }
        return false;
    }

    private Map<Id, Set<Id>> productGroupSets = new Map<Id, Set<Id>>();
    private Map<Id, Set<Id>> productDetailSets = new Map<Id, Set<Id>>();
}