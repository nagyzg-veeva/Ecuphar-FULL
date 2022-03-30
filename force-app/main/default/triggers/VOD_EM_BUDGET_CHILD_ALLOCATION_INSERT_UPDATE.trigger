trigger VOD_EM_BUDGET_CHILD_ALLOCATION_INSERT_UPDATE on EM_Budget_vod__c (after insert, after update) {
	Map<Id, EM_Budget_vod__c> oldBudgets = new Map<Id, EM_Budget_vod__c>();
    if(trigger.old != null) {
        oldBudgets = trigger.oldMap;
    }

    Map<Id, EM_Budget_vod__c> updateableParentBudgetMap = new Map<Id, EM_Budget_vod__c>();

    Set<Id> parentBudgetIds = new Set<Id>();

    for(EM_Budget_vod__c budget: trigger.new) {
        if(budget.Parent_Budget_vod__c != null) {
            parentBudgetIds.add(budget.Parent_Budget_vod__c);
        }
    }

    boolean multiCurrency = MultiCurrencyUtil.isMultiCurrencyOrg();

    Map<Id, EM_Budget_vod__c> parentBudgetMap = new Map<Id, EM_Budget_vod__c>();
    Map<Id, EM_Budget_vod__c> childBudgetMap = new Map<Id, EM_Budget_vod__c>();
    Map<Id, EM_Budget_vod__c> oldParentBudgetMap = new Map<Id, EM_Budget_vod__c>();

    if(parentBudgetIds.size() > 0) {
        if(multiCurrency) {
            List<EM_Budget_vod__c> budgetList = Database.query('SELECT Child_Budget_Allocation_vod__c, Id, CurrencyIsoCode, Parent_Budget_vod__r.CurrencyIsoCode FROM EM_Budget_vod__c WHERE Id IN ' + MultiCurrencyUtil.toCommaSeperated(parentBudgetIds));
            parentBudgetMap = new Map<Id, EM_Budget_vod__c>(budgetList);
            List<EM_Budget_vod__c> childBudgetList = Database.query('SELECT Id, Parent_Budget_vod__c, Total_Budget_vod__c, CurrencyIsoCode, Child_Budget_Allocation_vod__c FROM EM_Budget_vod__c WHERE Parent_Budget_vod__c IN ' + MultiCurrencyUtil.toCommaSeperated(parentBudgetIds));
            childBudgetMap = new Map<Id, EM_Budget_vod__c>(childBudgetList);
        } else {
            parentBudgetMap = new Map<Id, EM_Budget_vod__c>([SELECT Id, Child_Budget_Allocation_vod__c FROM EM_Budget_vod__c WHERE Id =: parentBudgetIds]);
            childBudgetMap = new Map<Id, EM_Budget_vod__c>([SELECT Id, Parent_Budget_vod__c, Total_Budget_vod__c, Child_Budget_Allocation_vod__c FROM EM_Budget_vod__c WHERE Parent_Budget_vod__c =: parentBudgetIds]);
        }
    }

    Set<Id> oldParentBudgetIds = new Set<Id>();
    for(Id id: oldBudgets.keySet()){
        EM_Budget_vod__c oldBudget = oldBudgets.get(id);
        if(oldBudget.Parent_Budget_vod__c != null) {
            oldParentBudgetIds.add(oldBudget.Parent_Budget_vod__c);
        }
    }
    if(oldParentBudgetIds.size() > 0) {
        if(multiCurrency) {
            List<EM_Budget_vod__c> oldParentBudgetList = Database.query('SELECT Id, Child_Budget_Allocation_vod__c, CurrencyIsoCode FROM EM_Budget_vod__c WHERE Id IN ' + MultiCurrencyUtil.toCommaSeperated(oldParentBudgetIds));
            oldParentBudgetMap = new Map<Id, EM_Budget_vod__c>(oldParentBudgetList);
        } else {
            oldParentBudgetMap = new Map<Id, EM_Budget_vod__c>([SELECT Id, Child_Budget_Allocation_vod__c FROM EM_Budget_vod__c WHERE Id =: oldParentBudgetIds]);
        }           
    }

    for(EM_Budget_vod__c budget: trigger.new) {
        Em_Budget_vod__c oldBudget = oldBudgets.get(budget.id);
        if(oldBudget == null) {
            EM_Budget_vod__c parentBudget = parentBudgetMap.get(budget.Parent_Budget_vod__c);

            if(parentBudget != null && budget.Total_Budget_vod__c != null) {
                Decimal totalBudget;
                if(multiCurrency) {
                    String fromIsoCode = (String)budget.get('CurrencyIsoCode');
                    String toIsoCode = (String)parentBudget.get('CurrencyIsoCode');
                    totalBudget = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, budget.Total_Budget_vod__c);
                } else {
                    totalBudget = budget.Total_Budget_vod__c;
                }

                if(parentBudget.Child_Budget_allocation_vod__c == null) {
                    parentBudget.Child_Budget_Allocation_vod__c = totalBudget;
                } else {
                    parentBudget.Child_Budget_Allocation_vod__c += totalBudget;
                }
                updateableParentBudgetMap.put(parentBudget.Id, parentBudget);
                //parentBudgetList.add(parentBudget);
            }
        } else if (oldBudget.Total_Budget_vod__c != budget.Total_Budget_vod__c) {
            Decimal oldBudgetValue;
            Decimal budgetValue;
            EM_Budget_vod__c parentBudget = parentBudgetMap.get(budget.Parent_Budget_vod__c);
			if(parentBudget != null) {
                if (oldBudget.Total_Budget_vod__c == null) {
                    oldBudgetValue = 0;
                } else if (multiCurrency) {
                    String fromIsoCode = (String)oldBudget.get('CurrencyIsoCode');
                    String toIsoCode = (String)parentBudget.get('CurrencyIsoCode');
                    oldBudgetValue = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, oldBudget.Total_Budget_vod__c);
                } else {
                    oldBudgetValue = oldBudget.Total_Budget_vod__c;
                }

                if (budget.Total_Budget_vod__c == null) {
                    budgetValue = 0;
                } else if (multiCurrency) {
                    String fromIsoCode = (String)budget.get('CurrencyIsoCode');
                    String toIsoCode = (String)parentBudget.get('CurrencyIsoCode');
                    budgetValue = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, budget.Total_Budget_vod__c);
                } else {
                    budgetValue = budget.Total_Budget_vod__c;
                }
                Decimal difference = budgetValue - oldBudgetValue;

                if(parentBudget.Child_Budget_allocation_vod__c == null) {
                    parentBudget.Child_Budget_Allocation_vod__c = difference;
                } else {
                    parentBudget.Child_Budget_Allocation_vod__c += difference;
                }
                updateableParentBudgetMap.put(parentBudget.Id, parentBudget);
            }
        } else if(oldBudget.Parent_Budget_vod__c != budget.Parent_Budget_vod__c){ // CRM-219099. Logic to handle Child_Budget_Allocation_vod__c when reparent a child budget.
            if(budget.Parent_Budget_vod__c != null) {
                // Combine all child's total budget for parent's child budget allocation.
                EM_Budget_vod__c parentBudget = parentBudgetMap.get(budget.Parent_Budget_vod__c);
                Decimal newTotal = 0;
                for (Id id : childBudgetMap.keySet()) {
                    EM_Budget_vod__c childBudget = childBudgetMap.get(id);
                    if(childBudget.Parent_Budget_vod__c == budget.Parent_Budget_vod__c){
                        Decimal budgetValue = getTotalBudget(childBudget, parentBudget);
                        newTotal += budgetValue;
                    }
                }
                if(newTotal > 0){
                    parentBudget.Child_Budget_Allocation_vod__c = newTotal;
                    updateableParentBudgetMap.put(parentBudget.Id, parentBudget);
                }
                
                if(oldBudget.Parent_Budget_vod__c != null) {
                    // Update old parent's child budget allocation to new one.
                    for (Id id : oldParentBudgetMap.keySet()) {
                        EM_Budget_vod__c oldParentBudget = oldParentBudgetMap.get(id);
                        if(oldParentBudget.Id == oldBudget.Parent_Budget_vod__c) {
                            Decimal budgetValue = getTotalBudget(budget, parentBudget);
                            if(oldParentBudget.Child_Budget_Allocation_vod__c != null) {
                                oldParentBudget.Child_Budget_Allocation_vod__c -= budgetValue;
                            }
                            updateableParentBudgetMap.put(oldParentBudget.Id, oldParentBudget);
                        }
                    }
                }
            } else if(budget.Parent_Budget_vod__c == null && oldBudget.Parent_Budget_vod__c != null) {
                // Update old parent's child budget allocation when reparent a NULL parent to a child budget.
                for (Id id : oldParentBudgetMap.keySet()) {
                    EM_Budget_vod__c oldParentBudget = oldParentBudgetMap.get(id);
                    if(oldParentBudget.Id == oldBudget.Parent_Budget_vod__c) {
                        Decimal budgetValue = getTotalBudget(budget, oldParentBudget);
                        if(oldParentBudget.Child_Budget_Allocation_vod__c != null) {
                            oldParentBudget.Child_Budget_Allocation_vod__c -= budgetValue;
                        }
                        updateableParentBudgetMap.put(oldParentBudget.Id, oldParentBudget);
                    }
                }
            }
        }
    }

    if(!updateableParentBudgetMap.isEmpty()) {
        update updateableParentBudgetMap.values();
    }

    /**
     * Convert TotalBudget based on currency. Return default TotalBudget if the Org is not support Multi Currency.
     */
    Decimal getTotalBudget(EM_Budget_vod__c budget, EM_Budget_vod__c parentBudget) {
        Decimal budgetValue = null;
        if (budget.Total_Budget_vod__c == null) {
            budgetValue = 0;
        } else if (MultiCurrencyUtil.isMultiCurrencyOrg()) {
            String fromIsoCode = (String)budget.get('CurrencyIsoCode');
            String toIsoCode = (String)parentBudget.get('CurrencyIsoCode');
            budgetValue = MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, budget.Total_Budget_vod__c);
        } else {
            budgetValue = budget.Total_Budget_vod__c;
        }
        return budgetValue;
    }
}