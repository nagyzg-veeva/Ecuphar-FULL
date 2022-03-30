public with sharing class VeevaGASUserAccess {

    // Allows classes that have 'without sharing' (or inherited 'without sharing') check if account ids are
    // accessible to the user
    public Set<Id> getUserAccessibleAccountIds(Set<Id> accountIds) {
        return new Map<Id, Account>([SELECT Id From Account WHERE Id In :accountIds]).keySet();
    }
}