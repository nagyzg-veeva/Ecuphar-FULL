public with sharing class VeevaStakeholderNavigatorInitData {
    @AuraEnabled public Id graphRootId { get; private set; }
    @AuraEnabled public List<Id> keyStakeholders { get; private set; }
    @AuraEnabled public Map<String, String> veevaMessages { get; private set; }
    @AuraEnabled public Map<String, Map<String, String>> labelTranslations { get; private set; }
    @AuraEnabled public Map<String, Map<String, String>> picklistTranslations { get; private set; }

    public VeevaStakeholderNavigatorInitData(Id graphRootId, 
                                           List<Id> keyStakeholders, 
                                           Map<String, String> veevaMessages,
                                           Map<String, Map<String, String>> labelTranslations,
                                           Map<String, Map<String, String>> picklistTranslations) {
        this.graphRootId = graphRootId;
        this.keyStakeholders = keyStakeholders;
        this.veevaMessages = veevaMessages;
        this.labelTranslations = labelTranslations;
        this.picklistTranslations = picklistTranslations;
    }

    public VeevaStakeholderNavigatorInitData() {}
}