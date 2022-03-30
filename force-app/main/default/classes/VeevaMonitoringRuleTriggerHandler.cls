public without sharing class VeevaMonitoringRuleTriggerHandler {
    
    public VeevaMonitoringRuleTriggerHandler()
    { 
    }
    
    public void OnBeforeInsert(List<Monitoring_Rule_vod__c> newMonitoringRules)
    {
        VeevaMonitoringRuleActions.validateInitialValues(newMonitoringRules);
    }
    
    public void OnBeforeUpdate(List<Monitoring_Rule_vod__c> newMonitoringRules, List<Monitoring_Rule_vod__c> oldMonitoringRules, Map<ID, Monitoring_Rule_vod__c> newMonitoringRuleMap, Map<ID, Monitoring_Rule_vod__c> oldMonitoringRuleMap)
    {
		VeevaMonitoringRuleActions.validateUpdatedValues(newMonitoringRules, oldMonitoringRules, newMonitoringRuleMap, oldMonitoringRuleMap);        
    }

}