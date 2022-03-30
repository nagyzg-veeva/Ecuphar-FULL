public without sharing class VeevaStakeholderNavigatorNode {
    @AuraEnabled public SObject account { get; private set; }
    @AuraEnabled public List<String> territories { get; private set; }

    public VeevaStakeholderNavigatorNode(SObject account, Set<String> territories) {
        this.account = account;
        this.territories = new List<String>(territories);
    }

    public VeevaStakeholderNavigatorNode() {}
}