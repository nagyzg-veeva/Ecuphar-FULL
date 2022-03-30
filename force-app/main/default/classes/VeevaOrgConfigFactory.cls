public without sharing class VeevaOrgConfigFactory {

    public VeevaOrgConfig getOrgConfig(String featureName){
        VeevaOrgConfig config;
        if(string.isNotBlank(featureName)){
            switch on featureName {
    			when 'files' {
					return new VeevaFilesOrgConfig();
    			} when 'sandbox' {
                     return new VeevaSandboxOrgConfig();
                } when 'dataStorage' {
                    return new VeevaStorageLimitsOrgConfig();
                } when else {
					return null;
    			}
			}
        }
        return null;
    }
}