public without sharing class VeevaChildAccountBrowse {
    public static String[] childAccountFields = new String[] {
        'Parent_Account_vod__c', 'Child_Account_vod__c', 'Primary_vod__c',
        'Child_Account_Identifier_vod__c', 'Child_Affiliation_Count_vod__c', 'Child_Name_vod__c',
        'Child_Record_Type_vod__c', 'Parent_Account_Identifier_vod__c', 'Parent_Affiliation_Count_vod__c',
        'Parent_Name_vod__c', 'Parent_Record_Type_vod__c', 'Parent_Child_Name_vod__c', 
        'Child_Account_Search_LastFirst_vod__c', 'Child_Furigana_vod__c'
    };

    public static sObject[] browse(String id) {
        UserAccessibleFields userAccessibleFields = new UserAccessibleFields();
        String userFlsFields = userAccessibleFields.get();

        sObject[] childAccounts = Database.Query('SELECT ' + userFlsFields + ', Id FROM Child_Account_vod__c WHERE Child_Account_vod__c = :id OR Parent_Account_vod__c = :id LIMIT 5001');

        return childAccounts;
    }

    private with sharing class UserAccessibleFields {
        public String get() {
            List<String> userFields = new List<String>();
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Child_Account_vod__c.fields.getMap();
            for(String field : VeevaChildAccountBrowse.childAccountFields) {
                if(fields.get(field).getDescribe().isAccessible()) {
                    userFields.add(field);
                }
            }
            return String.join(userFields, ',');
        }
    }
}