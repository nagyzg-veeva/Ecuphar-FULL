public with sharing class VeevaWiredWrapperParams {
    @AuraEnabled
    public List<String> queryParams { get; set; }
    @AuraEnabled
    public String childObject { get; set; }
    @AuraEnabled
    public String objectId { get; set; }
    @AuraEnabled
    public String referenceFieldName {get; set; }
}