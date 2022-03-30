trigger VeevaUserTrigger on User (before insert, before update, before delete, after insert, after update) {
    VeevaTriggerHandler handler = new VeevaUserTriggerHandler();
    handler.handleTrigger();
}