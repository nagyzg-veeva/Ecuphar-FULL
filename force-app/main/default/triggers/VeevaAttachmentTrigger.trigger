trigger VeevaAttachmentTrigger on Attachment (before delete) {
    new VeevaAttachmentTriggerHandler().handleTrigger();
}