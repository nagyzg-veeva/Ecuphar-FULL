public class VOD_EVENT_TRIG {
    public static void rollUptoBudget(Decimal committed, Decimal estimated, Id budgetId) {
        if(budgetId != null && (committed != 0 || estimated != 0)) {
            EM_Budget_vod__c budget = [Select Actual_Expenses_vod__c,
                                              Committed_Expenses_vod__c,
                                              Estimated_Expenses_vod__c,
                                              Parent_Budget_vod__c
                                              FROM EM_Budget_vod__c
                                              WHERE Id = :budgetId]; 
            if(budget != null) {
                if(budget.Committed_Expenses_vod__c == null) {
                    budget.Committed_Expenses_vod__c = committed;
                } else {
                	budget.Committed_Expenses_vod__c += committed;    
                }
                
                if(budget.Estimated_Expenses_vod__c == null) {
                    budget.Estimated_Expenses_vod__c = estimated;
                } else {
                	budget.Estimated_Expenses_vod__c += estimated;    
                }
				update budget;
                if(budget.Parent_Budget_vod__c != null) {
                	rolluptoBudget(committed, estimated, budget.Parent_Budget_vod__c);    
                }                                                
            }          
        }
    }

    public static void rollUptoBudgetBulk(List<EventBudgetRollup> budgetRollups) {
            if(budgetRollups != null && !budgetRollups.isEmpty()) {
                Set<Id> budgetIds = new Set<Id>();
                List<EventBudgetRollup> parentBudgetRollups = new List<EventBudgetRollup>();
                for(EventBudgetRollup budgetRollup : budgetRollups) {
                    budgetIds.add(budgetRollup.budgetId);
                }
                List<EM_Budget_vod__c>  budgets = [Select Id,
                                                  Actual_Expenses_vod__c,
                                                  Committed_Expenses_vod__c,
                                                  Estimated_Expenses_vod__c,
                                                  Parent_Budget_vod__c
                                                  FROM EM_Budget_vod__c
                                                  WHERE Id IN :budgetIds];
                if(budgets != null && !budgets.isEmpty()) {
                    for(EM_Budget_vod__c budget : budgets) {
                        for(EventBudgetRollup budgetRollup : budgetRollups) {
                            if(budgetRollup.budgetId == budget.Id) {
                                if(budget.Committed_Expenses_vod__c == null) {
                            		budget.Committed_Expenses_vod__c = budgetRollup.commitedDifference;
                                } else {
                                    budget.Committed_Expenses_vod__c += budgetRollup.commitedDifference;
                                }

                                if(budget.Estimated_Expenses_vod__c == null) {
                                    budget.Estimated_Expenses_vod__c = budgetRollup.estimatedDifference;
                                } else {
                                    budget.Estimated_Expenses_vod__c += budgetRollup.estimatedDifference;
                                }
                                if(budget.Parent_Budget_vod__c != null) {
                                    EventBudgetRollup rollup = new EventBudgetRollup();
                                    rollup.commitedDifference = budgetRollup.commitedDifference;
                                    rollup.estimatedDifference = budgetRollup.estimatedDifference;
                                    rollup.budgetId = budget.Parent_Budget_vod__c;
                                    parentBudgetRollups.add(rollup);
                                }
                            }
                		}
                    }
                }
                update budgets;
                if(!parentBudgetRollups.isEmpty()){
                    rollUptoBudgetBulk(parentBudgetRollups);
                }                
            }
        }

    public static boolean isChangedHostOnScheduledWebinar(EM_Event_vod__c newEvent, EM_Event_vod__c oldEvent, EM_Event_vod__c currentEvent) {
        return ('On_vod'.equals(currentEvent.Webinar_Status_vod__c) || 'Sending_vod'.equals(currentEvent.Webinar_Status_vod__c))
                && String.isNotBlank(oldEvent.Assigned_Host_vod__c)
                && !oldEvent.Assigned_Host_vod__c.equals(newEvent.Assigned_Host_vod__c);
    }
}