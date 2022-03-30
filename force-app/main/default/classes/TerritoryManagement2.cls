public class TerritoryManagement2 extends TerritoryManagement {
	public override DescribeSObjectResult getTerritoryDescribe() {
        if (TERRITORY_DESCR == null) {
            TERRITORY_DESCR = ((SObject)(Type.forName('Territory2').newInstance())).getSObjectType().getDescribe();
        }
        return TERRITORY_DESCR;
    }

    public override List<String> getTerritoryNames(Set<Id> ids) {
        List<String> result = new List<String>();
        for (SObject terr : Database.query('SELECT Name FROM Territory2 WHERE Id IN :ids ORDER BY Name'))
        {
            result.add((String)(terr.get('Name')));
        }
        return result;
    }

    public override Map<Id, Map<String, String>> getTerritories() {
        List<SObject> sObjects  =  Database.query('SELECT Id, Name FROM Territory2 WHERE Name LIKE \'%(%)%\' AND Territory2ModelId IN (select Id from Territory2Model where State=\'Active\')');
        return extractSObject(sObjects);
    }

    public override Map<Id, Map<String, String>> getTerritories(Set<Id> territoryIds) {
         Map<Id, Map<String, String>> result = new Map<Id, Map<String, String>>();
        if (territoryIds != null && territoryIds.size() > 0) {
            List<SObject> sObjects  = Database.query('Select Id,Name,Description From Territory2 Where Id In :territoryIds AND Territory2ModelId IN (select Id from Territory2Model where State=\'Active\')');
            result = extractSObject(sObjects);
        }

        return result;
    }

    public override Map<Id, Map<String, String>> getTerritoriesByNames(List<String> names) {
        Map<Id, Map<String, String>> result = new Map<Id, Map<String, String>>();
        if (names != null && names.size() > 0) {
            List<SObject> sObjects = Database.query('Select Id, AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, OpportunityAccessLevel,Name From Territory2 where Name in :names AND Territory2ModelId IN (select Id from Territory2Model where State=\'Active\')');
            result =  extractSObject(sObjects); 
        }

        return result;
    }
    
    public override Set<Id> getUserTerritories(Id userId) {
        Set<Id> result = new Set<Id>();
        for (SObject terr : Database.query('SELECT Territory2Id from UserTerritory2Association where UserId = :userId AND IsActive = true')) {
            result.add((Id)(terr.get('Territory2Id')));
        }
        return result;
    }

    public override Map<Id, Map<String, String>> getUserTerritories(Set<Id> userIds, Set<Id> territoryIds) {

        if ((userIds == null || userIds.isEmpty()) && (territoryIds == null || territoryIds.isEmpty())) {
            return new Map<Id, Map<String, String>>();
        }

        String whereClause = ' Where ';

        if (userIds != null && userIds.size() > 0) {
            whereClause += 'UserId In :userIds';
        }

        if (territoryIds != null && territoryIds.size() > 0) {
            if (whereClause.contains('UserId')) {
                whereClause += ' And ';
            }
            whereClause += 'Territory2Id in :territoryIds';
        }

        List<SObject> sObjects = Database.query('Select Id, UserId, Territory2Id From UserTerritory2Association ' + whereClause + ' And IsActive = true');

        return extractSObject(sObjects);
    }


    public Map<Id, Map<Id,Map<String, String>>> getObjectTerritory2Association(Set<Id> accIds) {
    	Map<Id, Map<Id, Map<String, String>>> objTer2AssociationByObjId = new Map<Id, Map<Id,Map<String, String>>>();
    	 String whereClause = ' Where ';
    	 whereClause += ' AssociationCause  =\'Territory2Manual\'' ;
    	 if (accIds != null && accIds.size() > 0) {
    	 	whereClause += ' AND ObjectId In :accIds';
    	 }

    	List<SObject> sObjects = Database.query('SELECT Id, ObjectId,Territory2Id From ObjectTerritory2Association' + whereClause ) ;
    	for (SObject sObj : sObjects) {
    		Set<String> fields = sObj.getPopulatedFieldsAsMap().keySet();
            Map<String, String> data = new Map<String, String>();
            for (String field: fields) {                
                data.put(field, (String) sObj.get(field));
            }

            String accId = data.get('ObjectId');
    		String ter2Id = data.get('Territory2Id');

    		Map<Id,Map<String, String>> associationsByTer2Id = objTer2AssociationByObjId.get(accId);
    		if (associationsByTer2Id == null ) {
    			objTer2AssociationByObjId.put((Id)accId, new Map<Id, Map<String, String>>());
    		}
    		objTer2AssociationByObjId.get(accId).put((Id)ter2Id, data);

    	}
    	return objTer2AssociationByObjId;

    }

    public override Map<Id, Map<String, String>> getTerritoriesMap() {
        List<SObject> sObjects = Database.query('SELECT Id, Name, ParentTerritory2Id FROM Territory2');
        return extractSObject(sObjects);
    }
}