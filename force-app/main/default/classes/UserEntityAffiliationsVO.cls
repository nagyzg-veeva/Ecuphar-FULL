/*
**** @description: UserEntityAffiliationsVO.cls, v1.0
**** @author: Murugesh Naidu, Veeva Professional Services
**** @date: July 16th, 2013
**** @comments: This class initializes itself with all associated Public Groups, Territories and Roles for either 
**** the given user in the Contructor or the User in session if default constructor is called.
*/
public class UserEntityAffiliationsVO {
	
    private Set<ID> allRelatedTerritoryIds ;
    private Set<ID> allRelatedRoleIds ;
    private Set<ID> allRelatedPublicGroupIds ;
    private User theUser;
/*    private static  UserEntityAffiliationsVO theEntityVO;
    
    public static UserEntityAffiliationsVO getInstance(){
    	if (theEntityVO == null){
    		System.debug('theEntityVO is null..setting it for first time');
    		theEntityVO = new UserEntityAffiliationsVO();
    	}
    	else{
    		System.debug('theEntityVO is NOT null..reusing!!!' + theEntityVO);   		
    	}
    	return theEntityVO;
    }
    public static UserEntityAffiliationsVO getInstance(ID userId){
    	if (theEntityVO == null){
    		System.debug('theEntityVO is null..setting it for first time');
    		theEntityVO = new UserEntityAffiliationsVO(userId);
    	}
    	else{
     		System.debug('theEntityVO is NOT null..reusing!!!' + theEntityVO);    		
    	}
    	return theEntityVO;
    }
  
  */  
    public UserEntityAffiliationsVO(){
    	System.debug('UserInfo.getUserId() = ' + UserInfo.getUserId());
    	new UserEntityAffiliationsVO(UserInfo.getUserId());
    }
    
    public UserEntityAffiliationsVO (ID userId){
    	//set the profile id and role id here
    	theUser = [Select Id, Name, ProfileId, UserRoleId from User where Id = :userId];
    	setAllRelatedTerritoryIds();
    	setAllRelatedRoleIds();
    	if(GAS_Hierarchical_Setting__c.getInstance().Include_Public_Group_based_filtering__c){
	    	setAllRelatedPublicGroupIds();
    	}
    }
    
    public Set<ID> getAllRelatedTerritoryIds () {
       	return allRelatedTerritoryIds;
    }
    public Set<ID> getAllRelatedRoleIds() {
    	return allRelatedRoleIds;
    }
    public Set<ID> getAllRelatedPublicGroupIds() {
    	return allRelatedPublicGroupIds;    	
    }
    
    public User getUserInfo(){
    	return theUser;
    }
    
    private void setAllRelatedPublicGroupIds(){
    	
    	Set<ID> userAssociatedGroups = new Set<ID> {theUser.Id};
    	Set<ID> userAssociatedPublicGroups = new Set<ID> ();
    	    	
    	Set<ID> allRelatedIds = new Set<ID> ();
    	if(allRelatedTerritoryIds!=null && allRelatedTerritoryIds.size() > 0){
    		//add the direct and indirect territories (parents of direct terrs) this person belongs to
    		allRelatedIds.addAll(allRelatedTerritoryIds);
    		
    	}
    	if(allRelatedRoleIds!=null && allRelatedRoleIds.size() > 0){
   		//add the direct and indirect roles (parents of direct role) this person belongs to
     		allRelatedIds.addAll(allRelatedRoleIds);
    	}
    	//add the userid also as a related id, to cover the case where public group is directly created for users
 	   	System.debug('allRelatedIds = ' + allRelatedIds);
    	Map<Id, Group> userGroups = new Map<Id, Group> (
    											[Select Id, RelatedId 
    												from Group where RelatedId 
    												in: allRelatedIds
    												]);	
    	if(userGroups!=null && userGroups.size() > 0){
    		userAssociatedGroups.addAll(userGroups.keySet());
    	//now that we have all the group ids to cover for any hierarchical Territory and Role Ids that make up Public Groups, 
    	//check and add any direct or indirect hierarchical Public Groups (Public Group inside a Public group inside a P...)
    	 //add the direct and indirect Public Groups (parents of direct Public Group or Public Groups corresponding to Terr or Role Hierarchy) this person belongs to
    	
			Set<ID> allRelPubGroups = getParentPublicGroupIDs(userAssociatedGroups, theUser.Id);
		   	System.debug('allRelPubGroups = ' + allRelPubGroups);
		   	if(allRelPubGroups!=null){
		   		userAssociatedGroups.addAll(allRelPubGroups);
		   	}
    	}
    	for(GroupMember aGrp: [SELECT GroupId, Group.Name, Id, SystemModstamp, UserOrGroupId FROM GroupMember
									where UserOrGroupId in :userAssociatedGroups]){
			userAssociatedPublicGroups.add(aGrp.GroupId);							
		}
    	allRelatedPublicGroupIds = userAssociatedPublicGroups;
    } 

    private void setAllRelatedTerritoryIds(){
    	List<UserTerritory2Association> userTerritories = [SELECT Id, Territory2Id , UserId 
    											FROM UserTerritory2Association 
												WHERE UserId = :theUser.Id];
		if(userTerritories==null || userTerritories.size() == 0 ){
			return;
		}
		Set<ID> allRelatedTerrIDs = new Set<ID> ();
		Set<ID> directTerrIds = new Set<ID> ();
		for(UserTerritory2Association ut: userTerritories){
			directTerrIds.add(ut.Territory2Id);
		}
		//load up ALL Territories
		Map<Id, Territory2 > territoryMap = new Map <ID, Territory2 > ([SELECT Id, ParentTerritory2Id , Name
											FROM Territory2]);
		
		for(ID terrId: directTerrIds){
			allRelatedTerrIDs.add(terrId);
			Territory2 aTerr = territoryMap.get(terrID);
			while(aTerr.ParentTerritory2Id!=null){//if there is no Parent, then it should drop out of the loop
				allRelatedTerrIDs.add(aTerr.ParentTerritory2Id);//record all related Terr Ids in this set
				aTerr = territoryMap.get(aTerr.ParentTerritory2Id);//this will now change the reference to th Parent Territory
			}
		}
		allRelatedTerritoryIds = allRelatedTerrIDs	;						    	
    } 
    
    private void setAllRelatedRoleIds(){

		if(theUser.UserRoleId==null){
			return;
		}
		Set<ID> allRelRoleIDs = new Set<ID> ();
		//load up ALL Roles
		Map<Id, UserRole> roleMap = new Map <ID, UserRole> ([Select Id, ParentRoleId, Name
											from UserRole]);
		if(roleMap == null || roleMap.size() == 0 ){
			return;
		}
		Id tmpRoleId = theUser.UserRoleId;
		do{
			
			UserRole theRole = roleMap.get(tmpRoleId);
			allRelRoleIDs.add(theRole.Id);
			tmpRoleId = theRole.ParentRoleId;
			
		}while (tmpRoleId!=null);
		
		allRelatedRoleIDs	= allRelRoleIDs;
    } 

   /*
    */
    private Set<ID> getParentPublicGroupIDs(Set<ID> groupIds, ID userId){
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
    

}