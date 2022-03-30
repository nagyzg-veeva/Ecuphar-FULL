public with sharing class MedInqController {

	static final Set<String> ADDRESS_FIELDS = new Set<String> {'Id', 'Name', 'Address_line_2_vod__c', 'City_vod__c', 'State_vod__c', 'Zip_vod__c', 'Country_vod__c'};
	static final Set<String> ACCT_FAX_FIELDS = new Set<String> {'Fax'};
	static final Set<String> ADDR_FAX_FIELDS = new Set<String> {'Fax_vod__c', 'Fax_2_vod__c'};
	static final Set<String> ADDR_PHONE_FIELDS = new Set<String> {'Phone_vod__c', 'Phone_2_vod__c'};
	static final Set<String> ACCT_PHONE_FIELDS = new Set<String> {'Phone', 'AssistantPhone', 'OtherPhone', 'PersonHomePhone', 'PersonAssistantPhone', 'PersonOtherPhone', 'HomePhone', 'PersonMobilePhone'};

	@AuraEnabled(cacheable=true)
	public static List<Address_vod__c> getAccountAddresses(String accountId) {
		List<Address_vod__c> result = new List<Address_vod__c>();
		Map<String, SObjectField> descr = Address_vod__c.SObjectType.getDescribe().fields.getMap();
		List<String> fields = filterFields(descr, ADDRESS_FIELDS);
		result.addAll(fetchAddresses(accountId, fields));
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static List<String> getAccountFaxes(String accountId) {
		List<String> result = new List<String>();
		Map<String, SObjectField> descr = Account.SObjectType.getDescribe().fields.getMap();
		List<String> fields = filterFields(descr, ACCT_FAX_FIELDS);
		addValueFromAccount(accountId, fields, result);

		descr = Address_vod__c.SObjectType.getDescribe().fields.getMap();
		fields = filterFields(descr, ADDR_FAX_FIELDS);
		addValueFromAddress(accountId, fields, result);
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static List<String> getAccountPhones(String accountId) {
		List<String> result = new List<String>();
		Map<String, SObjectField> descr = Account.SObjectType.getDescribe().fields.getMap();
		List<String> fields = filterFields(descr, ACCT_PHONE_FIELDS);
		addValueFromAccount(accountId, fields, result);

		descr = Address_vod__c.SObjectType.getDescribe().fields.getMap();
		fields = filterFields(descr, ADDR_PHONE_FIELDS);
		addValueFromAddress(accountId, fields, result);
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static List<String> getAccountEmails(String accountId) {
		List<String> result = new List<String>();
		List<String> fields = new List<String>();
		for (SObjectField field : Account.SObjectType.getDescribe().fields.getMap().values()) {
			DescribeFieldResult descr = field.getDescribe();
			if (descr.getType() == DisplayType.EMAIL && descr.isAccessible()) {
				fields.add(descr.getName());
			}
		}
		addValueFromAccount(accountId, fields, result);
		return result;
	}

	@AuraEnabled
	public static List<String> getMedInqsByGroupId(String groupId) {
		List<String> result = new List<String>();
		for (Medical_Inquiry_vod__c obj : [select Id from Medical_Inquiry_vod__c where Group_Identifier_vod__c = :groupId]) {
			result.add(String.valueOf(obj.Id));
		}
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static String getSentEmailRecordTypeId() {
		RecordTypeInfo info = SObjectType.Sent_Email_vod__c.getRecordTypeInfosByDeveloperName().get('Medical_Inquiry_vod');
		if (info != null && info.isAvailable()) {
			return info.getRecordTypeId();
		}
		return null;
	}

	static List<String> filterFields(Map<String, SObjectField> descr, Set<String> names) {
		List<String> fields = new List<String>();
		for (String name : names) {
			SObjectField field = descr.get(name);
			if (field != null && field.getDescribe().isAccessible()) {
				fields.add(name);
			}
		}
		return fields;
	}

	static List<Address_vod__c> fetchAddresses(String accountId, List<String> fields) {
		if (fields.size() > 0) {
			String stmt = 'Select ' + String.join(fields, ',') + ' from Address_vod__c ' +
                'where Account_vod__c = :accountId and Inactive_vod__c = false';
			return Database.query(stmt);
		}
		return new List<Address_vod__c>();
	}

	static List<Account> fetchAccount(String accountId, List<String> fields) {
		if (fields.size() > 0) {
			String stmt = 'Select ' + String.join(fields, ',') + ' from Account where Id = :accountId';
			return Database.query(stmt);
		}
		return new List<Account>();
	}

	static void addValueFromAccount(String accountId, List<String> fields, List<String> result) {
		List<Account> accounts = fetchAccount(accountId, fields);
		addValues(accounts, fields, result);
	}

	static void addValueFromAddress(String accountId, List<String> fields, List<String> result) {
		List<Address_vod__c> addresses = fetchAddresses(accountId, fields);
		addValues(addresses, fields, result);
	}

	static void addValues(List<SObject> sobjects, List<String> fields, List<String> result) {
		for (SObject sobj : sobjects) {
			for (String name: fields) {
				String value = (String) sobj.get(name);
				if (!String.isBlank(value) && !result.contains(value)) {
					result.add(value);
				}
			}
		}
	}
}