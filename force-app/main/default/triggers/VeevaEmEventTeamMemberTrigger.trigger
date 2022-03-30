trigger VeevaEmEventTeamMemberTrigger on EM_Event_Team_Member_vod__c (before insert, before update, before delete, after insert, after update, after delete) {
    VeevaTriggerHandler handler = new VeevaEmEventTeamMemberTriggerHandler();
    handler.handleTrigger();
}