trigger VeevaActionItemTrigger on Action_Item_vod__c (before insert, before update, before delete, after insert, after update, after delete) {

    VeevaActionItemTriggerHandler handler = new VeevaActionItemTriggerHandler();
    
    if( Trigger.isInsert) {
        if(Trigger.isBefore) {
            handler.onBeforeInsert(trigger.New);
        } else{
            handler.onAfterInsert(trigger.New);
        }        
    }
    else if ( Trigger.isUpdate ) {
        if(Trigger.isBefore) {
            handler.onBeforeUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap);
        } else {
            handler.onAfterUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap);
        }        
    } else {
        // delete event
        if (Trigger.isBefore) {
            handler.onBeforeDelete(trigger.Old, Trigger.OldMap);
        } else {
            handler.onAfterDelete(trigger.Old, Trigger.OldMap);
        }
    }

}