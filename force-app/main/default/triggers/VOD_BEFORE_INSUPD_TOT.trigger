trigger VOD_BEFORE_INSUPD_TOT on Time_Off_Territory_vod__c (before update, before insert) {
            if(VEEVA_PROCESS_FLAGS.getUpdateTOT()== true){
               return;
            }
            Set <Id> ownerList = new Set<Id> ();

            for (Integer o = 0; o < Trigger.new.size(); o++) {
                ownerList.add(Trigger.new[o].OwnerId);      
            }
            Map <String, List <String>> mTerr = new Map <String, List <String>>();

            Map<Id, Map<String, String>> userTerrs = new Map<Id, Map<String, String>>();
            Map<Id, Map<String, String>> territoryMap = new Map<Id, Map<String, String>>();
            Set<Id> territoryIds = new Set<Id>();
            userTerrs = TerritoryManagementFactory.getInstance().getUserTerritories(ownerList, null);
            for(Map<String, String> ut : userTerrs.values()){
                //TERRITORY_MAP in TerritoryManagement handles TerritoryId & Territory2Id mapping
                territoryIds.add(ut.get('territoryId'));
            }
            territoryMap = TerritoryManagementFactory.getInstance().getTerritories(territoryIds);

            for(Map<String, String> userTerr : userTerrs.values()) {
                String UserId = userTerr.get('UserId');
                List <String> sTerr = mTerr.get(UserId);
                if (sTerr == null) {
                   sTerr = new List <String> ();
                }
                Map<String, String> terr = territoryMap.get(userTerr.get('territoryId'));
                if (terr != null) {
                    sTerr.add(terr.get('Name'));
                    mTerr.put(UserId, sTerr);
                }
            }
        
            for (Integer l = 0; l < Trigger.new.size(); l++) {
        
                String ownerInRow = Trigger.new[l].OwnerId;
                List <String> thisSet = mTerr.get(ownerInRow);
                String terrString = ';';
        
                if (thisSet != null) {
                    for (String terrName : thisSet) {
                        terrString += terrName + ';';
                    }
                }
                Trigger.new[l].Territory_vod__c = terrString ;
                if(Trigger.new[l].Time_vod__c == 'Hourly'){
                    if(Trigger.new[l].Hours_off_vod__c == null)
                        Trigger.new[l].Hours_off_vod__c = '1';  
                    if(Trigger.new[l].Start_Time_vod__c == null)    
                        Trigger.new[l].Start_Time_vod__c = '8:00 AM';                 
                }
            }
        }