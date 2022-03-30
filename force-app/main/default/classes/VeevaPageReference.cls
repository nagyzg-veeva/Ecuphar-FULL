public without sharing class VeevaPageReference {
	@AuraEnabled(cacheable=true)
	public static String getFieldApiName(String lkid, String objectApiName) {
		String param = '%' + lkid + '%';
		List<FieldDefinition> defns = [SELECT QualifiedApiName from fieldDefinition where entityDefinition.QualifiedApiName = :objectApiName and DurableId like :param];
		if (defns.size() == 1) {
			return defns[0].QualifiedApiName;
		}
		return null;
	}
}