trigger VeevaEmSpeakerTrigger on EM_Speaker_vod__c  (before insert, before update, before delete, after insert, after update, after delete) {
	VeevaTriggerHandler handler = new VeevaEmSpeakerTriggerHandler();
    handler.handleTrigger();
}