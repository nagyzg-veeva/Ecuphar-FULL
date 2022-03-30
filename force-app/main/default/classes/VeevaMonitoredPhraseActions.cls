public without sharing class VeevaMonitoredPhraseActions {
    // Note that the class specifies without sharing because it is used from within the context of VeevaMonitoredPhraseTriggerHandler which as the name specifies, run as part of a trigger.
    // If this class is to be used elsewhere, update sharing, add appropriate field access checks and this comment appropriately.

    private static final String defaultDuplicatePhraseErrorFormat = 'This monitored phrase already exists for this monitoring rule here: {0}.';

	public static void validateUniquePhrases(List<Monitored_Phrase_vod__c> monitoredPhrases)
    {
        Set<Id> monitoringRuleIds = new Set<Id>();
        Set<String> phraseTextValues = new Set<String>();
        Map<Id, Map<String, Id>> ruleToPhraseMap = new Map<Id, Map<String, Id>>(); // Maps rule id to a map of phrase text to phrase id
        Map<Monitored_Phrase_vod__c, Id> phraseToExistingDuplicatePhraseMap = new Map<Monitored_Phrase_vod__c, Id>();
        String locale = UserInfo.getLocale();

        // Get the set of all monitoring rules and phrases that need to be checked
        for (Monitored_Phrase_vod__c phrase : monitoredPhrases) {
            monitoringRuleIds.add(phrase.Monitoring_Rule_vod__c);
            if (phraseTextValues.contains(phrase.Phrase_vod__c.toLowerCase(locale))) {
                // We have a local duplicate we're trying to update/create
                phraseToExistingDuplicatePhraseMap.put(phrase, null);
            } else {
                phraseTextValues.add(phrase.Phrase_vod__c.toLowerCase(locale));
            }
        }


        // Check for duplicates among existing monitored phrases
        for (Monitored_Phrase_vod__c existingPhrase : [SELECT Id, Monitoring_Rule_vod__c, Phrase_vod__c FROM Monitored_Phrase_vod__c WHERE Monitoring_Rule_vod__c IN :monitoringRuleIds AND Phrase_vod__c IN :phraseTextValues]) {
            // Find potential duplicate for the phrase
            for (Monitored_Phrase_vod__c phrase : monitoredPhrases) {
                if (!existingPhrase.Id.equals(phrase.Id) && existingPhrase.Monitoring_Rule_vod__c.equals(phrase.Monitoring_Rule_vod__c) && existingPhrase.Phrase_vod__c.equalsIgnoreCase(phrase.Phrase_vod__c)) {
                    phraseToExistingDuplicatePhraseMap.put(phrase, existingPhrase.Id);
                    continue;
                }
            }
        }

        if (!phraseToExistingDuplicatePhraseMap.isEmpty()) {
        	String duplicatePhraseErrorFormat = VOD_GET_ERROR_MSG.getErrorMsgWithDefault('APPROVED_NOTES_DUPLICATE_MONITORED_PHRASE_ERROR', 'ApprovedNotes', defaultDuplicatePhraseErrorFormat);

            // Add the error to each duplicate monitored phrase
            Set<Monitored_Phrase_vod__c> duplicatePhraseSet = phraseToExistingDuplicatePhraseMap.keySet();
            for (Monitored_Phrase_vod__c phrase : duplicatePhraseSet) {
                List<Object> errorParams = new List<Object> { phraseToExistingDuplicatePhraseMap.get(phrase) };
                phrase.addError(String.format(duplicatePhraseErrorFormat, errorParams));
            }
        }
    }

    public static void validateUpdatedPhrasesUnique(List<Monitored_Phrase_vod__c> newMonitoredPhrases, Map<ID, Monitored_Phrase_vod__c> oldMonitoredPhraseMap) {

		List<Monitored_Phrase_vod__c> phrasesWithModifiedText = new List<Monitored_Phrase_vod__c>();

        for (Monitored_Phrase_vod__c updatedPhrase : newMonitoredPhrases) {
            Monitored_Phrase_vod__c oldPhraseValues = oldMonitoredPhraseMap.get(updatedPhrase.Id);
            if (!updatedPhrase.Phrase_vod__c.equalsIgnoreCase(oldPhraseValues.Phrase_vod__c)) {
                // Phrase changed, should add to list of phrasesWithModifiedText for evaluation of duplicates
                phrasesWithModifiedText.add(updatedPhrase);
            }
        }

        validateUniquePhrases(phrasesWithModifiedText);
    }
}