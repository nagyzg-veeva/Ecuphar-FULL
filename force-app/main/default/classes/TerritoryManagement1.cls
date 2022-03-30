public class TerritoryManagement1 extends TerritoryManagement {	
    public override DescribeSObjectResult getTerritoryDescribe() {
        if (TERRITORY_DESCR == null) {
            TERRITORY_DESCR = ((SObject)(Type.forName('Territory').newInstance())).getSObjectType().getDescribe();
        }
        return TERRITORY_DESCR;
    }
	
    public override List<String> getTerritoryNames(Set<Id> ids) {
        List<String> result = new List<String>();
        for (SObject terr : Database.query('SELECT Name FROM Territory WHERE Id IN :ids ORDER BY Name'))
        {
            result.add((String)(terr.get('Name')));
        }
        return result;
    }

    public override Map<Id, Map<String, String>> getTerritories() {
        List<SObject> sObjects = Database.query('SELECT Id, Name FROM Territory WHERE Name LIKE \'%(%)%\'');
        return extractSObject(sObjects);
    }

    public override Map<Id, Map<String, String>> getTerritories(Set<Id> territoryIds) {
        Map<Id, Map<String, String>> result = new Map<Id, Map<String, String>>();
        if (territoryIds != null && territoryIds.size() > 0) {
            List<SObject> sObjects = Database.query('Select Id, Name, Description From Territory Where Id In :territoryIds');
            result = extractSObject(sObjects);
        }

        return result;
    }

    public override Map<Id, Map<String, String>> getTerritoriesByNames(List<String> names) {
        Map<Id, Map<String, String>> result = new Map<Id, Map<String, String>>();
        if (names != null && names.size() > 0) {
            List<SObject> sObjects = Database.query('Select Id, Name, AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, OpportunityAccessLevel From Territory where Name in :names');
            result = extractSObject(sObjects); 
        }
        return result; 
    }

    public override Set<Id> getUserTerritories(Id userId) { 
        Set<Id> result = new Set<Id>();
        for (SObject terr : Database.query('SELECT TerritoryId from UserTerritory where UserId = :userId AND IsActive = true')) {
            result.add((Id)(terr.get('TerritoryId')));
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
            whereClause += 'TerritoryId in :territoryIds';
        }

        List<SObject> sObjects = Database.query('Select Id, UserId, TerritoryId From UserTerritory' + whereClause + ' And IsActive = true');

        return extractSObject(sObjects);
    }
    
    public override Map<Id, Map<String, String>> getTerritoriesMap() {
        List<SObject> sObjects = Database.query('SELECT Id, Name, ParentTerritoryId FROM Territory');
        return extractSObject(sObjects);
    }
}