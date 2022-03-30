public abstract class TerritoryManagement {
    public static DescribeSObjectResult TERRITORY_DESCR;
	
	protected Map<String, String> TERRITORY_MAP = new Map<String, String> {
        'TerritoryId' => 'territoryId',
        'Territory2Id' => 'territoryId',
        'ParentTerritoryId' => 'ParentTerritoryId',
        'ParentTerritory2Id' => 'ParentTerritoryId'
    };
	
	public Map<Id, Map<String, String>> extractSObject(List<SObject> sObjects) {
        Map<Id, Map<String, String>> result = new Map<Id, Map<String, String>>();
        for (SObject sObj: sObjects) {
            Set<String> fields = sObj.getPopulatedFieldsAsMap().keySet();
            Map<String, String> data = new Map<String, String>();
            for (String field: fields) {
                String key = TERRITORY_MAP.containsKey(field) ? TERRITORY_MAP.get(field) : field;
                data.put(key, (String) sObj.get(field));
            }
            result.put((Id) sObj.get('Id'), data);
        }

        return result;
    }
    
    public String getLabelForTerritoryObject(){
		return getTerritoryDescribe().getLabelPlural();
	}
    
    // For territory only
    public abstract DescribeSObjectResult getTerritoryDescribe();
    public abstract List<String> getTerritoryNames(Set<Id> ids);
    public abstract Map<Id, Map<String, String>> getTerritories();
    public abstract Map<Id, Map<String, String>> getTerritories(Set<Id> territoryIds);
    public abstract Map<Id, Map<String, String>> getTerritoriesByNames(List<String> names);
    public abstract Map<Id, Map<String, String>> getTerritoriesMap();

    // For user territory
    public abstract Set<Id> getUserTerritories(Id userId);
    public abstract Map<Id, Map<String, String>> getUserTerritories(Set<Id> userIds, Set<Id> territoryIds);

    // for accountshare territory
    public List<AccountShare> getAccounts(Set<Id> accountIds, Boolean includeTerrAssignRule) {
        Set<String> rowCauses = new Set<String>{'TerritoryManual', 'Territory2AssociationManual'};
        if (includeTerrAssignRule) {
            rowCauses.add('Territory');
        }

        return (List<AccountShare>) Database.query('Select Id, AccountId, UserOrGroupId From AccountShare Where AccountId In :accountIds And RowCause In :rowCauses');
    }

    // Get parent territory ids by territory id
    public Set<Id> getParentIdsByTerritoryId(Id id, Map<Id, Map<String, String>> territoriesMap) {
        Set<Id> parentTerritorySet = new Set<Id>();
        
        Map<String, String> territoryMap = territoriesMap.get(id);
        Id parentTerritoryId = territoryMap.get('ParentTerritoryId');
        if(parentTerritoryId != null) {
            Boolean result = parentTerritorySet.add(parentTerritoryId);
            if(result) {
                parentTerritorySet.addAll(getParentIdsByTerritoryId(parentTerritoryId, territoriesMap));
            }
        }
        
        return parentTerritorySet;
    }
    
    // Get parent territory ids by territory id set
    public Set<Id> getParentIdsByTerritorySet(Set<Id> territoryIds) {
        Set<Id> parentTerritoryIds = new Set<Id>();
        Map<Id, Map<String, String>> territoriesMap = getTerritoriesMap();
        
        if(!territoriesMap.isEmpty()){
            for (Id id : territoryIds) {
                parentTerritoryIds.addAll(getParentIdsByTerritoryId(id, territoriesMap));
            }
        }
    
        return parentTerritoryIds;
    }

}