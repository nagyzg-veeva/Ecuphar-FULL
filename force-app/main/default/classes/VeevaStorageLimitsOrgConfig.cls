public class VeevaStorageLimitsOrgConfig implements VeevaOrgConfig{
	public Object getOrgConfiguration(){
        Map<String,System.OrgLimit> limitsMap = OrgLimits.getMap();
        DataStorage data = new DataStorage();
        System.OrgLimit apiRequestsLimit = limitsMap.get('DataStorageMB');

        data.currentUsage = apiRequestsLimit.getValue();
        data.maxLimit = apiRequestsLimit.getLimit();
        return data;
    }
    


}