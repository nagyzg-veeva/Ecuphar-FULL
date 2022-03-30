trigger VeevaAccountTeamMemberTrigger on Account_Team_Member_vod__c (before insert, before update, before delete, after insert, after update, after delete) {

    VeevaAccountTeamMemberTriggerHandler handler = new VeevaAccountTeamMemberTriggerHandler();

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
            handler.onBeforeDelete(trigger.Old);
        } else{
            handler.onAfterDelete(trigger.Old, Trigger.OldMap);
        }
    }

}