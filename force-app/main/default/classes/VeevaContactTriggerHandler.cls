public without sharing class VeevaContactTriggerHandler extends VeevaTriggerHandler {

    private List<Contact> newContacts = new List<Contact>();
    private List<Contact> oldContacts = new List<Contact>();
    private Map<ID, Contact> newContactsMap = new Map<ID, Contact>();
    private Map<ID, Contact> oldContactsMap = new Map<ID, Contact>();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newContacts = (List<Contact>) triggerNew;
        this.oldContacts = (List<Contact>) triggerOld;
        this.newContactsMap = (Map<ID, Contact>) triggerNewMap;
        this.oldContactsMap = (Map<ID, Contact>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Contact';
    }

    protected override void beforeInsert() {
        VeevaCountryHelper.updateCountryFields(Contact.getSObjectType(), Contact.OwnerId, null, false, newContacts, oldContacts);
    }
    
    protected override void beforeUpdate() {
        VeevaCountryHelper.updateCountryFields(Contact.getSObjectType(), Contact.OwnerId, null, true, newContacts, oldContacts);
    }
}