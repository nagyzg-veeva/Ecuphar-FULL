public without sharing class VeevaFilesOrgConfig implements VeevaOrgConfig{

    public Object getOrgConfiguration(){
        String profileId = UserInfo.getProfileId();
        List<Id> permissionSetIds = new List<Id>();
        for (PermissionSetAssignment assignment: [Select PermissionSetId from PermissionSetAssignment where AssigneeId =: UserInfo.getUserId()]) {
        	permissionSetIds.add(assignment.PermissionSetId);
        }

        String lightningExperienceField = 'PermissionsLightningExperienceUser';
        String chatterEnabledField = 'PermissionsChatterEnabledForUser';

        // Always query for the Lightning Experience User setting
        String fieldsToQuery = lightningExperienceField;


        Map<String, Schema.SObjectField> permSetFields = Schema.SObjectType.PermissionSet.fields.getMap();
		boolean containsChatterEnabled = permSetFields.containsKey(chatterEnabledField.toLowerCase());
        if (containsChatterEnabled) {
            fieldsToQuery = fieldsToQuery + ', ' + chatterEnabledField;
        }

        boolean isLightningExperienceUser = false;
        boolean isChatterEnabledUser = false;
        // Iterate through all permission sets (user-assigned or profile) to check for these permissions
        for (sObject permissionSet: Database.query('Select ' + fieldsToQuery + ' from PermissionSet where ProfileId = :profileId or Id IN :permissionSetIds')) {
            if ((boolean)permissionSet.get(lightningExperienceField)) {
                isLightningExperienceUser = true;
            }
            if (containsChatterEnabled && (boolean)permissionSet.get(chatterEnabledField)) {
                isChatterEnabledUser = true;
            }
        }

        return isLightningExperienceUser && (!containsChatterEnabled || isChatterEnabledUser);
    }
}