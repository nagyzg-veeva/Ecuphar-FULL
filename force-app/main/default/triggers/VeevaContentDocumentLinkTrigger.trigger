trigger VeevaContentDocumentLinkTrigger on ContentDocumentLink (before delete, after insert) {
    new VeevaContentDocumentLinkTriggerHandler().handleTrigger();
}