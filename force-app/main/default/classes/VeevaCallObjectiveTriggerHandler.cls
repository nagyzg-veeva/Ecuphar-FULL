public without sharing class VeevaCallObjectiveTriggerHandler extends VeevaAccountPlanSharingTriggerHandler{

    public void onBeforeInsert(List<Call_Objective_vod__c> newCallObjectives) {
        // place holder
    }
    public void onBeforeUpdate( List<Call_Objective_vod__c> newCallObjectives, List<Call_Objective_vod__c> oldCallObjectives, Map<ID, Call_Objective_vod__c> newCallObjectivesMap , Map<ID, Call_Objective_vod__c> oldCallObjectivesMap ) {
        // place holder
    }

    public void onBeforeDelete (List<Call_Objective_vod__c> oldCallObjectives, Map<ID, Call_Objective_vod__c> oldCallObjectivesMap) {
        callObjectiveAfterUpsertBeforeDeleteLogic(null, oldCallObjectives, false, false, true);
    }

    public void onAfterInsert(List<Call_Objective_vod__c> newCallObjectives) {
        // sharing rules
        super.onAfterInsert(newCallObjectives, 'Call_Objective_vod__c');
        callObjectiveAfterUpsertBeforeDeleteLogic(newCallObjectives, null, true, false, false);

    }
    public void onAfterUpdate( List<Call_Objective_vod__c> newCallObjectives, List<Call_Objective_vod__c> oldCallObjectives, Map<ID, Call_Objective_vod__c> newCallObjectivesMap , Map<ID, Call_Objective_vod__c> oldCallObjectivessMap ) {
        // sharing rules
        super.onAfterUpdate(newCallObjectives, 'Call_Objective_vod__c', oldCallObjectivessMap);
        callObjectiveAfterUpsertBeforeDeleteLogic(newCallObjectives, oldCallObjectives, false, true, false);
    }

    public void onAfterDelete(List<Call_Objective_vod__c> oldCallObjectives, Map<ID, Call_Objective_vod__c> oldCallObjectivesMap) {
        // place holder
    }

    private void callObjectiveAfterUpsertBeforeDeleteLogic(List<Call_Objective_vod__c> newCallObjectives, List<Call_Objective_vod__c> oldCallObjectives, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {
        Integer triggerSize = isDelete ? oldCallObjectives.size() : newCallObjectives.size();

        if (VEEVA_CALL_OBJECTIVE_TRIG.invoked)
        {
            //It is coming from Business_Event_Target trigger
            System.debug('Call_Objective_after_upsert_before_delete: VEEVA_CALL_OBJECTIVE_TRIG.invoked set, exit');
            return;
        }

        VEEVA_CALL_OBJECTIVE_TRIG.invoked = true;

        Set<Call_Objective_vod__c> callObjectiveToUpdate = new Set<Call_Objective_vod__c>();

        Map<Id, RecordType> recTypes = new Map<Id, RecordType>(
        [SELECT Id, Name
        FROM RecordType
        WHERE SobjectType IN ('Business_Event_Target_vod__c', 'Call_Objective_vod__c')
        AND Name IN ('EPPV', 'PI')
        AND IsActive=TRUE]);

        List<Id> betIds = new List<Id>();
        Set<Id> deletedIds = new Set<Id>();
        Boolean[] skip = new Boolean[triggerSize];

        // The case of prerequisite
        if(!isInsert) {
            List<Id> prereqIds = new List<Id>();
            for (Integer idx = 0; idx < triggerSize; idx++) {
                prereqIds.add(oldCallObjectives.get(idx).Id);
            }

            List<Call_Objective_vod__c> children = new List<Call_Objective_vod__c>();
            if(prereqIds.size() > 0) {
                children = [SELECT Id, Prerequisite_vod__c FROM Call_Objective_vod__c WHERE Prerequisite_vod__c IN :prereqIds];
            }

            if(children != null && children.size() > 0 ) {
                for(Integer cildIdx = 0; cildIdx < children.size(); cildIdx++) {
                    children[cildIdx].Non_Executable_vod__c = true;
                }
                System.debug('Call_Objective_after_upsert_before_delete: callObjectiveToUpdate.addAll(children)');
                callObjectiveToUpdate.addAll(children);
            }
        }

        for (Integer idx = 0; idx < triggerSize; idx++)
        {
            skip[idx] = false;
            if (isDelete)
            {
                if (!recTypes.containsKey(oldCallObjectives.get(idx).RecordTypeId))
                {
                    skip[idx] = true;
                    continue;
                }
                deletedIds.add(oldCallObjectives.get(idx).Id);
            }
            else if (!recTypes.containsKey(newCallObjectives.get(idx).RecordTypeId))
            {
                skip[idx] = true;
                continue;
            }
            else
            {
                if (newCallObjectives.get(idx).Business_Event_Target_vod__c == null ||
                        newCallObjectives.get(idx).Business_Event_vod__c == null ||
                        newCallObjectives.get(idx).Account_vod__c == null ||
                        newCallObjectives.get(idx).Date_vod__c == null)
                {
                    newCallObjectives.get(idx).addError((newCallObjectives.get(idx).Name + ' [Business_Event_vod__c, Business_Event_Target_vod__c, Account_vod__c and Date_vod__c] ' + VOD_GET_ERROR_MSG.getErrorMsg('REQUIRED', 'Common')), false);
                    return;
                }
            }
            betIds.add(isDelete ? oldCallObjectives.get(idx).Business_Event_Target_vod__c : newCallObjectives.get(idx).Business_Event_Target_vod__c);
        }

        if(callObjectiveToUpdate.size() > 0) {
            System.debug('Call_Objective_after_upsert_before_delete: update(callObjectiveToUpdateList)');
            List<Call_Objective_vod__c> callObjectiveToUpdateList = new List<Call_Objective_vod__c>(callObjectiveToUpdate);
            update(callObjectiveToUpdateList);
        }

        Map<Id, Business_Event_Target_vod__c> bets = new Map<Id, Business_Event_Target_vod__c>(
        [SELECT Id, RecordTypeId FROM Business_Event_Target_vod__c WHERE Id IN :betIds AND RecordTypeId IN :recTypes.keySet()]);

        for (Integer idx = 0; idx < triggerSize; idx++)
        {
            if (skip[idx])
            {
                continue;
            }
            Id betId = isDelete ? oldCallObjectives.get(idx).Business_Event_Target_vod__c : newCallObjectives.get(idx).Business_Event_Target_vod__c;

            if (betId != null)
            {
                Business_Event_Target_vod__c bet = bets.get(betId);
                if (!isDelete && bet == null)
                {
                    newCallObjectives.get(idx).addError(('Call_Objective ' + newCallObjectives.get(idx).Name + ' ' + VOD_GET_ERROR_MSG.getErrorMsg('Invalid', 'TABLET')  + ' Business_Event_Target_vod__c = ' + betId), false);
                    return;
                }

                if (!isDelete)
                {
                    RecordType coRecType = recTypes.get(newCallObjectives.get(idx).RecordTypeId);
                    RecordType betRecType = recTypes.get(bet.RecordTypeId);

                    if (coRecType == null || betRecType == null)
                    {
                        newCallObjectives.get(idx).addError('RecordType must not be null', false);
                        return;
                    }
                    else if (!coRecType.Name.equals(betRecType.Name))
                    {
                        newCallObjectives.get(idx).addError('Call Objective must be the same RecordType as Business_Event_Target_vod__c', false);
                        return;
                    }
                }

                bet.Next_Visit_Date_vod__c = null;
                bet.Remaining_Calls_vod__c = 0;

                Boolean updBET = isUpdate && newCallObjectives.get(idx).Completed_Flag_vod__c && !oldCallObjectives.get(idx).Completed_Flag_vod__c;

                if (isDelete)
                {
                    if (oldCallObjectives.get(idx).Pre_Explain_Flag_vod__c)
                    {
                        System.debug('Call_Objective_after_upsert_before_delete: trying to reset pre_explain bet ' + bet.Id);
                        bet.Pre_Explain_Date_vod__c = null;
                    }
                    bets.put(betId, bet);
                }
                else if (newCallObjectives.get(idx).Pre_Explain_Flag_vod__c)
                {
                    // this is Pre_Explain Call Objective
                    if (updBET  || (isInsert && newCallObjectives.get(idx).Completed_Flag_vod__c))
                    {
                        // update BET if update status to completed from incompleted, Or insert a new completed
                        bet.Pre_Explain_Date_vod__c = newCallObjectives.get(idx).Date_vod__c.date();
                        bets.put(newCallObjectives.get(idx).Business_Event_Target_vod__c, bet);
                    }
                }
                else if (updBET || (isInsert && !newCallObjectives.get(idx).Completed_Flag_vod__c))
                {
                    // update count if update status to completed from incompleted, Or insert a new incompleted
                    if (!bets.containsKey(newCallObjectives.get(idx).Business_Event_Target_vod__c))
                    {
                        bets.put(newCallObjectives.get(idx).Business_Event_Target_vod__c, bet);
                    }
                }
            }
        }

        // Query Call_Objective_vod to set next visit date and number of remaining calls for the corresponding Business_Event_Target_vod
        for (List<Call_Objective_vod__c> cObjs : [SELECT Id, Business_Event_Target_vod__c,Date_vod__c
        FROM Call_Objective_vod__c
        WHERE Completed_Flag_vod__c = FALSE AND
        RecordTypeId IN :recTypes.keySet() AND
        Business_Event_Target_vod__c IN :bets.keySet()])
        {
            for (Call_Objective_vod__c cObj : cObjs)
            {
                if (deletedIds.contains(cObj.Id) || cObj.Business_Event_Target_vod__c == null)
                {
                    continue;
                }
                Business_Event_Target_vod__c bet = bets.get(cObj.Business_Event_Target_vod__c);
                if (bet != null)
                {
                    if (bet.Next_Visit_Date_vod__c == null || bet.Next_Visit_Date_vod__c > cObj.Date_vod__c.date())
                    {
                        bet.Next_Visit_Date_vod__c = cObj.Date_vod__c.date();
                    }
                    bet.Remaining_Calls_vod__c++;
                }
            }
        }

        if (bets.size() > 0)
        {
            // update Business Event Target with the new remaining count and next visit date
            // and skip all triggers
            VEEVA_BUSINESS_EVENT_TARGET_TRIG.invoked = true;
            update(bets.values());
        }
    }

}