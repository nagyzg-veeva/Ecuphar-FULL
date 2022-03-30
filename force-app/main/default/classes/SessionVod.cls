public with sharing class SessionVod {
	@AuraEnabled(cacheable=true)
	public static Map<String, String> getVodInfo() {
		Map<String, String> result = new Map<String, String>();
		Organization org = [SELECT isSandbox FROM Organization];
		String isSandbox = org.isSandbox ? 'true' : 'false';
		result.put('veevaServer', VOD_Common.VOD_URL);
		result.put('veevaVersion', VOD_Common.VOD_VERSION);
		result.put('mcServer', VOD_Common.MC_SERVER);
		result.put('mcVersion', VOD_Common.MC_CONTEXT_ROOT);
		result.put('sfSession', getSessionId());
		result.put('sfEndpoint', URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/48.0/' + UserInfo.getOrganizationId());
		result.put('orgId', UserInfo.getOrganizationId());
		result.put('isSandbox', isSandbox);
		return result;
	}

	public static String getSessionId() {
        PageReference sessionPage = Page.SessionLgtnVod;
        String vfContent = sessionpage.getContent().toString();
        Integer startP = vfContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length();
        Integer endP = vfContent.indexOf('End_Of_Session_Id');
        return vfContent.substring(startP, endP);
    }
}