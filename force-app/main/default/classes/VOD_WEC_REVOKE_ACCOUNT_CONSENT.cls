@RestResource(urlMapping='/VodWecMultichannelConsent/*')
global without sharing class VOD_WEC_REVOKE_ACCOUNT_CONSENT {

    @HttpPost
    global static List<String> revoke(){
        List<String> results= new List<String>();
        RestRequest req = RestContext.request;
        String multichannelConsentId = req.params.get('multichannelConsentId');
        String userId = req.params.get('userId');

        List<Multichannel_Consent_vod__c> multichannelConsents = [SELECT RecordType.Id, Consent_Type_vod__c, Content_Type_vod__c, Account_vod__c From Multichannel_Consent_vod__c WHERE Id =:multichannelConsentId];

        Multichannel_Consent_vod__c multichannelConsent = null;
        if(multichannelConsents != null && multichannelConsents.size() > 0){
           multichannelConsent = multichannelConsents.get(0);
        }

        if(multichannelConsent != null){
           multichannelConsent.Opt_Expiration_Date_vod__c = Date.today();

           update multichannelConsent;
           results.add(multichannelConsentId);

           Multichannel_Consent_vod__c optOutMultichannelConsent = new Multichannel_Consent_vod__c();
           optOutMultichannelConsent.Account_vod__c = multichannelConsent.Account_vod__c;
           optOutMultichannelConsent.Capture_Datetime_vod__c = Datetime.now();
           optOutMultichannelConsent.RecordTypeId = multichannelConsent.RecordTypeId;
           optOutMultichannelConsent.Captured_By_vod__c = userId;
           optOutMultichannelConsent.Consent_Type_vod__c = multichannelConsent.Consent_Type_vod__c;
           optOutMultichannelConsent.Content_Type_vod__c = multichannelConsent.Content_Type_vod__c;
           optOutMultichannelConsent.Opt_Type_vod__c = 'Opt_Out_vod';
           insert optOutMultichannelConsent;
           results.add(optOutMultichannelConsent.id);
        }

       return results;
    }
}