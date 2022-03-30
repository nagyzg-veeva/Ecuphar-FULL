public without sharing class VeevaDynamicAttributeActions {

    // CRM-192620 - moving the content of upserted picklist
    // values from the text area field to the text field
    public static void migratePicklistValues(List<Dynamic_Attribute_vod__c> das) {
        for (Dynamic_Attribute_vod__c da : das) {
            if (da.Dynamic_Attribute_Record_Type_vod__c == 'Picklist_vod') {
                String textAreaContent = da.Dynamic_Attribute_Value_Text_Area_vod__c;
                if (textAreaContent != null && textAreaContent.length() != 0) {
                    // possibly truncate to 255 characters
                    textAreaContent = textAreaContent.left(255);
                    // copy the text area content into the text area,
                    // overwriting anything that might already be in there
                    da.Dynamic_Attribute_Value_Text_vod__c = textAreaContent;
                    // blank out the text area
                    da.Dynamic_Attribute_Value_Text_Area_vod__c = null;
                }
            }
        }
    }

    public static Map<String, List<Dynamic_Attribute_vod__c>> groupByAccountAndConfig(List<Dynamic_Attribute_vod__c> das) {
        Map<String, List<Dynamic_Attribute_vod__c>> groups = new Map<String, List<Dynamic_Attribute_vod__c>>();
        for (Dynamic_Attribute_vod__c da : das) {
            String key = generateKey(da);
            List<Dynamic_Attribute_vod__c> bin = groups.get(key);
            if (bin == null) {
                bin = new List<Dynamic_Attribute_vod__c>();
                groups.put(key, bin);
            }
            bin.add(da);
        }
        return groups;
    }

    public static Dynamic_Attribute_vod__c findLastActive(List<Dynamic_Attribute_vod__c> das) {
        Dynamic_Attribute_vod__c lastActive = null;
        for (Dynamic_Attribute_vod__c check : das) {
            if (check.Active_vod__c == true) {
                lastActive = check;
            }
        }
        return lastActive;
    }

    // This method keeps track of the last active Dynamic Attribute record for every given
    // Account + DAC combination that comes through.
    //
    // The results are stored in the static lastActives map for later cleanup on insert
    public static void groupLastActives(List<Dynamic_Attribute_vod__c> das, Map<String, Dynamic_Attribute_vod__c> lastActives) {
        Map<String, List<Dynamic_Attribute_vod__c>> daGroups = VeevaDynamicAttributeActions.groupByAccountAndConfig(das);
        for (List<Dynamic_Attribute_vod__c> grouping : daGroups.values()) {
            // find the last DA in the change set that is marked active
            Dynamic_Attribute_vod__c lastActive = VeevaDynamicAttributeActions.findLastActive(grouping);
            if (lastActive != null) {
                String key = VeevaDynamicAttributeActions.generateKey(lastActive);
                lastActives.put(key, lastActive);
            }
        }
    }

    // This method builds a map of all Multi-Select Picklist Dynamic Attribute records for every given Account + DAC combination.
    //
    // The Map is used to delete inactive Mutli-Select Picklist during insert
    public static void groupMultiSelectConfigs(List<Dynamic_Attribute_vod__c> das, Map<String, Dynamic_Attribute_vod__c> multiSelectRecords) {
        Map<String, List<Dynamic_Attribute_vod__c>> daGroups = VeevaDynamicAttributeActions.groupByAccountAndConfig(das);
        for (List<Dynamic_Attribute_vod__c> grouping : daGroups.values()) {
            if (grouping.get(0).Dynamic_Attribute_Record_Type_vod__c == 'Multi_Select_Picklist_vod') {
                String key = VeevaDynamicAttributeActions.generateKey(grouping.get(0));
                multiSelectRecords.put(key, grouping.get(0));
            }
        }
    }

    public static void deleteInactiveDynamicAttributesRecord(Map<String, Dynamic_Attribute_vod__c> multiSelectRecords) {
        // build the sets of accounts and DACs involved
        Set<Id> accountIds = new Set<Id>();
        Set<Id> dacIds = new Set<Id>();
        for (Dynamic_Attribute_vod__c da : multiSelectRecords.values()) {
            	accountIds.add(da.Account_vod__c);
            	dacIds.add(da.Dynamic_Attribute_Configuration_vod__c);
        }
        List<Dynamic_Attribute_Configuration_vod__c> dacTrackChangesOff = 
            [Select Id, Track_Changes_vod__c
             from Dynamic_Attribute_Configuration_vod__c 
             Where Id in :dacIds
             and Track_Changes_vod__c = false];
        // get the DAs that are inactive, Multi-Select Picklist RT and track changes off for the accounts and configs
        List<Dynamic_Attribute_vod__c> deleteThese = new List<Dynamic_Attribute_vod__c>();
        for (Dynamic_Attribute_vod__c candidate :
             [Select Id, Account_vod__c, Dynamic_Attribute_Configuration_vod__c, Dynamic_Attribute_Record_Type_vod__c
              from Dynamic_Attribute_vod__c
              where Active_vod__c = false
              and Dynamic_Attribute_Record_Type_vod__c = 'Multi_Select_Picklist_vod'
              and Account_vod__c in :accountIds
              and Dynamic_Attribute_Configuration_vod__c in :dacTrackChangesOff]) {
              deleteThese.add(candidate);
        }
        delete deleteThese;
    }

    public static void maintainLastActives(Map<String, Dynamic_Attribute_vod__c> lastActives) {
        // build the sets of accounts and DACs involved in the last active groups
        // that aren't also the ones we want to keep active
        Set<Id> accountIds = new Set<Id>();
        Set<Id> dacIds = new Set<Id>();
        Set<Id> keepDaIds = new Set<Id>();
        for (Dynamic_Attribute_vod__c da : lastActives.values()) {
            accountIds.add(da.Account_vod__c);
            dacIds.add(da.Dynamic_Attribute_Configuration_vod__c);
            keepDaIds.add(da.Id);
        }
        // get the candidate DAs and compare to those we're keeping
        List<Dynamic_Attribute_vod__c> inactivateThese = new List<Dynamic_Attribute_vod__c>();
        for (Dynamic_Attribute_vod__c candidate :
             [Select Id, Account_vod__c, Dynamic_Attribute_Configuration_vod__c, Dynamic_Attribute_Record_Type_vod__c
              from Dynamic_Attribute_vod__c
              where Active_vod__c = true
              and Id not in :keepDaIds
              and Account_vod__c in :accountIds
              and Dynamic_Attribute_Configuration_vod__c in :dacIds]) {
            String candidateKey = VeevaDynamicAttributeActions.generateKey(candidate);
            if (lastActives.keySet().contains(candidateKey) && candidate.Dynamic_Attribute_Record_Type_vod__c != 'Multi_Select_Picklist_vod') {
                inactivateThese.add(candidate);
            }
        }
        for (Dynamic_Attribute_vod__c da : inactivateThese) {
            da.Active_vod__c = false;
        }
        update inactivateThese;
    }

    public static void preventChangingRecordType(List<Dynamic_Attribute_vod__c> newDAs, List<Dynamic_Attribute_vod__c> originalDAs) {
        for (Integer i = 0; i < newDAs.size(); i++) {
            Dynamic_Attribute_vod__c newDA = newDAs.get(i);
            Dynamic_Attribute_vod__c oldDA = originalDAs.get(i);

            if (!oldDA.Dynamic_Attribute_Record_Type_vod__c.equals(newDA.Dynamic_Attribute_Record_Type_vod__c)) {
                newDA.addError(VOD_GET_ERROR_MSG.getErrorMsgWithDefault('RECORD_TYPE_NOT_MODIFIABLE', 'Common',
                    '\'Record Type\' cannot be modified for any Dynamic Attribute Configuration records.'));
            }
        }
    }

    public static String generateKey(Dynamic_Attribute_vod__c da) {
        return da.Account_vod__c + '_' + da.Dynamic_Attribute_Configuration_vod__c;
    }
}