public with sharing class FormularyForRepExtensionLgtnVod {

    ApexPages.StandardController m_controller;

    public FormularyForRepExtensionLgtnVod(ApexPages.StandardController controller) {
        m_controller = controller;
    }

    public String getMessages() {
        Map<String, String> messages = new Map<String, String>();
        messages.put('PrescriberOptOut', 'Sales Data for this Account cannot be viewed due to the PDRP Opt Out program.');
        for (Message_vod__c message : [SELECT Name, Text_vod__c FROM Message_vod__c WHERE Language_vod__c= :UserInfo.getLanguage() AND Category_vod__c='Analytics' AND Name IN ('PrescriberOptOut')]) {
            messages.put(message.Name, message.Text_vod__c.replace('\'', '&#39;'));
        }
        return JSON.serialize(messages);
    }

}