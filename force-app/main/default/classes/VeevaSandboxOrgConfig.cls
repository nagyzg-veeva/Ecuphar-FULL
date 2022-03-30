public without sharing class VeevaSandboxOrgConfig implements VeevaOrgConfig{

    public Object getOrgConfiguration(){
        organization org = [Select isSandbox from organization limit 1];
        return org.IsSandbox;
    }

}