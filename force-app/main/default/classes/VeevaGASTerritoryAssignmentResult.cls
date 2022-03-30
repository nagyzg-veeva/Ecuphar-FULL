public inherited sharing class VeevaGASTerritoryAssignmentResult {

    @AuraEnabled
    public boolean success { get; private set; }

    @AuraEnabled
    public String errorMessage { get; private set; }

    public VeevaGASTerritoryAssignmentResult(boolean success, String errorMessage) {
        this.success = success;
        this.errorMessage = errorMessage;
    }
}