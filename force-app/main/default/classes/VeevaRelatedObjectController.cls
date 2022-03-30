public with sharing class VeevaRelatedObjectController {

	@AuraEnabled
	public static List<SObject> getRelatedRecords(String fields, String objectApiName, String relationField, String id, Integer qlimit, Integer offset) {
		return queryRelatedRecords(fields, objectApiName, relationField, id, qlimit, offset);
	}

	private static List<SObject> queryRelatedRecords(String fields, String objectApiName, String relationField, String id, Integer qlimit, Integer offset) {
		try {
			fields = applyToLabelToPicklistFields(fields, objectApiName);
			Id validId = id;
			String query = 'SELECT {0} FROM {1} WHERE {2} = :validId ORDER BY Name LIMIT :qlimit OFFSET :offset';
            List<Object> parameters = new List<Object> {fields, objectApiName, String.escapeSingleQuotes(relationField)};
			List<SObject> records = Database.query(String.format(query, parameters));
			return records;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static string applyToLabelToPicklistFields(String fieldsString, String objectApiName) {
		Map<String, Schema.SObjectField> objectFieldsMap = getFieldsMap(objectApiName);
		String[] fieldNames = fieldsString.split(',');

		for (Integer i = 0; i < fieldNames.size(); i++) {
			String fieldName = fieldNames[i].trim();
			if(objectFieldsMap.containsKey(fieldName)){
				Schema.DisplayType fieldDataType = objectFieldsMap.get(fieldName).getDescribe().getType(); 
				if(fielddataType == Schema.DisplayType.PICKLIST) {
					fieldNames[i] = 'toLabel(' + fieldName + ')';
				}
			}
		}

		String updatedFieldsString = String.join(fieldNames, ',');
		return updatedFieldsString;
	}

	private static Map<String, Schema.SObjectField> getFieldsMap(string objectApiName) {
		Type objectType = Type.forName(objectApiName);
		Schema.SObjectType sObjectType = ((SObject) objectType.newInstance()).getSObjectType();
		Schema.DescribeSObjectResult objectDescribeResult = sObjectType.getDescribe();
		Map<String, Schema.SObjectField> fieldsMap = objectDescribeResult.fields.getMap();
		return fieldsMap;
	}
	
	@AuraEnabled(cacheable=true)
	public static List<SObject> getRelatedObjects(VeevaWiredWrapperParams wrapper){
		if (wrapper.referenceFieldName == null) {
			return null;
		}
		List<String> queryParams = wrapper.queryParams;
		String childObject = wrapper.childObject;
		String objectId = wrapper.objectId;
		List<SObject> result = new List<SObject>();
		if (queryParams != null && queryParams.size() > 0) {
			String stmt = 'Select ' + String.join(new List<String>(queryParams), ',') + ' from ' + childObject +
			' where ' + wrapper.referenceFieldName + ' = :objectId';
			result = Database.query(stmt);
		}
		return result;
	}
}