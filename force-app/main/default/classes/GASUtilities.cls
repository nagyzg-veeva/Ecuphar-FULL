/**
***** @className: GASUtilities.cls
***** @createDate: 7/17/2013
***** @author: Murugesh Naidu, Veeva Professional Services
***** @description: Includes methods used by the GAS search API (searchAccts.cls). At the time of creation, this mostly
***** had methods related to GAS Custom Criteria based filtering
**** Jan 9, 2014 - mnaidu - Update the filtering methods to consider the already filtered account list so that a full table scan is avoided
**/
public without sharing class GASUtilities {

	public static User LOGGED_IN_USER_GLOBAL = (User) Database.query(
																CustomVeevaUtilities.getDynamicSOQLForAllEligibleFields(User.SOBjectType) 
																+ ' where Id = \'' + UserInfo.getUserId() + '\'' ); 
	public static final Set<String> FIELD_TYPES_NEEDING_QUOTES = new Set<String> {'STRING', 'REFERENCE','ID','BASE64','PICKLIST','MULTIPICKLIST','URL',
																					'PHONE','EMAIL'};
	public static final String KEYWORD_DELIM = '@@';
	
    //MNAIDU - Jan 9, 2014 - Update the signature to take in the accountIds that have already been filtered by the first unfiltered search so that we avoid a full
	//table scan																			
	public static Set<ID> getAccountIdsToExclude(ID userId, List<ID> acctIdsWithoutFilter){
		
		Set<ID> accountIdsToExclude = null;
    //	LOGGED_IN_USER_GLOBAL = (User) Database.query(CustomVeevaUtilities.getDynamicSOQLForAllEligibleFields(User.SOBjectType) + ' where Id = \'' + UserInfo.getUserId() + '\'' );
		
		List<GAS_Visibility_Configuration__c> userGVCs = getGVCInstances(userId);
		
		if(userGVCs!=null && userGVCs.size() > 0){
			accountIdsToExclude = new Set<ID> ();
			for(GAS_Visibility_Configuration__c aGVC: userGVCs){
				accountIdsToExclude.addAll(getMatchingAccountIds(aGVC.Custom_Criteria__c, aGVC.Object_API_Name__c, aGVC.Account_Lookup_Field_API_Name__c, acctIdsWithoutFilter));
			}
		}		
		return accountIdsToExclude;
	}
	
	//MNAIDU - Jan 9, 2014 - Update the signature to take in the accountIds that have already been filtered by the first unfiltered search so that we avoid a full
	//table scan																			
	public static List<ID> getMatchingAccountIds(String whereClause, String tableName, String accountLookupFieldName, List<ID> acctIdsWithoutFilter){
		
		String dynamicSOQL = '';
		String additionalFilter = '';
		whereClause = getParsedQuery(whereClause, tableName);
		System.debug('Parsed whereClause = ' + whereClause);
		if(accountLookupFieldName!=null && accountLookupFieldName.trim()!=''){
			if(acctIdsWithoutFilter!=null){
				additionalFilter = ' AND ' + accountLookupFieldName + ' in:acctIdsWithoutFilter';
			}
			else{
				additionalFilter = ' LIMIT 1';//this is just a SOQL compile check - called from the trigger				
			}
			dynamicSOQL = 'Select Id, ' + accountLookupFieldName + ', Name from ' +  tableName 
							+ ' where ' + whereClause + additionalFilter;
		}
		else{
			if(acctIdsWithoutFilter!=null){
				additionalFilter = ' AND Id in:acctIdsWithoutFilter';
			}
			else{
				additionalFilter = ' LIMIT 1';//this is just a SOQL compile check - called from the trigger				
			}
			dynamicSOQL = 'Select Id, Name from ' +  tableName 
							+ ' where ' + whereClause + additionalFilter;		
		}
		System.debug('dynamicSOQL = ' + dynamicSOQL);
		List<sObject> sObjList = Database.query(dynamicSOQL);
		List<ID> matchingAccountIdList = null ; 
 		if(sObjList!=null){
 			matchingAccountIdList = new List<ID> ();
 			for(sObject aObj: sObjList){
 				if(accountLookupFieldName!=null){
	 				matchingAccountIdList.add((ID) aObj.get(accountLookupFieldName));
 				}
 				else{
 					matchingAccountIdList.add((ID) aObj.get('Id'));
 				}
 			}
 		}
		return matchingAccountIdList;
	}
	
	public static List<GAS_Visibility_Configuration__c> getGVCInstances(Id userId){
		//if Exclusive criteria exists, then only send  instances which are exclusive
		
		UserEntityAffiliationsVO entityVO = new UserEntityAffiliationsVO(userId);
	   	Set<ID> gvcEntityIdSet = new Set<ID> ();
	    	gvcEntityIdSet.add(entityVO.getUserInfo().Id);
	    	gvcEntityIdSet.add(entityVO.getUserInfo().ProfileId);
	    	gvcEntityIdSet.add([Select Id from Organization].Id);
	    	if(entityVO.getAllRelatedPublicGroupIds()!=null){
		    	gvcEntityIdSet.addAll(entityVO.getAllRelatedPublicGroupIds());
	    	}
	    	List<GAS_Visibility_Configuration__c> gvcList = [SELECT Account_Lookup_Field_API_Name__c, Active__c, Custom_Criteria__c, Entity_ID__c, 
	    															Name, Entity_Type__c, Exclusive_criteria__c, External_Id__c, 
	    															Object_API_Name__c, Id 
	    														FROM GAS_Visibility_Configuration__c
	    															WHERE Entity_ID__c in: gvcEntityIdSet
	    															and Active__c = true];
	    	
	    	if(gvcList == null || gvcList.size() == 0) {
	    			return null;
	     	}
	     	List<GAS_Visibility_Configuration__c> gvcExclusiveList = new List<GAS_Visibility_Configuration__c> ();
 		    for(GAS_Visibility_Configuration__c aGVC: gvcList){
 		    	if(aGVC.Exclusive_criteria__c){ //one exclusive criteria per entity per object - enforced from external id. Ext id = Entity Id + Object Name + Exclusive_criteria__c
 		    		gvcExclusiveList.add(aGVC);
 		    	}
 		    }
 		    
 		    if(gvcExclusiveList.size() > 0 ){
 		    	return gvcExclusiveList;//if exclusive values exist, then only consider those in evaluation
 		    }
 		    else{
 		    	return gvcList;
 		    }
		
		return null;
	}
   
   /*
    * @description - This method will return a Set of IDs that includes
    * 1. All direct territories that the user belongs to
    * 2. All parent and grand parents traversed through the top till there is no parent
    */
    public static Set<ID> getParentTerritoryIDs(ID userID){
    	List<UserTerritory2Association > userTerritories = [SELECT Id, Territory2Id , UserId 
    											FROM UserTerritory2Association 
												WHERE UserId = :userID];
		if(userTerritories==null || userTerritories.size() == 0 ){
			return null;
		}
		Set<ID> allRelatedTerrIDs = new Set<ID> ();
		Set<ID> directTerrIds = new Set<ID> ();
		for(UserTerritory2Association  ut: userTerritories){
			directTerrIds.add(ut.Territory2Id);
		}
		//load up ALL Territories
		Map<Id, Territory2 > territoryMap = new Map <ID, Territory2 > ([Select Id, ParentTerritory2Id , Name
											from Territory2 ]);
		
		for(ID terrId: directTerrIds){
			allRelatedTerrIDs.add(terrId);
			Territory2  aTerr = territoryMap.get(terrID);
			while(aTerr.ParentTerritory2Id !=null){//if there is no Parent, then it should drop out of the loop
				allRelatedTerrIDs.add(aTerr.ParentTerritory2Id );//record all related Terr Ids in this set
				aTerr = territoryMap.get(aTerr.ParentTerritory2Id );//this will now change the reference to th Parent Territory
			}
		}
		return 	allRelatedTerrIDs	;						
    }

   /*
    * @description - This method will return a Set of IDs that includes
    * 1. All direct territories that the user belongs to
    * 2. All parent and grand parents traversed through the top till there is no parent
    */
    public static Set<ID> getParentPublicGroupIDs(Set<ID> groupIds, ID userId){
    	List<GroupMember> userGroupMembers = [Select Id, GroupId, Group.Type, UserOrGroupId 
    											from GroupMember
												where  (UserOrGroupId in: groupIds OR UserOrGroupId =: userId)
												and Group.Type = 'Regular'];
		if(userGroupMembers==null || userGroupMembers.size() == 0 ){
			return null;
		}
		Set<ID> allRelatedPubGrpIDs = new Set<ID> ();
		Set<ID> directPubGrpIds = new Set<ID> ();
		for(GroupMember gm: userGroupMembers){
			directPubGrpIds.add(gm.GroupId);
		}
		//load up ALL GroupMembers that are related to Public Groups
		List<GroupMember> groupMembers = new List <GroupMember> ([Select Id, GroupId, Group.Type, UserOrGroupId 
    																		from GroupMember
																			where Group.Type = 'Regular']);
		
		Map<Id, GroupMember> userGrpIdToGroupMember = new Map<Id, GroupMember> ();
		for(GroupMember aMem: groupMembers){
			userGrpIdToGroupMember.put(aMem.UserOrGroupId, aMem);
		}
		
		for(GroupMember grpMember: userGroupMembers){
			allRelatedPubGrpIDs.add(grpMember.GroupId);//add the direct Group Id to relatedId list
			GroupMember aGrpMem = userGrpIdToGroupMember.get(grpMember.GroupId);//Check if this Group itself belongs to another Public Group
			while(aGrpMem!=null){//if there is no associated Public Group, then it should drop out of the loop
				allRelatedPubGrpIDs.add(aGrpMem.GroupId);//record all related Terr Ids in this set
				aGrpMem = userGrpIdToGroupMember.get(aGrpMem.GroupId);//this will now change the reference to th Parent Group, if any
			}
		}
		return 	allRelatedPubGrpIDs	;						
    }

    /*
    * @description - This method will return a Set of IDs that includes
    * 1. All direct roles that the user belongs to
    * 2. All parent and grand parents roles traversed through the top till there is no parent
    */
    public static Set<ID> getParentRoleIDs(ID roleId){
		
		if(roleId==null){
			return null;
		}
		Set<ID> allRelatedRoleIDs = new Set<ID> ();
		//load up ALL Roles
		Map<Id, UserRole> roleMap = new Map <ID, UserRole> ([Select Id, ParentRoleId, Name
											from UserRole]);
		if(roleMap == null || roleMap.size() == 0 ){
			return null;
		}
		Id tmpRoleId = roleId;
		do{
			
			UserRole theRole = roleMap.get(tmpRoleId);
			allRelatedRoleIDs.add(theRole.Id);
			tmpRoleId = theRole.ParentRoleId;
			
		}while (tmpRoleId!=null);
		
		return 	allRelatedRoleIDs	;						
    }
	/*
	* @methodDescription: Returns false if eny of the entity names is not valid. If all entities are valid, 
	* Returns true and updates the passed <code>List<GAS_Visibility_Configuration__c></code> with the valid entity Ids.
	*/
    public static Boolean allValidEntities(List<GAS_Visibility_Configuration__c> gvcList){
    	if(gvcList==null || gvcList.size() == 0){
    		return false;
    	}
    	List<String> userNameList = new List<String>();
    	List<String> profileNameList = new List<String>();
    	List<String> grpNameList = new List<String>();
    	Organization theOrg = [Select Id, Name from Organization];
    	Integer totalInputSize = 0;
    	Integer totalOutputSize = 0;
    	Boolean isValid = false;
    	for(GAS_Visibility_Configuration__c aGVC: gvcList){
    		if(aGVC.Entity_Type__c == 'Public Group'){
    			grpNameList.add(aGVC.Name);
    		}
    		if(aGVC.Entity_Type__c == 'Profile'){
    			profileNameList.add(aGVC.Name);
    		}
    		if(aGVC.Entity_Type__c == 'User'){
    			userNameList.add(aGVC.Name);
    		}
    		if(aGVC.Entity_Type__c == 'Organization'){
    			if(aGVC.Name.trim() != theOrg.Name.trim()){
    				return false;
    			}
    			else{
    				aGVC.Entity_ID__c = theOrg.Id;
    			}
    		}
    	}
    	totalInputSize = grpNameList.size() + profileNameList.size() + userNameList.size();//org is already handled so dont consider that
    	List<User> usrList = [select Id, Name, UserName from User where UserName in:userNameList ];
    	List<Profile> prflList = [select Id, Name from Profile where name in:profileNameList ];
    	List<Group> grpList = [select Id, Name from Group where name in:grpNameList ];
    	totalOutputSize += (usrList!=null) ? usrList.size() : 0;
    	totalOutputSize += (prflList!=null) ? prflList.size() : 0;
    	totalOutputSize += (grpList!=null) ? grpList.size() : 0;
    	
    	if(totalInputSize==totalOutputSize){
    		isValid = true;
	    	Map<String, ID> usrMap = new Map<String, ID>();
	    	Map<String, ID> prflMap = new Map<String, ID>();
	    	Map<String, ID> grpMap = new Map<String, ID>();

    		for(User aUsr: usrList){
    			usrMap.put(aUsr.UserName, aUsr.Id);
    		}
    		for(Profile aPrfl: prflList){
    			prflMap.put(aPrfl.Name, aPrfl.Id);
    		}
    		for(Group aGrp: grpList){
    			grpMap.put(aGrp.Name, aGrp.Id);
    		}
    		
    		for(GAS_Visibility_Configuration__c aGVC: gvcList){
    			if(aGVC.Entity_Type__c == 'Profile'){
       				aGVC.Entity_ID__c = prflMap.get(aGVC.Name);
    			}
    			if(aGVC.Entity_Type__c == 'User'){
       				aGVC.Entity_ID__c = usrMap.get(aGVC.Name);
    			}
    			if(aGVC.Entity_Type__c == 'Public Group'){
       				aGVC.Entity_ID__c = grpMap.get(aGVC.Name);
    			}
     		}
    	}
    	
    	return isValid;
    	
    }    

   	
    	
    	/**
VOD_SF_USER:<fieldName> - Retrieves the value of the Logged In User's User.fieldName. For eg: User.Country_code__c will return a single quote encapsulated 'US' from the Logged in User's User Record
VOD_SF_USER_ID - Salesforce ID of the mobile user
VOD_SF_PROFILEID - Profile ID of the mobile user
VOD_MY_ORGID - Salesforce organization ID
VOD_USER_LANG_CD - Value of User.LanuageLocaleKey. Can be a 2-character language code, eg. 'ru' for Russian, or a 5-character language plus locale, e.g. 'es_EC' for Spanish (Ecuador).
VOD_MY_TERRITORY - Returns a comma-separated list of the mobile user's territory names (NOT Ids). If the number of user territories is more than 100, a quoted empty string ('') will be returned.
VOD_RECORDTYPE_ID - Retrieve a RecordType ID by name, e.g. @@VOD_RECORDTYPE_ID:Professional@@. Record type provided must be applicable to the object referenced by thadVOC, and visible to the mobile user.
VOD_USERS_IN_MY_TERRITORY - Generates a clause listing User IDs for all Salesforce users in the mobile user's territory and sub-territories, including at least the mobile user themselves, queried through the provided field name, e.g. @@VOD_USERS_IN_MY_TERRITORY:OwnerId@@ will generate ( OwnerId IN ('005d....', '005a...',))    	
    	*/
    	
    
    public static String getParsedQuery(String queryToParse, String objectName){
    	
    	if(queryToParse==null || queryToParse.trim() == '' || !queryToParse.contains(KEYWORD_DELIM)){
    		return queryToParse;
    	}
      	Map<String, String> tokenToValueMap = new Map<String, String> ();
    	Set<String> tokenSet = CustomVeevaUtilities.getFieldTokens(queryToParse, KEYWORD_DELIM, KEYWORD_DELIM, true);
    	 									
    	for(String aStr: tokenSet){
    		if(aStr.contains('VOD_SF_USER:')){
    			//get the field type first so that we know for String to enquote the value in ''
    			sObjectField aField = User.sObjectType.getDescribe().fields.getMap().get(aStr.subStringBetween(':',KEYWORD_DELIM));
    			if(aField!=null){
	    			Object value = LOGGED_IN_USER_GLOBAL.get(aField);
	    			System.debug('aField.getDescribe().getType().name()...' + aField.getDescribe().getType().name());
	    			if(value!=null && FIELD_TYPES_NEEDING_QUOTES.contains(aField.getDescribe().getType().name().toUpperCase())){
		    			tokenToValueMap.put(aStr,'\'' + value  + '\'');    				
	    			}
	    			else{
	    				tokenToValueMap.put(aStr, value + '');
	    			}
    			}
    		}
    		else if(aStr.contains('VOD_RECORDTYPE_ID:'))	{
    			String recTypeId = getRecordTypeIdByName(objectName, aStr.subStringBetween(':',KEYWORD_DELIM));
    			tokenToValueMap.put(aStr,recTypeId );
    		}
    		else if(aStr.contains('VOD_USERS_IN_MY_TERRITORY:'))	{
    			String value = getUsersInMyTerritoryAndBelow(aStr.subStringBetween(':',KEYWORD_DELIM));
    			tokenToValueMap.put(aStr,value);
    		}
    		else if(aStr.equalsIgnoreCase(KEYWORD_DELIM + 'VOD_MY_TERRITORY' + KEYWORD_DELIM))	{
    			tokenToValueMap.put(aStr,getMyTerritories());
    		}
    		else if(aStr.equalsIgnoreCase(KEYWORD_DELIM + 'VOD_SF_PROFILEID' + KEYWORD_DELIM))	{
    			tokenToValueMap.put(aStr,'\'' + UserInfo.getProfileId() + '\'');
    		}
    		else if(aStr.equalsIgnoreCase(KEYWORD_DELIM + 'VOD_SF_USER_ID' + KEYWORD_DELIM))	{
    			tokenToValueMap.put(aStr,'\'' + UserInfo.getUserId() + '\'');
    		}
    		else if(aStr.equalsIgnoreCase(KEYWORD_DELIM + 'VOD_MY_ORGID' + KEYWORD_DELIM))	{
    			tokenToValueMap.put(aStr,'\'' + UserInfo.getOrganizationId() + '\'');
    		}
    		else if(aStr.equalsIgnoreCase(KEYWORD_DELIM + 'VOD_USER_LANG_CD' + KEYWORD_DELIM))	{
    			tokenToValueMap.put(aStr,'\'' + LOGGED_IN_USER_GLOBAL.LanguageLocaleKey + '\'');
    		}
    	}
    	for(String aToken: tokenToValueMap.keySet()){
    		queryToParse = queryToParse.replaceAll(aToken, tokenToValueMap.get(aToken));
    		if(!queryToParse.contains(KEYWORD_DELIM)){
    			break;//break if no more parseable string exists
    		}
    	}
    	//MNAIDU - Jan 9, 2014 - Enclose the string in ( ) so that an AND condition could be applied
     	return queryToParse;
    }
    
    public static String getUsersInMyTerritoryAndBelow(String queryWithField){
    	
    	return null;
    }
    
    public static String getMyTerritories(){
    	List<Territory2> userTerrList = [SELECT Name, Id FROM Territory2  WHERE Id in (SELECT Territory2Id  FROM UserTerritory2Association WHERE UserId = :UserInfo.getUserId())];
    	
    	if(userTerrList==null || userTerrList.size() == 0 || userTerrList.size() > 100){
    		return '\'\'' ;//quoted empty string
    	}
    	String myTerrs = '';
    	for(Territory2 aTerr: userTerrList){
    		myTerrs += '\'' + aTerr.Name + '\'' + ',';
    	}
    	myTerrs = myTerrs.substringBeforeLast(',');
    	System.debug('myTerrs = ' + myTerrs);
    	return myTerrs;
    }
    
    public static String getRecordTypeIdByName(String objectName, String recordTypeName){
		Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
		if(objType.getDescribe().getRecordTypeInfosByName().get(recordTypeName)!=null){
			ID rtId = objType.getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();		
			System.debug('rtId = ' + rtId);
	    	return '\'' + rtId + '\'';			
		}		
		else{
			return '\'' + '\'';
		}
    }
    
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName)
	{
	    Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
	    Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
	    Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
	
	    Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
	    return fieldSetObj.getFields();
	}
    
    /*
    * Returns default fieldset if no fielset exists for the RecordTypeName
    */
    public static List<Schema.FieldSetMember> readFieldSet(String defaultFieldSetName, 
    														String RTDeveloperName, 
    														String ObjectName,
    														String delim)
	{
	    List<Schema.FieldSetMember> FSMembers;
	    Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
	    Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
	    Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
	
		Map<String, Schema.FieldSet> fieldSetMap = DescribeSObjectResultObj.FieldSets.getMap();
		String theFieldSetName;
		System.debug('fieldSetMap = ' + fieldSetMap);
		for(Schema.FieldSet aFS: fieldSetMap.values()){
			System.debug('Label = ' + aFS.getLabel());
			System.debug('Name = ' + aFS.getName());
			if(aFS.getLabel().contains(delim + RTDeveloperName + delim)){
				theFieldSetName = aFS.getName();
				break;
			}
		}
		System.debug('theFieldSetName = ' + theFieldSetName);
		Schema.FieldSet fieldSetObj;
		if(theFieldSetName!=null){
			fieldSetObj = fieldSetMap.get(theFieldSetName);
		}
	    else{
	    	fieldSetObj = fieldSetMap.get(defaultFieldSetName);
	    }
	   System.debug('fieldSetObj = ' + fieldSetObj);
	    
	    if(fieldSetObj!=null){
	    	FSMembers = fieldSetObj.getFields();
	    }
	    System.debug('FSMembers = ' + FSMembers);
	    return FSMembers;
	}
    
}