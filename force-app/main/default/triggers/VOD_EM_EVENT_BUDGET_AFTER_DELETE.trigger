trigger VOD_EM_EVENT_BUDGET_AFTER_DELETE on EM_Event_Budget_vod__c (after delete) {
    Set<Id> emBudgetIds = new Set<Id>();
    for (EM_Event_Budget_vod__c  eventBudget: Trigger.old) {
        emBudgetIds.add(eventBudget.Budget_vod__c);
    }
    if (emBudgetIds.size() > 0) {
        VOD_EXPENSE_LINE_TRIG.calculateEMBudgets(emBudgetIds);
    }
}