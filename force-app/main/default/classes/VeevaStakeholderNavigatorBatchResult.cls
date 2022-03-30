public with sharing class VeevaStakeholderNavigatorBatchResult {
    @AuraEnabled public Id batchId { get; set; }
    @AuraEnabled public List<VeevaStakeholderNavigatorNode> accounts { get; set; }
    @AuraEnabled public List<SObject> affiliations { get; set; }
    @AuraEnabled public Boolean limitTriggered { get; set; }

    public VeevaStakeholderNavigatorBatchResult(Id batchId) {
        this.batchId = batchId;
        this.limitTriggered = false;
    }

    public void setLimitTriggered(Boolean limitTriggered) {
        this.limitTriggered = limitTriggered;
    }

    public void addAccounts(List<VeevaStakeholderNavigatorNode> accounts) {
        this.accounts = accounts;
    }

    public void addAffiliations(List<SObject> affiliations) {
        this.affiliations = affiliations;
    }

    public VeevaStakeholderNavigatorBatchResult() {}
}