public without sharing class VeevaEmEventBudgetTriggerHandler {

    private boolean isExecuting = false;
    private integer batchSize = 0;
    private System.TriggerOperation triggerOperation;

    private List<EM_Event_Budget_vod__c> newEventBudgetsToProcess = new List<EM_Event_Budget_vod__c>();
    private List<EM_Event_Budget_vod__c> oldEventBudgetsToProcess = new List<EM_Event_Budget_vod__c>();
    private Map<ID, EM_Event_Budget_vod__c> newEventBudgetsMapToProcess = new Map<ID, EM_Event_Budget_vod__c>();
    private Map<ID, EM_Event_Budget_vod__c> oldEventBudgetsMapToProcess = new Map<ID, EM_Event_Budget_vod__c>();

    public static Set<ID> processedIds = new Set<ID>();

    public VeevaEmEventBudgetTriggerHandler(boolean isExecuting, integer size, System.TriggerOperation triggerOperation, List<EM_Event_Budget_vod__c> newEventBudgets, List<EM_Event_Budget_vod__c> oldEventBudgets, Map<ID, EM_Event_Budget_vod__c> newEventBudgetsMap, Map<ID, EM_Event_Budget_vod__c> oldEventBudgetsMap) {
        this.isExecuting = isExecuting;
        this.batchSize = size;
        this.triggerOperation = triggerOperation;

        filterRecordsToProcess(triggerOperation, newEventBudgets, oldEventBudgets, newEventBudgetsMap, oldEventBudgetsMap);
    }


    public boolean haveRecordsToProcess() {
        return !newEventBudgetsToProcess.isEmpty() || !oldEventBudgetsToProcess.isEmpty();
    }

    private void filterRecordsToProcess(System.TriggerOperation context, List<EM_Event_Budget_vod__c> newEventBudgets, List<EM_Event_Budget_vod__c> oldEventBudgets, Map<ID, EM_Event_Budget_vod__c> newEventBudgetsMap, Map<ID, EM_Event_Budget_vod__c> oldEventBudgetsMap) {
        if (context == System.TriggerOperation.BEFORE_UPDATE || context == System.TriggerOperation.AFTER_UPDATE) {
            for (ID recordId : oldEventBudgetsMap.keySet()) {
                if (!processedIds.contains(recordId)) {
                    oldEventBudgetsToProcess.add(oldEventBudgetsMap.get(recordId));
                    oldEventBudgetsMapToProcess.put(recordId, oldEventBudgetsMap.get(recordId));
                    newEventBudgetsToProcess.add(newEventBudgetsMap.get(recordId));
                    newEventBudgetsMapToProcess.put(recordId, newEventBudgetsMap.get(recordId));
                }
            }
        } else {
            if (newEventBudgets != null) {
                newEventBudgetsToProcess.addAll(newEventBudgets);
            }
            if (oldEventBudgets != null) {
                oldEventBudgetsToProcess.addAll(oldEventBudgets);
            }
            if (newEventBudgetsMap != null) {
                newEventBudgetsMapToProcess.putAll(newEventBudgetsMap);
            }
            if (oldEventBudgetsMap != null) {
                oldEventBudgetsMapToProcess.putAll(oldEventBudgetsMap);
            }
        }
    }

    public void handleTrigger() {
        if (!haveRecordsToProcess()) {
            return;
        }
        switch on triggerOperation {
            when BEFORE_INSERT {
            }
            when BEFORE_UPDATE {
            }
            when BEFORE_DELETE {
            }
            when AFTER_INSERT {
            }
            when AFTER_UPDATE {
            }
        }
    }

    public void vodEmRollupBudget() {
        Set<Id> emBudgetIds = new Set<Id>();
        for (EM_Event_Budget_vod__c  beforeBudget: oldEventBudgetsToProcess) {
            EM_Event_Budget_vod__c  afterBudget = newEventBudgetsMapToProcess.get(beforeBudget.id);
            Decimal beforeEstimate = beforeBudget.Estimate_vod__c == null ? 0: beforeBudget.Estimate_vod__c;
            Decimal beforeCommitted = beforeBudget.Committed_vod__c == null ? 0: beforeBudget.Committed_vod__c;
            Decimal beforeActual = beforeBudget.Actual_vod__c == null ? 0: beforeBudget.Actual_vod__c;
            Decimal afterEstimate = afterBudget.Estimate_vod__c == null ? 0: afterBudget.Estimate_vod__c;
            Decimal afterCommitted = afterBudget.Committed_vod__c == null ? 0: afterBudget.Committed_vod__c;
            Decimal afterActual = afterBudget.Actual_vod__c == null ? 0: afterBudget.Actual_vod__c;
            if (beforeBudget.Budget_vod__c != afterBudget.Budget_vod__c) {
                if (beforeBudget.Budget_vod__c != null && (beforeEstimate != 0 || beforeCommitted != 0 || beforeActual != 0)) {
                    emBudgetIds.add(beforeBudget.Budget_vod__c);
                }
                if (afterBudget.Budget_vod__c != null && (afterEstimate != 0 || afterCommitted != 0 || afterActual != 0)) {
                    emBudgetIds.add(afterBudget.Budget_vod__c);
                }
            }
        }
        if (emBudgetIds.size() > 0) {
            VOD_EXPENSE_LINE_TRIG.calculateEMBudgets(emBudgetIds);
        }
    }
}