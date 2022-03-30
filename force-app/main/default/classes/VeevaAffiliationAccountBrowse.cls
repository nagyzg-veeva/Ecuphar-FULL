global without sharing class VeevaAffiliationAccountBrowse {
    private static String[] affiliationFields = new String[] {
        'From_Account_vod__c', 'From_Contact_vod__c', 'To_Account_vod__c',
        'To_Contact_vod__c', 'Role_vod__c', 'Influence_vod__c',
        'Comments_vod__c', 'Relationship_Strength_vod__c', 'Therapeutic_Area_vod__c',
        'To_Account_Name_vod__c', 'To_Account_Identifier_vod__c', 'To_Account_Record_Type_vod__c',
        'To_Account_Affiliation_Count_vod__c', 'Parent_vod__c'
    };

    public static sObject[] browse(String id) {
        UserAccessibleFields userAccessibleFields = new UserAccessibleFields();
        String userFlsFields = userAccessibleFields.get();

        sObject[] affiliationAccounts = Database.Query('SELECT ' + userFlsFields + ', Id FROM Affiliation_vod__c WHERE From_Account_vod__c = :id AND To_Account_vod__c != :id LIMIT 1001');

        return affiliationAccounts;
    }

    private with sharing class UserAccessibleFields {
        public String get() {
            List<String> userFields = new List<String>();

            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Affiliation_vod__c.fields.getMap();
            for(String field : VeevaAffiliationAccountBrowse.affiliationFields) {
                if(fields.get(field).getDescribe().isAccessible()) {
                    userFields.add(field);
                }
            }

            Veeva_Settings_vod__c vsc = VeevaSettings.getVeevaSettings();
            if(vsc != null && vsc.ENABLE_CUSTOM_RELATIONSHIP_FIELDS_vod__c == 1) {
                for(Schema.SObjectField field : fields.values()) {
                    Schema.DescribeFieldResult fieldDesc = field.getDescribe();
                    if(isCustomAttribute(fieldDesc)) {
                        userFields.add(fieldDesc.getName());
                    }
                }
            }
            
            return String.join(userFields, ',');
        }

        private boolean isCustomAttribute(Schema.DescribeFieldResult describeFieldResult) {
            return describeFieldResult.isAccessible() 
                && isPicklistType(describeFieldResult)
                && isNotDefaultField(describeFieldResult);
        }

        private boolean isPicklistType(Schema.DescribeFieldResult describeFieldResult) {
            return describeFieldResult.getType() == Schema.DisplayType.Picklist || describeFieldResult.getType() == Schema.DisplayType.MultiPicklist;
        }

        private boolean isNotDefaultField(Schema.DescribeFieldResult describeFieldResult) {
            return !VeevaAffiliationAccountBrowse.affiliationFields.contains(describeFieldResult.getName());
        }
    }
}