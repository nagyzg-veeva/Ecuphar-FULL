public class VOD_ProcessATL {
    
    public static final String ATL_TRACKING_FIELD = 'ATL_Last_Update_Date_Time_vod__c';    
    
    public static void processATL(List<Account_Territory_Loader_vod__c> acctLoaders, Set<Id> acctIds, boolean extendATLMode) {
    	
        List<Set<String>> allTerrNames = getTerritories(acctLoaders, extendATLMode);
 		boolean isTm2Enabled = TerritoryManagementFactory.isTM2();
        // use territory names to find out Territory and Group records        
        List<Map<Id, Map<String, String>>> allTerritories = new List<Map<Id, Map<String, String>>>();        
        List<Map<String, Map<String, String>>> allTerritoryByName = new List<Map<String, Map<String, String>>>();
        Map<String, Map<String, String>> allTerritoryByNameMap = new Map<String, Map<String, String>>();
        
        List<Map<String,Group>> allGroupsByRelated =  new List<Map<String,Group>> ();
        for (Set<String> names : allTerrNames) {            
            Map<Id, Map<String, String>> territories = TerritoryManagementFactory.getInstance().getTerritoriesByNames(new List<String>(names));
            if (territories.size() == 0)
                continue;
            allTerritories.add(territories);

            // Create a Map that is by territory name and not id,  makes it easier to lookup            
            Map<String, Map<String, String>> territoryByName = new Map<String,Map<String, String>> ();

            for (Map<String, String> terr : territories.values()) {
               territoryByName.put(terr.get('Name'), terr);
               allTerritoryByNameMap.put(terr.get('Name'), terr);
               
            }
            allTerritoryByName.add(territoryByName);

			if (!isTm2Enabled) {
	            // Grab a list of the groups for the territories that we are using.
	            // We only grab the group ids for 'TerritoryAndSubordinates' so that we can make manual assignements.
	            // To grab the "Territory" group would cause a "TerritoryManual" assignment.  If you change this then you need to
	            // Change the query on AccountShare for deletes from Manual to TerritroyManual.
	            //Map<Id,Group> groups = new Map<Id,Group>([Select Id, RelatedId from Group where Type = 'TerritoryAndSubordinates' and RelatedId in :territories.keySet()]);
	            Map<Id,Group> groups = new Map<Id,Group>([Select Id, RelatedId from Group where Type = 'Territory' and RelatedId in :territories.keySet()]);
	            if (groups.size() == 0)
	                continue;
	
	           //Make a map of groups by territory id so that it is easier to lookup
	           Map<String, Group> groupsByRelated =  new Map<String,Group> ();
	           for (Group grp : groups.values()) {
	               groupsByRelated.put(grp.RelatedId, grp);
	           }
	           allGroupsByRelated.add(groupsByRelated);
			}
        }

        System.debug(acctIds);
        
        if (isTm2Enabled) {
        	VOD_ProcessATL_TM2 tm2Processor = new VOD_ProcessATL_TM2();
        	tm2Processor.processATL_TM2(acctLoaders, acctIds, allTerritoryByNameMap, extendATLMode);	
        }else {
        	processATLTM1(acctLoaders, acctIds, allTerritoryByName, allGroupsByRelated, extendATLMode);
        }
        updateAccountATLTracking(acctIds); 
    }
    
    
    public static void processATLTM1 (List<Account_Territory_Loader_vod__c> acctLoaders, Set<Id> acctIds, List<Map<String, Map<String, String>>> allTerritoryByName, List<Map<String,Group>> allGroupsByRelated, boolean extendATLMode) {
    	 
    	List<AccountShare []> sharesAll = new List<AccountShare[]>();
        for (AccountShare [] shares : [SELECT Id, AccountId, UserOrGroupId From AccountShare WHERE AccountId in :acctIds AND RowCause = 'TerritoryManual']) {
            sharesAll.add(shares);
        }
        List<AccountShare> addShares = new List<AccountShare>();

        if (extendATLMode) {
            Map<Id, Map<Id, AccountShare>> acctToShares = new Map<Id, Map<Id, AccountShare>>();
            for (AccountShare[] shares : sharesAll) {
                for (AccountShare share : shares) {
                    if (acctToShares.get(share.AccountId) == null) {
                        acctToShares.put(share.AccountId, new Map<Id, AccountShare>());
                    }
                    acctToShares.get(share.AccountId).put(share.UserOrGroupId, share);
                }
            }
            List<AccountShare> sharesToDel = new List<AccountShare>();
            for (Account_Territory_Loader_vod__c acc : acctLoaders) {
                if (acc.Territory_To_Drop_vod__c != null) {
                    Map<Id, AccountShare> groupToShares = acctToShares.get(acc.Account_vod__c);
                    if (groupToShares == null) {
                        continue;
                    }
                    Set<String> uniqueSplits = new Set<String>();
                    String[] dropTerritories = acc.Territory_To_Drop_vod__c.split(';');
                    if (dropTerritories != null && dropTerritories.size() > 0) {
	                    uniqueSplits.addAll(dropTerritories);
    	                uniqueSplits.remove('');
                        for (String terrValue : uniqueSplits) {
                            Map<String,String> terr = getTerritoryByName(terrValue, allTerritoryByName);
                            if (terr == null) {
                                continue;
                            }
                            Group grp = getGroupById(terr.get('Id'), allGroupsByRelated);
                            if (grp == null) {
                                continue;
                            }
                            AccountShare share = groupToShares.get(grp.Id);
                            if (share != null) {
                                sharesToDel.add(share);
                                if (sharesToDel.size() == 1000) {
                                    delete sharesToDel;
                                    sharesToDel.clear();
                                }
                            }
                        }
                    }
                }
            }
            if (!sharesToDel.isEmpty()) {
                delete sharesToDel;
            }
            for (Account_Territory_Loader_vod__c acc : acctLoaders) {
                if (acc.Territory_To_Add_vod__c != null) {
                    String[] addTerritories = acc.Territory_To_Add_vod__c.split(';');
                    if (addTerritories != null && addTerritories.size() > 0) {
	                    Set<String> uniqueSplits = new Set<String>();
	                    uniqueSplits.addAll(addTerritories);
    	                uniqueSplits.remove('');
                        for (String terrValue : uniqueSplits) {
                            Map<String,String> terr = getTerritoryByName(terrValue, allTerritoryByName);
                            if (terr == null) {
                                continue;
                            }
                            Group grp = getGroupById(terr.get('Id'), allGroupsByRelated);
                            if (grp == null) {
                                continue;
                            }
                            AccountShare accShare = new AccountShare(UserOrGroupId = grp.Id,
                                                                     AccountId = acc.Account_vod__c);
                            addShares.add(accShare);
                            if (addShares.size() == 1000) {
                                insert addShares;
                                addShares.clear();
                            }
                        }
                    }
                }
            }
            if (!addShares.isEmpty()) {
                insert addShares;
            }
           
        } else {
            // If we are doing an update we need to clean out the account share rows.
            for (AccountShare [] shares : sharesAll) {
                delete shares;
            }

            // ready to create AccountShare
            for (Account_Territory_Loader_vod__c acc : acctLoaders) {
                if (acc.Territory_vod__c == null) {
                    continue;
                }
                String [] Territory_Split = acc.Territory_vod__c.split(';');
                Set<String> uniqueSplits = new Set<String>();
                uniqueSplits.addAll(Territory_Split);
                uniqueSplits.remove('');
                Set<Id> groupIds = new Set<Id>();
                for (String terrValue : uniqueSplits) {
                    Map<String,String> terr = getTerritoryByName(terrValue, allTerritoryByName);
                    // If we cant find the territory that was provieded move to the next entry.
                    if (terr == null) {
                        System.debug ('Territory not found for = ' + terrValue);
                        continue;
                    }
                    
                    Group grp = getGroupById(terr.get('Id'), allGroupsByRelated);
                    // If in the unlikely event we don't find a group. Move to the next
                    if (grp == null) {
                        System.debug ('Group not found for = '+ terrValue + '/' + terr.get('Id'));
                        continue;
                    }
                    
                    if (groupIds.contains(grp.Id))
                        continue;
                    
                    groupIds.add(grp.Id);
                    
                    //Since we are creating a manual assignment we read the important AccountShare settings
                    //off the territory and assign them to the new row.
                    AccountShare accShare = new AccountShare (  UserOrGroupId = grp.Id,
                                                              //  AccountAccessLevel = terr.AccountAccessLevel,
                                                              //  CaseAccessLevel = terr.CaseAccessLevel,
                                                              //  OpportunityAccessLevel = terr.OpportunityAccessLevel,
                                                              AccountId = acc.Account_vod__c);
                    System.debug ('Adding AccountShare grpId:' + grp.Id + ', acctId:' + acc.Account_vod__c);
                    addShares.add(accShare);
                    if (addShares.size() == 1000) {
                        insert addShares;
                        addShares.clear();
                    }
                }
            }
            // If we have new rows,  then perform the insert.
            if (!addShares.isEmpty()) {
                insert addShares;
            }
        }
    }
    public static boolean haveAccountATLTracking() {
        Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Account.fields.getMap();
        Schema.SObjectField trackingField = fieldMap.get(ATL_TRACKING_FIELD);
        Veeva_Settings_vod__c settings = Veeva_Settings_vod__c.getInstance();
        
        return trackingField != null && trackingField.getDescribe().getType() == Schema.DisplayType.DateTime 
            && settings != null && settings.ATL_LAST_UPDATE_TRACKING_vod__c;
    }
    
    public static void updateAccountATLTracking(Set<Id> acctIds) {
        if (acctIds != null && acctIds.size() > 0 && haveAccountATLTracking()) {
            DateTime now = Datetime.now();
            List<Account> accounts = new List<Account>();
            for (Id acctId : acctIds) {
                Account acct = new Account(Id=acctId);
                acct.put(ATL_TRACKING_FIELD, now);
                accounts.add(acct);
            }
            update accounts;
        }
    }

    public static List<Set<String>> getTerritories(List<Account_Territory_Loader_vod__c> acctLoaders, boolean extendATLMode) {
        // collect all territory names
        List<Set<String>> allTerrNames = new List<Set<String>>();
        Set<String> terrNames = new Set<String>();
        boolean addLastPiece = false;
        for (Account_Territory_Loader_vod__c acc : acctLoaders) {
            addLastPiece = false;
            Set<String> newTerrs = new Set<String>();
            if (extendATLMode) {
                if (acc.Territory_To_Add_vod__c != null) {
                    newTerrs.addAll(acc.Territory_To_Add_vod__c.split(';'));
                }
                if (acc.Territory_To_Drop_vod__c != null) {
                    newTerrs.addAll(acc.Territory_To_Drop_vod__c.split(';'));
                }
            } else {
                if (acc.Territory_vod__c != null) {
                    newTerrs.addAll(acc.Territory_vod__c.split(';'));
                }
            }
            newTerrs.remove('');

            // add territories to set
            for (Set<String> iterTerrs : allTerrNames) {
                newTerrs.removeAll(iterTerrs);
            }
            newTerrs.removeAll(terrNames);

            // break up to avoid governor limit
            if (terrNames.size() + newTerrs.size() < 1000) {
                terrNames.addAll(newTerrs);
                addLastPiece = true;
            } else {
                allTerrNames.add(terrNames);
                terrNames = newTerrs;
            }
        }
        if (addLastPiece) {
            allTerrNames.add(terrNames);
        }
        return allTerrNames;
    }

	public static Map<String, String> getTerritoryByName(String territoryName, List<Map<String, Map<String, String>>> allTerritoryByName) {
	        Map<String, String> terr = null;
	        for (Map<String, Map<String, String>> territoryByName : allTerritoryByName) {
	            terr = territoryByName.get(territoryName);
	            if (terr != null) {
	                return terr;
	            }
	        }
	        return terr;
	 }

    public static Group getGroupById(String territoryId, List<Map<String,Group>> allGroupsByRelated) {
        Group grp = null;
        for (Map<String,Group> groupsByRelated : allGroupsByRelated) {
            grp = groupsByRelated.get(territoryId);
            if (grp != null) {
                return grp;
            }
        }
        return grp;
    }
}