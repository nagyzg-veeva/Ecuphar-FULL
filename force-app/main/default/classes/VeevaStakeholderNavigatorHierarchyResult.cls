public with sharing class VeevaStakeholderNavigatorHierarchyResult {
    @AuraEnabled public Map<Id, Set<Id>> hierarchy { get; set; }
    @AuraEnabled public Set<Id> rootAccounts { get; set; }
    @AuraEnabled public Integer queryResultCount { get; set; }
    @AuraEnabled public Boolean queryLimitTriggered { get; set; }
    @AuraEnabled public Boolean rootHasUnloadedParent { get; set; }
    @AuraEnabled public Id newGraphRoot { get; set; }
    @AuraEnabled public Integer depth { get; set; }

    public VeevaStakeholderNavigatorHierarchyResult(Map<ID, Set<Id>> hierarchy,
                                               Set<Id> rootAccounts,
                                               Integer queryResultCount,
                                               Boolean queryLimitTriggered,
                                               Integer depth) {
        this.hierarchy = hierarchy;
        this.rootAccounts = rootAccounts;
        this.queryResultCount = queryResultCount;
        this.queryLimitTriggered = queryLimitTriggered;
        this.depth = depth;
    }

    public void setNewRoot(Id newRoot) {
        this.newGraphRoot = newRoot;
    }

    public void setRootHasUnloadedParent(Boolean hasUnloadedParent) {
        this.rootHasUnloadedParent = hasUnloadedParent;
    }

    public VeevaStakeholderNavigatorHierarchyResult() {

    }
}