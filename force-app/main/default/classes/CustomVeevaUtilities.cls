/* 
* @author - Murugesh Naidu, Veeva Systems Professional Services
* @createdDate - Jul 8, 2013
* @description - CustomVeevaUtilities - contains custom generic helper methods that can be applicable across a spectrum of customizations
*/
public with sharing class CustomVeevaUtilities {

	public static String getDynamicSOQLForAllEligibleFields(Schema.SobjectType sObjType){
		
		if(!sObjType.getDescribe().isQueryable()){
			throw new ApplicationException ('Object ' + sObjType.getDescribe().getName() + ' cannot be queried');
		}
		if(!sObjType.getDescribe().isAccessible()){
			throw new ApplicationException ('Object ' + sObjType.getDescribe().getName() + ' cannot be accessed');
		}
		
		Map<String, Schema.SObjectField> mapFields = sObjType.getDescribe().fields.getMap();
		
		String dynamicSOQL = 'Select ';
		for(Schema.SObjectField aField: mapFields.values()){
			if(aField.getDescribe().isAccessible()){
				dynamicSOQL += aField.getDescribe().getName() ;
				dynamicSOQL += ', ';
			}
		}
		dynamicSOQL = dynamicSOQL.substringBeforeLast(',');
		dynamicSOQL += ' From ' + sObjType.getDescribe().getName();
		System.debug('dynamicSOQL ==>' + dynamicSOQL);
		return dynamicSOQL;
	}
	
	public static String getDynamicChildFieldsSOQL(Schema.ChildRelationship childRelationship, ID parentIdValue){
		String dynamicSOQL = getDynamicSOQLForAllEligibleFields(childRelationship.getChildSObject());
		//apply the where clause to only return child records related to parent
		dynamicSOQL += ' where ' + childRelationship.getField().getDescribe().getName() + ' = \'' + parentIdValue + '\'';
		System.debug('dynamicChild fields SOQL ==>' + dynamicSOQL);
		
		return dynamicSOQL;
	}
	
	public static Schema.SObjectType getSObjectType(String objectAPIName){
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		return gd.get(objectAPIName);
	}
	
	public static Schema.SObjectField getSObjectField(String objectAPIName, String fieldAPIName){
		Schema.SObjectType sObjType = getSObjectType(objectAPIName);
		Schema.SObjectField sObjField = null;
		if(sObjType!=null){
			sObjField =  sObjType.getDescribe().fields.getMap().get(fieldAPIName);
		}
		return sObjField;
	}
	
	public static Set<String> getFieldTokens(String s, String startKey, String endKey, Boolean includeKeys){
		if(s==null || s.trim() == '' || (!s.contains(startKey) && !s.contains(endKey))){
			return null;
		}
		Set<String> tokenList = new Set<String> ();
		
		while(s.indexOf(startKey)!=-1){
			String theToken = s.substringBetween(startKey,endKey);
			if(includeKeys){
				theToken = startKey + theToken + endKey;
			}
			tokenList.add(theToken);
			s = s.replaceFirst(startKey, '');
			s = s.replaceFirst(endKey, '');
		}
		System.debug('The tokenList = ' + tokenList);
		return tokenList;
	}
		
	public class ApplicationException extends Exception {
		
	}
}