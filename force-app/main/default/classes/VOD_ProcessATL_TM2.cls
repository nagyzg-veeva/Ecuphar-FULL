public class VOD_ProcessATL_TM2 {
	/**
	 This class is used to process ATL in Territory 2 Environment( Territory 2 is enabled)
	*/
    Schema.SObjectType acctTerAssoObjType = Schema.getGlobalDescribe().get('ObjectTerritory2Association');

    public  void processATL_TM2(List<Account_Territory_Loader_vod__c> acctLoaders, Set<Id> accIds, Map<String, Map<String, String>> allTerritoryByName, boolean extendATLMode) {
    	
	      List<Map<Id,Map<String, String>>> allAccTer2Associations = new List<Map<Id,Map<String, String>>>();
	      Map<Id, Map<Id,Map<String, String>>> accTer2Associations = ((TerritoryManagement2)TerritoryManagementFactory.getInstance()).getObjectTerritory2Association(accIds);      
	      allAccTer2Associations = accTer2Associations.values();
	       
	      if (extendAtlMode) {                      
	            processAddDropTerritoriesExtendATL_True(acctLoaders, accTer2Associations, allTerritoryByName);            
	      } else {        
	            processAssociationsExtendATL_False(acctLoaders, allTerritoryByName, allAccTer2Associations);
	      }
    }
    
    private void processAddDropTerritoriesExtendATL_True(List<Account_Territory_Loader_vod__c> acctLoaders, Map<Id, Map<Id,Map<String, String>>> accTer2Associations,  Map<String, Map<String, String>> allTerritoryByName) {
    	
    	Schema.SObjectType objTerAssoObjType = Schema.getGlobalDescribe().get('ObjectTerritory2Association');
    	List<SObject> addAccToTerAssociations = new List<SObject>();
        List<Id> delAccToTerAssociations = new List<Id>();
        
    	for (Account_Territory_Loader_vod__c acc : acctLoaders) {
               
               // Drop Territory Processing	
                if (String.isNotEmpty(acc.Territory_To_Drop_vod__c)) {
                	
                    Map<Id,Map<String, String>> existingAssociations = accTer2Associations.get(acc.Account_vod__c);
                    if (existingAssociations == null) {
                        continue;
                    }
                    
                    Set<String> uniqueSplits = new Set<String>();
                    String[] dropTerritories = acc.Territory_To_Drop_vod__c.split(';');
                
                    uniqueSplits.addAll(dropTerritories);
                    uniqueSplits.remove('');
                    for (String terrValue : uniqueSplits) {
                        Map<String,String> terr = getTerritoryByName(terrValue, allTerritoryByName);
                        // System.debug('Terr found to delete' + terr + '::'+terrValue + ' allTerritoryByName:' + allTerritoryByName);
                        if (terr == null) {
                            continue;
                        }
                        // System.debug('ExistingAssociations delete flow:'+ existingAssociations + ' for terrId:' + terr.get('Id'));
                        Map<String, String> isAssociationExitsForThisTer = existingAssociations.get(terr.get('Id'));
                        // System.debug('Association to delete:'+ isAssociationExitsForThisTer);
                        if (isAssociationExitsForThisTer != null) {
                            delAccToTerAssociations.add(isAssociationExitsForThisTer.get('Id'));
                            if (delAccToTerAssociations.size() == 1000) {
                                Database.delete(delAccToTerAssociations, false);                                    
                                delAccToTerAssociations.clear();
                            }
                        }
                    }                    
                }    
       }
       
       if (!delAccToTerAssociations.isEmpty()) {
           // System.debug('Deleting OTA now' + delAccToTerAssociations);
           Database.delete(delAccToTerAssociations, false);       
       }
        
       // add territory processing 
       addNewAssociations(acctLoaders, allTerritoryByName, true);            
	}
	
        
   private void processAssociationsExtendATL_False(List<Account_Territory_Loader_vod__c> acctLoaders, Map<String, Map<String, String>> allTerritoryByName, List<Map<Id,Map<String, String>>> allAccTer2Associations) {
	    
	    // First remove all existing association
	    removeExistingAssociations(allAccTer2Associations);
	    
	    // Now add associations
	    addNewAssociations(acctLoaders, allTerritoryByName, false );   		 
    }
                    
    private void addNewAssociations(List<Account_Territory_Loader_vod__c> acctLoaders, Map<String, Map<String, String>> allTerritoryByName, boolean extendATL) {
    	// ready to create ObjectTerritory2Association
	    List<SObject> addAccToTerAssociations = new List<SObject>();
	    
        for (Account_Territory_Loader_vod__c acc : acctLoaders) {
            if ((extendATL && String.isEmpty(acc.Territory_To_Add_vod__c)) || (!extendATL && String.isEmpty(acc.Territory_vod__c))) {
                continue;
            }
            
            String [] add_territories = new String[]{};
            if (extendATL) {
            	add_territories.addAll(acc.Territory_To_Add_vod__c.split(';'));
            }else {
                add_territories.addAll(acc.Territory_vod__c.split(';'));
            }
            	                
            Set<String> uniqueTerSplits = new Set<String>();
            uniqueTerSplits.addAll(add_territories);
            uniqueTerSplits.remove('');
                
            for (String terrValue : uniqueTerSplits) {
                Map<String, String>  terr = getTerritoryByName(terrValue, allTerritoryByName);
                // If we cant find the territory that was provieded move to the next entry.
                if (terr == null) {
                    System.debug ('Territory not found for = ' + terrValue);
                    continue;
                }                  
                //Since we are creating a manual assignment we read the important AccountShare settings
                //off the territory and assign them to the new row.                  
        	    SObject acctTerAssociation = getAssociationObject(terr.get('Id'), acc.Account_vod__c); 
                                                          
                // System.debug ('Adding ObjectTerritory2Association terId:' + terr.get('Id') + ', acctId:' + acc.Account_vod__c);
                addAccToTerAssociations.add(acctTerAssociation);
                
                if (addAccToTerAssociations.size() == 1000) {
                    Database.insert(addAccToTerAssociations, false);
                    addAccToTerAssociations.clear();
                }
            }            
        }
        
	    if (!addAccToTerAssociations.isEmpty()) {
	    	 //System.debug('Adding OTA now' + addAccToTerAssociations);	    	
	      	 Database.insert(addAccToTerAssociations, false);
		}                   
    }
    
    
	private void removeExistingAssociations(List<Map<Id,Map<String, String>>> allAccTer2Associations) {
    	List<Id> delAccToTerAssociations = new List<Id>();
    	
    	// If we are doing an update we need to clean out the account share rows.
        for (Map<Id,Map<String, String>> acctTer2Association : allAccTer2Associations) {
           Set<Id> keys = acctTer2Association.keySet();
           for (Id key:keys) {
           		String idVal = acctTer2Association.get(key).get('Id');
                delAccToTerAssociations.add((Id)idVal);           
           }
        }
        Database.delete( delAccToTerAssociations, false);
   }
   
   private SObject getAssociationObject(String terrId, String accId) {		
		SObject acctTerAssociation = acctTerAssoObjType.newSObject();
        acctTerAssociation.put('Territory2Id', terrId);
        acctTerAssociation.put('ObjectId', accId);
        acctTerAssociation.put('AssociationCause', 'Territory2Manual');
        return acctTerAssociation;
   }
	
   private Map<String, String> getTerritoryByName(String territoryName, Map<String, Map<String, String>> allTerritoryByName) {        
        return allTerritoryByName.get(territoryName);            
   }
}