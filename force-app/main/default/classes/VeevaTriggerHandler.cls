/*
 * VeevaTriggerHandler
 * Description: Extend this class to inherit common functionality between trigger handlers (e.g. trigger context switch, trigger recursion, etc.)
 * 
 * To set up trigger and trigger handler:
 * 1. Create a Trigger Handler class and extend this class
 * 2. Create the trigger on the object you're working on and instantiate your handler class
 * 3. Call handleTrigger()
 * 
 * Usage:
 * -Override trigger context methods (beforeInsert(), afterUpdate(), etc.) and add business logic
 * -Override preTrigger and save+cast the arguments, these will be what you refer to in place of Trigger.New, Trigger.Old, etc.
 * -(Optional) If you want to eliminate trigger recursion, override the doRecursionCheck() method to return true
 * 
 */
public abstract class VeevaTriggerHandler {
        
    //Method must be overridden - This method should return the name of the Object (e.g. return 'Call2_vod__c')
    //This is used to allow an easier cast of the Maps in preTrigger()
    protected abstract String sObjectType();
    
    //Trigger context methods - override as needed and add business logic
    //If you don't need to add logic to a certain context, theres no need to override it in the child class
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
    
    //preTrigger - Override and save these arguments in the child class
    //Regardless of whether you are turning on recursion checking, you can use these in place of the usual trigger variables - Trigger.New, Trigger.NewMap, Trigger.Old, and Trigger.OldMap
    //If you are turning on recursion checking, then you MUST use these arguments
    //In the method you can cast these from the SObject type to the respective object the handler is handling e.g. Map<ID, Call2_vod__c> newCallsMap = (Map<ID, Call2_vod__c>) triggerNewMap
    protected virtual void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {}
    
    private List<SObject> newRecordsToProcess = new List<SObject>();
    private List<SObject> oldRecordsToProcess = new List<SObject>();
    private Map<ID, SObject> newRecordsMapToProcess = new Map<ID, SObject>();
    private Map<ID, SObject> oldRecordsMapToProcess = new Map<ID, SObject>();

    static Set<ID> processedIds = new Set<ID>();
    
    //main method
    public void handleTrigger() {
        filterRecordsToProcess(Trigger.operationType, Trigger.New, Trigger.Old, Trigger.NewMap, Trigger.OldMap);
        if (Trigger.isExecuting && haveRecordsToProcess()) {
            System.TriggerOperation triggerOperation = Trigger.operationType;
            
            preTrigger(getRecursionCheckedTriggerList(TriggerContextVariable.TRIGGER_NEW), 
                       getRecursionCheckedTriggerList(TriggerContextVariable.TRIGGER_OLD), 
                       getRecursionCheckedTriggerMap(TriggerContextVariable.TRIGGER_NEW_MAP), 
                       getRecursionCheckedTriggerMap(TriggerContextVariable.TRIGGER_OLD_MAP));
            
            switch on triggerOperation {
                when BEFORE_INSERT {
                    beforeInsert();
                }
                when BEFORE_UPDATE {
                    beforeUpdate();
                }
                when BEFORE_DELETE {
                    beforeDelete();
                }
                when AFTER_INSERT {
                    afterInsert();
                }
                when AFTER_UPDATE {
                    afterUpdate();
                    addProcessedIds();
                }
                when AFTER_DELETE {
                    afterDelete();
                }
                when AFTER_UNDELETE {
                    afterUndelete();
                }
            }
        }
    }
    
    //Recursion Check off by default, must explicitly turn on by overriding
    protected virtual boolean doRecursionCheck() {
        return false;
    }
    
    //If recursion checking is turned on - to prevent executing the same logic on the same records, we filter out those that have already gone through the before/after update cycle
    //If recursion checking is off - all records will be added to the new/oldRecordsToProcess variables
    @TestVisible protected virtual void filterRecordsToProcess(System.TriggerOperation context, List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        if (doRecursionCheck() && (context == System.TriggerOperation.BEFORE_UPDATE || context == System.TriggerOperation.AFTER_UPDATE)) {
            for (ID recordId : triggerOldMap.keySet()) {
                if (!processedIds.contains(recordId)) {
                    oldRecordsToProcess.add(triggerOldMap.get(recordId));
                    oldRecordsMapToProcess.put(recordId, triggerOldMap.get(recordId));
                    newRecordsToProcess.add(triggerNewMap.get(recordId));
                    newRecordsMapToProcess.put(recordId, triggerNewMap.get(recordId));
                }
            }
        } else {
            if (triggerNew != null && !triggerNew.isEmpty()) {
                newRecordsToProcess.addAll(triggerNew);
            }
            if (triggerOld != null && !triggerOld.isEmpty()) {
                oldRecordsToProcess.addAll(triggerOld);
            }
            if (triggerNewMap != null && !triggerNewMap.isEmpty()) {
                newRecordsMapToProcess.putAll(triggerNewMap);
            }
            if (triggerOldMap != null && !triggerOldMap.isEmpty()) {
                oldRecordsMapToProcess.putAll(triggerOldMap);
            }
        }
    }
    
    protected virtual boolean haveRecordsToProcess() {
        return !newRecordsToProcess.isEmpty() || !oldRecordsToProcess.isEmpty();
    }
    
    protected virtual void addProcessedIds() {
        processedIds.addAll(newRecordsMapToProcess.keySet());
    }
    
    @TestVisible private List<SObject> getRecursionCheckedTriggerList(TriggerContextVariable triggerVar) {
        if (triggerVar == TriggerContextVariable.TRIGGER_NEW) {
            return newRecordsToProcess;
        } else if (triggerVar == TriggerContextVariable.TRIGGER_OLD) {
            return oldRecordsToProcess;
        }
        return new List<SObject>();
    }
    
    @TestVisible private Map<Id, SObject> getRecursionCheckedTriggerMap(TriggerContextVariable triggerVar) {
        String mapType = 'Map<Id, {0}>';
        List<String> args = new List<String>();
        args.add(sObjectType());
        Type t = Type.forName(String.format(mapType, args));
        Map<Id, SObject> typedMap = (Map<Id,SObject>) t.newInstance();
        
        if (triggerVar == TriggerContextVariable.TRIGGER_NEW_MAP) {
            typedMap.putAll(newRecordsToProcess);
        } else if (triggerVar == TriggerContextVariable.TRIGGER_OLD_MAP) {
            typedMap.putAll(oldRecordsToProcess);
        }
        return typedMap;
    }
    
    @TestVisible enum TriggerContextVariable {
        TRIGGER_NEW, TRIGGER_OLD, TRIGGER_NEW_MAP, TRIGGER_OLD_MAP
    }
    
    @TestVisible private void setProcessedIds(Set<Id> ids) {
        processedIds.addAll(ids);
    }
}