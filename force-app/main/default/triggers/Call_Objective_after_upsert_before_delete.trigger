trigger Call_Objective_after_upsert_before_delete on Call_Objective_vod__c (after insert, after update, before delete) {

    // Veeva Call Objective trigger that only contains old rollup logic. This trigger should be disabled if using new rollup.

    // Start count percentage of Call Objectives progress

    Set<Id> delIds = new Set<Id>();
    Call_Objective_vod__c [] cRow = null;
    if (Trigger.isDelete)
    {
        cRow = Trigger.old;
        for (Integer idx = 0; idx < Trigger.size; idx++)
        {
            delIds.Add(Trigger.old[idx].Id);
        }
    }
    else {
        cRow = Trigger.new;
    }

    List<String> parentATids = new List <String> ();
    for (Integer i = 0; i < cRow.size (); i++ ) {
        if (Trigger.isInsert || Trigger.isDelete || VEEVA_CALL_OBJECTIVE_TRIG.objectivesToRollup.remove(cRow[i].Id)) {
            parentATids.add(cRow[i].Account_Tactic_vod__c);
        }
    }

    if (parentATids.isEmpty()) {
        return;
    }

    Map<Id, Account_tactic_vod__c> acctTactics = new Map<Id, Account_tactic_vod__c>(
    [select Id, Progress_Type_vod__c, Completed_Call_Objectives_vod__c, Total_Call_Objectives_vod__c
            ,Call_Objective_Progress_vod__c, Status_vod__c from Account_Tactic_vod__c where Id in :parentATids and (Progress_Type_vod__c = 'Call_Objective_vod' or Progress_Type_vod__c = null)]);
    Map<Id, List<Call_Objective_vod__c>> atCOMappings = new Map<Id, List<Call_Objective_vod__c>>();

    if(acctTactics.size() > 0)
    {
        try
        {
            for (Call_Objective_vod__c cObj : [select Id, Account_Tactic_vod__c,Completed_Flag_vod__c
            from Call_Objective_vod__c
            where Account_Tactic_vod__c in :acctTactics.keySet()])
            {
                if(atCOMappings.containsKey(cObj.Account_Tactic_vod__c) == false)
                    atCOMappings.put(cObj.Account_Tactic_vod__c, new List<Call_objective_vod__c>());

                atCOMappings.get(cObj.Account_Tactic_vod__c).Add(cobj);
            }

            for(Account_Tactic_vod__c at : acctTactics.values())
            {
                if(atCOMappings.containsKey(at.Id))
                {
                    Integer completedCO = 0;
                    Integer allCO = 0;
                    for(Call_Objective_vod__c co : atCOMappings.get(at.Id))
                    {
                        if (delIds.contains(co.Id))
                        {
                            continue;
                        }
                        if(co.Completed_Flag_vod__c == true)
                        {
                            completedCO++;
                        }
                        allCO++;
                    }
                    at.Completed_Call_Objectives_vod__c = completedCO ;
                    at.Total_Call_Objectives_vod__c = allCO;
                    if(at.Total_Call_Objectives_vod__c > 0)
                    {
                        at.Call_Objective_Progress_vod__c = (at.Completed_Call_Objectives_vod__c / at.Total_Call_Objectives_vod__c) * 100;
                        if(at.Call_Objective_Progress_vod__c == 100)
                            at.Status_vod__c = 'Completed_vod';
                        else
                                at.Status_vod__c = 'Pending_vod';
                    }
                }
            }
            update(acctTactics.values());
        }
        catch( Exception e ) {
            System.debug('Call_Objective_after_upsert_before_delete: exception');
        }
    }
}