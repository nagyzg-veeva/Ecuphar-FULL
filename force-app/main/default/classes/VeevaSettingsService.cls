/**
 * REST Web service providing API access to white-listed Veeva-specific Custom-settings objects.
 * Provides an alternative to direct querying if the "Restrict access to custom settings" feature is enabled
 * in Setup->Schema Settings. Users requiring external access then need to have access to this Apex class.
 **/
@RestResource(urlMapping='/veeva/settings/*')
global with sharing class VeevaSettingsService {

    global class VeevaSetting {
        global String name {get; set;}
        global String label {get; set;}
        global String labelPlural {get; set;}
        global String keyPrefix {get; set;}
        global SObject data {get; set;}
    }

    private static final Map<String, String> objNameToApiNameMap = new Map<String, String>();

    static {
        objNameToApiNameMap.put('common', 'Veeva_Common_vod__c');
        objNameToApiNameMap.put('veeva', 'Veeva_Settings_vod__c');
        objNameToApiNameMap.put('approved-email', 'Approved_Email_Settings_vod__c');
        objNameToApiNameMap.put('concur', 'Concur_Settings_vod__c');
        objNameToApiNameMap.put('events-management', 'Events_Management_Settings_vod__c');
        objNameToApiNameMap.put('global-account-search', 'Global_Account_Search_Settings_vod__c');
        objNameToApiNameMap.put('mobile', 'Mobile_CRM_Settings_vod__c');
        objNameToApiNameMap.put('multichannel', 'Multichannel_Settings_vod__c');
        objNameToApiNameMap.put('network', 'Network_Settings_vod__c');
        objNameToApiNameMap.put('portal', 'Portal_Settings_vod__c');
        objNameToApiNameMap.put('territory', 'Territory_Settings_vod__c');
        objNameToApiNameMap.put('vds', 'VDS_Settings_vod__c');
        objNameToApiNameMap.put('wechat', 'WeChat_Settings_vod__c');
    }

    @HttpGet
    global static List<VeevaSetting> getSettings() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        List<VeevaSetting> settingsList = new List<VeevaSetting>();
        String profileId = UserInfo.getProfileId();

        String objectName = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        Map<String, String> params = request.params;
        if (params != null && params.size() != 0 && Boolean.valueOf(params.get('deleted'))
            && objNameToApiNameMap.containsKey(objectName)) {
            addDeleted(objNameToApiNameMap.get(objectName), settingsList);
            return settingsList;
        }

		/* Last URL component, in general, should be the a lowercase version of the Settings object
		 * name, minus redundant noise like Veeva or CRM if it's included and the vod__c suffix.
		 * To keep standard REST URL naming conventions, use kebab-case rather than snake_case.
		 */
        switch on objectName {
            // First one is a "list" setting, and we're only returning 'Main'
            when 'common' {
                addIfNotNull(Veeva_Common_vod__c.getValues('Main'), settingsList);
            }
            // Rest of these are hierarchy settings.
            // As always, we are supporting only org and profile levels.
            when 'veeva' {
                addIfNotNull(Veeva_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Veeva_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'approved-email' {
                addIfNotNull(Approved_Email_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Approved_Email_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'concur' {
                addIfNotNull(Concur_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Concur_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'events-management' {
                addIfNotNull(Events_Management_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Events_Management_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'global-account-search' {
                addIfNotNull(Global_Account_Search_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Global_Account_Search_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'mobile' {
                addIfNotNull(Mobile_CRM_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Mobile_CRM_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'multichannel' {
                addIfNotNull(Multichannel_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Multichannel_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'network' {
                addIfNotNull(Network_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Network_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'portal' {
                addIfNotNull(Portal_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Portal_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'territory' {
                addIfNotNull(Territory_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(Territory_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'vds' {
                addIfNotNull(VDS_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(VDS_Settings_vod__c.getValues(profileId), settingsList);
            }
            when 'wechat' {
                addIfNotNull(WeChat_Settings_vod__c.getOrgDefaults(), settingsList);
                addIfNotNull(WeChat_Settings_vod__c.getValues(profileId), settingsList);
            }
            when '', 'settings' {
                // ends with either /settings or /settings/ - global describe
                settingsList.add(describe(Approved_Email_Settings_vod__c.sObjectType));
                settingsList.add(describe(Concur_Settings_vod__c.sObjectType));
                settingsList.add(describe(Events_Management_Settings_vod__c.sObjectType));
                settingsList.add(describe(Global_Account_Search_Settings_vod__c.sObjectType));
                settingsList.add(describe(Mobile_CRM_Settings_vod__c.sObjectType));
                settingsList.add(describe(Multichannel_Settings_vod__c.sObjectType));
                settingsList.add(describe(Network_Settings_vod__c.sObjectType));
                settingsList.add(describe(Portal_Settings_vod__c.sObjectType));
                settingsList.add(describe(Territory_Settings_vod__c.sObjectType));
                settingsList.add(describe(VDS_Settings_vod__c.sObjectType));
                settingsList.add(describe(Veeva_Common_vod__c.sObjectType));
                settingsList.add(describe(Veeva_Settings_vod__c.sObjectType));
                settingsList.add(describe(WeChat_Settings_vod__c.sObjectType));
            }
            when else {
            	// Unsupported value returns NOT FOUND and empty List
                response.statusCode = 404;
            }
        }
        return settingsList;
    }

    private static void addIfNotNull(SObject value, List<VeevaSetting> myList) {
        if (value != null) {
            Schema.DescribeSObjectResult describe = value.getSObjectType().getDescribe();
            VeevaSetting toAdd = describe(describe);
            toAdd.data = addEmptyFields(describe, value);
            myList.add(toAdd);
        }
    }

    private static VeevaSetting describe(Schema.SObjectType type) {
        return describe(type.getDescribe());
    }

    private static VeevaSetting describe(Schema.DescribeSObjectResult describe) {
        VeevaSetting setting = new VeevaSetting();
        setting.name = describe.name;
        setting.label = describe.label;
        setting.labelPlural = describe.labelplural;
        setting.keyPrefix = describe.keyprefix;
        return setting;
    }

    // Null values don't show up in REST output. This replaces null text values with empty string.
    private static SObject addEmptyFields(Schema.DescribeSObjectResult describe, SObject value) {
       List<Schema.SObjectField> fieldMap = describe.fields.getMap().values();
       for (Schema.SObjectField field : describe.fields.getMap().values()) {
           Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
           if (fieldDescribe.getSoapType() == Schema.SOAPType.String
               && value.get(field) == null) {
              value.put(field, '');
           }

       }
       return value;
    }

    // Adding deleted custom settings records
    private static void addDeleted(String objectApiName, List<VeevaSetting> myList) {
        SObject[] deleted = Database.query('SELECT Id FROM ' + objectApiName + ' WHERE isDeleted=true ALL ROWS');
        for (SObject each : deleted) {
            VeevaSetting setting = new VeevaSetting();
            setting.name = objectApiName;
            setting.data = each;
            myList.add(setting);
        }
    }

}