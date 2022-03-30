trigger VeevaCallObjectiveTrigger on Call_Objective_vod__c (before insert, before update, before delete, after insert, after update, after delete) {
    VeevaCallObjectiveTriggerHandler handler = new VeevaCallObjectiveTriggerHandler();

    if( Trigger.isInsert) {
        if(Trigger.isBefore) {
            handler.OnBeforeInsert(trigger.New);
        } else{
            handler.OnAfterInsert(trigger.New);
        }
    }
    else if ( Trigger.isUpdate ) {
        if(Trigger.isBefore) {
            handler.OnBeforeUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap);
        } else {
            handler.OnAfterUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap);
        }
    } else {
        // delete event
        if (Trigger.isBefore) {
            handler.OnBeforeDelete(trigger.Old, Trigger.OldMap);
        } else {
            handler.OnAfterDelete(trigger.Old, Trigger.OldMap);
        }
    }

}