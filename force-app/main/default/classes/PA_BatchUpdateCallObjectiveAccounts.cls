global class PA_BatchUpdateCallObjectiveAccounts implements Database.Batchable<sObject> {
	
	String Query = 'SELECT id FROM Account WHERE RecordTypeid =: AccountRT';
	String AccountRT;
	List<id> CallObjectiveIDs;

	global PA_BatchUpdateCallObjectiveAccounts(List<Id> CallObjectiveIDs,String RecordTypeAccount) {
		AccountRT = RecordTypeAccount;
		this.CallObjectiveIDs = CallObjectiveIDs;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}


	global PA_BatchUpdateCallObjectiveAccounts(String RecordTypeAccount, String country) {
		System.debug('0');
		AccountRT = RecordTypeAccount;
		this.CallObjectiveIDs = new List<id>();
		List<Call_Objective_vod__c> callObjectivesTemp = new List<Call_Objective_vod__c> ();
		callObjectivesTemp = [SELECT Id FROM Call_Objective_vod__c WHERE Account_vod__c = null AND EP_Country_Code__c = :country];

		
		if(callObjectivesTemp!=null && callObjectivesTemp.size()>0){
			for(Call_Objective_vod__c callObj : callObjectivesTemp){
				this.CallObjectiveIDs.add(callObj.Id);
			}
		}
		System.debug('CallObjectiveIDs.size '+ CallObjectiveIDs.size());
		System.debug('CallObjectiveIDs '+ CallObjectiveIDs);
	}


   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		System.debug('1 CallObjectiveIds '+CallObjectiveIds);
		List<Call_Objective_vod__c> AccountsToCloneCallObjectives = [SELECT id,On_By_default_vod__c,Name_vod__c,Account_vod__c,From_Date_vod__c,To_Date_vod__c,Name,EP_Country_Code__c,Product_vod__c,Recurring_vod__c,RecordTypeId,Visibility_vod__c FROM Call_Objective_vod__c WHERE id in: CallObjectiveIds];
		System.debug('2 AccountsToCloneCallObjectives '+AccountsToCloneCallObjectives);
		List<Call_Objective_vod__c> CallObjectivesToInsert = new List<Call_Objective_vod__c> ();

		List<Id> accountIdList = new List<Id>();
		for(Account acc: (List<Account>) scope){
			accountIdList.add(acc.Id);
		}
		List<Call_Objective_vod__c> allCallObjectivesOfAccounts = [
			SELECT id, Name_vod__c, Account_vod__c, Product_vod__c
			FROM Call_Objective_vod__c
			WHERE Account_vod__c in :accountIdList
		];
		Map<Id,List<Call_Objective_vod__c>> mapCallObjByAccount = new Map<Id,List<Call_Objective_vod__c>>();
		for(Call_Objective_vod__c co: allCallObjectivesOfAccounts){
			Id accountId = co.Account_vod__c;
			if(!mapCallObjByAccount.keyset().contains(accountId)){
				mapCallObjByAccount.put(accountId,new List<Call_Objective_vod__c>());
			}
			List<Call_Objective_vod__c> callObjectivesOfAccount = mapCallObjByAccount.get(accountId);
			callObjectivesOfAccount.add(co);
		}

		for(Call_Objective_vod__c CO: AccountsToCloneCallObjectives){
		    for(Account A: (List<Account>) scope) {
		 	    Call_Objective_vod__c cloned = CO.clone(false,true,false,false);
			    cloned.Account_vod__c = A.id;
			    
			    if(!existsCallObjective(cloned,mapCallObjByAccount)){
			    	CallObjectivesToInsert.add(cloned);
				}
			}
		}
		try {
	   		insert CallObjectivesToInsert;
		}
		catch(DmlException E) {
			PA_EmailUtilsModel.sendExceptionEmailToAdmin('Exception on inserting cloned Call Objectives',
			   											String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'))
														,E);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}

	/**
		Checks if the Call Objective that we are going to insert already exists
		@param coToInsert the Call Objective that we want to check if it already exists
		@param mapCO map that contains all the Call Objectives of the Accounts
		@return true if the Call Objective exists in the Database. False otherwise
	**/
	private boolean existsCallObjective(Call_Objective_vod__c coToInsert, Map<Id,List<Call_Objective_vod__c>> mapCO){
		List<Call_Objective_vod__c> listCO = mapCO.get(coToInsert.Account_vod__c);
		Integer i = 0;
		//Boolean found = false;
		while(listCO != null && i<listCO.size() && !(listCO[i].Account_vod__c == coToInsert.Account_vod__c && listCO[i].Name_vod__c == coToInsert.Name_vod__c && listCO[i].Product_vod__c == coToInsert.Product_vod__c)){
			//Call_Objective_vod__c coAux = listCO[i];
			//found = (coAux.Account_vod__c == coToInsert.Account_vod__c && coAux.Name_vod__c == coToInsert.Name_vod__c && coAux.Product_vod__c == coToInsert.Product_vod__c);
			i++;
		}

		return listCO != null && i<listCO.size();
	}
	
}