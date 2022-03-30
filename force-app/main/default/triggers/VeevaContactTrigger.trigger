trigger VeevaContactTrigger on Contact (before insert, before update, before delete, after insert, after update) {
    VeevaTriggerHandler handler = new VeevaContactTriggerHandler();
    handler.handleTrigger();
}