public without sharing class VeevaMonitoredPhraseTriggerHandler {
	
    public VeevaMonitoredPhraseTriggerHandler()
    {
    }

    public void OnBeforeInsert(List<Monitored_Phrase_vod__c> newMonitoredPhrases)
    {
        VeevaMonitoredPhraseActions.validateUniquePhrases(newMonitoredPhrases);
    }
    
    public void OnBeforeUpdate(List<Monitored_Phrase_vod__c> newMonitoredPhrases, Map<ID, Monitored_Phrase_vod__c> oldMonitoredPhraseMap)
    {
        VeevaMonitoredPhraseActions.validateUpdatedPhrasesUnique(newMonitoredPhrases, oldMonitoredPhraseMap);
    }        
}