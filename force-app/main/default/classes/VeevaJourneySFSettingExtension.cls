public class VeevaJourneySFSettingExtension {
    public VeevaJourneySFSettingExtension() { }

    public VeevaJourneySFSettingExtension(ApexPages.StandardController stdController) { }

    public String getSfEndpoint() {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/44.0/' +
               UserInfo.getOrganizationId();
    }

    public String getAndiDomain() {
        // not using profile
        return Veeva_Common_vod__c.getValues('Main').Andi_Server_vod__c;
    }

    public String getAndiWidgetURL() {
        // not using profile
        return Veeva_Common_vod__c.getValues('Main').Andi_Widget_URL_vod__c;
    }
}