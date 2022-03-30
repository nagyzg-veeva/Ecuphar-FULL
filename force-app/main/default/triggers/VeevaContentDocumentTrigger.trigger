trigger VeevaContentDocumentTrigger on ContentDocument (before delete, before update) {
    new VeevaContentDocumentTriggerHandler().handleTrigger();
}