@RestResource(urlMapping='/account/browse/*')
global without sharing class VeevaAccountBrowse {
    private static final String CHILD_ACCOUNTS = 'child_accounts';
    private static final String AFFILIATIONS = 'affiliations';

    private class UnsupportedTypeParameterException extends Exception {}

    @HttpGet
    global static sObject[] browse() {
        RestRequest request = RestContext.request;
        String id = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);

        String type = request.params.get('type');

        if(type.equalsIgnoreCase(VeevaAccountBrowse.CHILD_ACCOUNTS)) {
            return VeevaChildAccountBrowse.browse(id);
        } else if(VeevaAccountBrowse.AFFILIATIONS.equalsIgnoreCase(type)) {
            return VeevaAffiliationAccountBrowse.browse(id);
        } else {
            throw new UnsupportedTypeParameterException('Unsupported type parameter');
        }
    }
}