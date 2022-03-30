trigger VOD_EXPENSE_LINE_DELETE on Expense_Line_vod__c (before delete) {
    Set<Id> eventIds = new Set<Id>();
    Set<Id> expenseLineIds = new Set<Id>();

    for (Expense_Line_vod__c line : Trigger.old) {
        if (line.Event_vod__c != null) {
            eventIds.add(line.Event_vod__c);
            expenseLineIds.add(line.Id);
        }
    }

    Map<Id, EM_Event_vod__c> eventMap = new Map<Id, EM_Event_vod__c>([SELECT Id, Lock_vod__c, Override_Lock_vod__c
                                                                      FROM EM_Event_vod__c
                                                                      WHERE Id IN : eventIds]);
    Set<String> lockedEvents = new Set<String>();
    for (Id eventId : eventMap.keySet()) {
        EM_Event_vod__c event = eventMap.get(eventId);
        if (VOD_Utils.isEventLocked(event)) {
            lockedEvents.add(event.Id);
        }
    }

    VOD_EVENT_UTILS.addErrorToLockedEventChildObject(Trigger.old, lockedEvents);

    // Because expense line and expense attribution are Master-Detail relationship, delete expense attribution explicitly to make sure execute its delete trigger to recalc speaker YTD.
    List<Expense_Attribution_vod__c> attributions = [SELECT Id FROM Expense_Attribution_vod__c WHERE Expense_Line_vod__c IN :expenseLineIds];
    try {
        if(attributions.size() > 0) {
            delete attributions;
        }
    } catch (DmlException e) {
        for (Integer i = 0; i < e.getNumDml(); i++) {
            System.debug(e.getDmlMessage(i));
        }
    }

}