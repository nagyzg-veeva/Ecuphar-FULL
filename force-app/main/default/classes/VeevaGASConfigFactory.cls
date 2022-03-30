public inherited sharing class VeevaGASConfigFactory {

    public static VeevaGASConfigBase getGASConfigForPlatform(String platform) {
        VeevaGASConfigBase veevaGASConfig;
        if (platform == 'Mobile'){
            veevaGASConfig = new VeevaGASConfigMobile();
        } else {            
            veevaGASConfig = new VeevaGASConfigOnline();
        }
        return veevaGASConfig;
    }
}