trigger VeevaMedicalEventTrigger on Medical_Event_vod__c (before insert, before update, before delete, after insert, after update, after delete) {
	VeevaTriggerHandler handler = new VeevaMedicalEventTriggerHandler();
    handler.handleTrigger();
}