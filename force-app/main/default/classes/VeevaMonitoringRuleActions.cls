public without sharing class VeevaMonitoringRuleActions {
    // Note that the class specifies without sharing because it is used from within the context of VeevaMonitoringRuleTriggerHandler which as the name specifies, run as part of a trigger.
    // If this class is to be used elsewhere, update sharing, add appropriate field access checks and this comment appropriately.
    
	@testVisible static Date today = Date.today();

    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    private static Pattern emailPattern = Pattern.compile('^[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$');
    private static Map<String, Map<String, Boolean>> knownFieldType = new Map<String, Map<String, Boolean>>();
    private static String badStartDateMessage = 'Start Date cannot be in past. Please update value and try again.';
    private static String badEndDateMessage = 'End Date cannot be in past. Please update value and try again.';
    private static String fieldSetRequiredMessage = 'At least one \'Object Field\' must be defined in Field Set as part of Monitoring Rule';
    private static String textFieldsOnlyMessage = 'Only fields of type Text can be defined in Field Set.';
    private static String invalidEmailMessageTemplate = 'Invalid Email Address - {{1}}';
    private static String endDateBeforeStartDateMessage = 'End Date should be later than Start Date. Please update value and try again.';
    private static String duplicateFieldMessage = '{0} cannot be referenced more than once for the same Monitoring Rule.';

    public static void validateInitialValues(List<Monitoring_Rule_vod__c> newMonitoringRules)
    {
        List<Monitoring_Rule_vod__c> monitoringRulesWithBadStartDate = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithBadEndDate = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithoutFieldSet = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithNonTextFieldSet = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithBadEmail = new List<Monitoring_Rule_vod__c>();
        List<String> badEmailValues = new List<String>(); // paired with monitoringRulesWithBadEmail
        List<Monitoring_Rule_vod__c> monitoringRulesWithEndDateBeforeStartDate = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithDuplicateField = new List<Monitoring_Rule_vod__c>();
        List<String> duplicateFields = new List<String>(); // paired with monitoringRulesWithDuplicateField

        for (Monitoring_Rule_vod__c rule : newMonitoringRules) {
            // Check if start date is in the past
            if (today > rule.Start_Date_vod__c) {
                monitoringRulesWithBadStartDate.add(rule);
            }

            // Check if end date is set and in the past
            if (rule.End_Date_vod__c != null && today > rule.End_Date_vod__c) {
                monitoringRulesWithBadEndDate.add(rule);
            }

            // Validate field set
            validateFieldSetValue(rule, monitoringRulesWithoutFieldSet, monitoringRulesWithNonTextFieldSet, monitoringRulesWithDuplicateField, duplicateFields);

            // Validate emails
            validateEmails(rule, monitoringRulesWithBadEmail, badEmailValues);

            // Make sure end date is not sooner than start date if provided
            if (rule.End_Date_vod__c != null && rule.End_Date_vod__c < rule.Start_Date_vod__c) {
                monitoringRulesWithEndDateBeforeStartDate.add(rule);
            }
        }

        addErrorsToRulesIfNeeded(monitoringRulesWithBadStartDate, monitoringRulesWithBadEndDate, monitoringRulesWithoutFieldSet, monitoringRulesWithNonTextFieldSet, monitoringRulesWithBadEmail, badEmailValues, monitoringRulesWithEndDateBeforeStartDate, monitoringRulesWithDuplicateField, duplicateFields);
    }

    public static void validateUpdatedValues(List<Monitoring_Rule_vod__c> newMonitoringRules, List<Monitoring_Rule_vod__c> oldMonitoringRules, Map<ID, Monitoring_Rule_vod__c> newMonitoringRuleMap, Map<ID, Monitoring_Rule_vod__c> oldMonitoringRuleMap)
    {
        List<Monitoring_Rule_vod__c> monitoringRulesWithBadStartDate = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithBadEndDate = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithoutFieldSet = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithNonTextFieldSet = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithBadEmail = new List<Monitoring_Rule_vod__c>();
        List<String> badEmailValues = new List<String>(); // paired with monitoringRulesWithBadEmail
        List<Monitoring_Rule_vod__c> monitoringRulesWithEndDateBeforeStartDate = new List<Monitoring_Rule_vod__c>();
        List<Monitoring_Rule_vod__c> monitoringRulesWithDuplicateField = new List<Monitoring_Rule_vod__c>();
        List<String> duplicateFields = new List<String>(); // paired with monitoringRulesWithDuplicateField

        for (Monitoring_Rule_vod__c rule : newMonitoringRules) {
            ID id = rule.Id;

            // Check if start date is in the past and has been modified
            if (today > rule.Start_Date_vod__c && (rule.Start_Date_vod__c != oldMonitoringRuleMap.get(id).Start_Date_vod__c)) {
                monitoringRulesWithBadStartDate.add(rule);
            }

            // Check if end date is set and in the past and has been modified
            if (rule.End_Date_vod__c != null && today > rule.End_Date_vod__c && (rule.End_Date_vod__c != oldMonitoringRuleMap.get(id).End_Date_vod__c)) {
                monitoringRulesWithBadEndDate.add(rule);
            }

            // Validate field set
            validateFieldSetValue(rule, monitoringRulesWithoutFieldSet, monitoringRulesWithNonTextFieldSet, monitoringRulesWithDuplicateField, duplicateFields);

            // Validate emails
            validateEmails(rule, monitoringRulesWithBadEmail, badEmailValues);

            // Make sure end date is not sooner than start date if provided
            if (rule.End_Date_vod__c != null && rule.End_Date_vod__c < rule.Start_Date_vod__c) {
                monitoringRulesWithEndDateBeforeStartDate.add(rule);
            }
        }

        addErrorsToRulesIfNeeded(monitoringRulesWithBadStartDate, monitoringRulesWithBadEndDate, monitoringRulesWithoutFieldSet, monitoringRulesWithNonTextFieldSet, monitoringRulesWithBadEmail, badEmailValues, monitoringRulesWithEndDateBeforeStartDate, monitoringRulesWithDuplicateField, duplicateFields);
    }

    private static void initializeMessages()
    {
        List<Message_vod__c> allMessages = [SELECT Text_vod__c, Name, Language_vod__c FROM Message_vod__c WHERE Category_vod__c='ApprovedNotes' AND
                                            Name IN ('APPROVED_NOTES_START_DATE_VALIDATION', 'APPROVED_NOTES_END_DATE_VALIDATION', 'APPROVED_NOTES_FIELD_SET_REQUIRED', 'APPROVED_NOTES_FIELD_SET_VALIDATION', 'APPROVED_NOTES_INVALID_EMAIL_ADDRESS', 'APPROVED_NOTES_END_DATE_BEFORE_START_DATE', 'APPROVED_NOTES_DUPLICATE_FIELD_VALIDATION')
                                            AND Active_vod__c=true AND Language_vod__c IN (:UserInfo.getLanguage(), 'en_US') ORDER BY Language_vod__c];
        List<Message_vod__c> englishMessages = new List<Message_vod__c>();
        List<Message_vod__c> localizedMessages = new List<Message_vod__c>();

        // Sort messages into localized versus english buckets so we can apply them in correct order
        for (Message_vod__c message : allMessages) {
            if (message.Language_vod__c == UserInfo.getLanguage()) {
                localizedMessages.add(message);
            } else {
                // en_US
                englishMessages.add(message);
            }
        }
        // Override defaults with en_US messages if available
        updateErrorMessages(englishMessages);

        // Override with localized messages if available
        updateErrorMessages(localizedMessages);
    }

    private static void updateErrorMessages(List<Message_vod__c> messages) {
        for (Message_vod__c message : messages) {
            switch on message.Name {
                when 'APPROVED_NOTES_START_DATE_VALIDATION' {
                    badStartDateMessage = message.Text_vod__c;
                }
                when 'APPROVED_NOTES_END_DATE_VALIDATION' {
                     badEndDateMessage = message.Text_vod__c;
                }
                when 'APPROVED_NOTES_FIELD_SET_REQUIRED' {
                    fieldSetRequiredMessage = message.Text_vod__c;
                }
                when 'APPROVED_NOTES_FIELD_SET_VALIDATION' {
                    textFieldsOnlyMessage = message.Text_vod__c;
                }
                when 'APPROVED_NOTES_INVALID_EMAIL_ADDRESS' {
                    invalidEmailMessageTemplate = message.Text_vod__c;
                }
                when 'APPROVED_NOTES_END_DATE_BEFORE_START_DATE' {
                    endDateBeforeStartDateMessage = message.Text_vod__c;
                }
                when 'APPROVED_NOTES_DUPLICATE_FIELD_VALIDATION' {
                    duplicateFieldMessage = message.Text_vod__c;
                }
            }
        }
    }

    private static void addErrorsToRulesIfNeeded(List<Monitoring_Rule_vod__c> monitoringRulesWithBadStartDate, List<Monitoring_Rule_vod__c> monitoringRulesWithBadEndDate,
                                                 List<Monitoring_Rule_vod__c> monitoringRulesWithoutFieldSet, List<Monitoring_Rule_vod__c> monitoringRulesWithNonTextFieldSet,
                                                 List<Monitoring_Rule_vod__c> monitoringRulesWithBadEmail, List<String> badEmailValues,
                                                 List<Monitoring_Rule_vod__c> monitoringRulesWithEndDateBeforeStartDate, List<Monitoring_Rule_vod__c> monitoringRulesWithDuplicateField, List<String> duplicateFields)
    {
        if (monitoringRulesWithBadStartDate.isEmpty() && monitoringRulesWithBadEndDate.isEmpty() && monitoringRulesWithoutFieldSet.isEmpty() &&
            monitoringRulesWithNonTextFieldSet.isEmpty() && monitoringRulesWithBadEmail.isEmpty() &&
            monitoringRulesWithEndDateBeforeStartDate.isEmpty() && monitoringRulesWithDuplicateField.isEmpty()) {
            // No errors
            return;
        }

        initializeMessages();
        addErrorToRules(monitoringRulesWithBadStartDate, badStartDateMessage);
        addErrorToRules(monitoringRulesWithBadEndDate, badEndDateMessage);
        addErrorToRules(monitoringRulesWithoutFieldSet, fieldSetRequiredMessage);
        addErrorToRules(monitoringRulesWithNonTextFieldSet, textFieldsOnlyMessage);
        addBadEmailRuleErrorToRules(monitoringRulesWithBadEmail, badEmailValues);
        addErrorToRules(monitoringRulesWithEndDateBeforeStartDate, endDateBeforeStartDateMessage);
        addDuplicateFieldErrorToRules(monitoringRulesWithDuplicateField, duplicateFields);
    }

    private static void addErrorToRules(List<Monitoring_Rule_vod__c> rules, String message)
    {
        if (rules.size() > 0) {
            for (Monitoring_Rule_vod__c rule : rules)
            {
                rule.addError(message);
            }
        }
    }

    private static void addBadEmailRuleErrorToRules(List<Monitoring_Rule_vod__c> monitoringRulesWithBadEmail, List<String> badEmailValues)
    {
        if (monitoringRulesWithBadEmail.size() > 0) {
            for (Integer i = 0; i < monitoringRulesWithBadEmail.size(); i++) {
                String badEmails = badEmailValues[i];
                String errorMessage = invalidEmailMessageTemplate.replace('{{1}}', badEmails);
                monitoringRulesWithBadEmail[i].addError(errorMessage);
            }
        }
    }

    private static void addDuplicateFieldErrorToRules(List<Monitoring_Rule_vod__c> monitoringRulesWithDuplicateField, List<String> duplicateFields) {
        if (monitoringRulesWithDuplicateField.size() > 0) {
            for (Integer i = 0; i < monitoringRulesWithDuplicateField.size(); i++) {
                List<String> duplicateFieldList = new List<String>(); // create a new list from each field, since that's the parameter type for String.format()
                duplicateFieldList.add(duplicateFields[i]);
            	String errorMessage = String.format(duplicateFieldMessage, duplicateFieldList);
                monitoringRulesWithDuplicateField[i].addError(errorMessage);
            }
        }
    }

    private static void validateFieldSetValue(Monitoring_Rule_vod__c rule, List<Monitoring_Rule_vod__c> monitoringRulesWithoutFieldSet, List<Monitoring_Rule_vod__c> monitoringRulesWithNonTextFieldSet, List<Monitoring_Rule_vod__c> monitoringRulesWithDuplicateField, List<String> duplicateFields) {
            // Ensure field set value exists
            if (rule.Field_Set_vod__c == null || rule.Field_Set_vod__c.length() == 0) {
                monitoringRulesWithoutFieldSet.add(rule);
            }
            else {
                // Check that the field set values correspond to text fields and that there are no duplicates
				Set<String> uniqueFieldSets = new Set<String>();
                // Split to each field set pairing using the ;; delimiter
                List<String> fieldSets = rule.Field_Set_vod__c.split(';;');
                for (String fieldSet : fieldSets) {
                    // Split into object (0) and field name (1) using the . delimiter
                    String[] setSplit = fieldSet.split('\\.');

                    // Make sure fieldSet is correct format, otherwise fail validation
                    if (setSplit == null || setSplit.size() != 2) {
                        monitoringRulesWithNonTextFieldSet.add(rule);
                        break; // No need to continue
                    }

                    if (!isAllowedFieldType(setSplit[0], setSplit[1])) {
                        monitoringRulesWithNonTextFieldSet.add(rule);
                        break; // No need to continue
                    }

                    // Ensure each field set is unique
                    if (uniqueFieldSets.contains(fieldSet)) {
                        monitoringRulesWithDuplicateField.add(rule);
                        duplicateFields.add(fieldSet);
                        break; // No need to continue
                    } else {
                        uniqueFieldSets.add(fieldSet);
                    }
                }
            }
    }

    private static void validateEmails(Monitoring_Rule_vod__c rule, List<Monitoring_Rule_vod__c> monitoringRulesWithBadEmail, List<String> badEmailValues) {
        List<String> badEmails = new List<String>();

        if (rule.Email_Recipients_vod__c == null || rule.Email_Recipients_vod__c.length() == 0) {
            return;
        }

        // Gather the bad emails
        List<String> emails = rule.Email_Recipients_vod__c.split(',');
        for (String email : emails) {
            Matcher emailMatcher = emailPattern.matcher(email);
            if (!emailMatcher.matches()) {
                badEmails.add(email);
            }
        }

        // Add an error if at least one bad email was found
        if (badEmails.size() > 0) {
            String badEmailsAsString = String.join(badEmails, ',');
            monitoringRulesWithBadEmail.add(rule);
            badEmailValues.add(badEmailsAsString);
        }
    }

    private static Boolean isAllowedFieldType(String objectName, String fieldName)
    {
        // Check previously cached info
        Map<String, Boolean> fieldMap = knownFieldType.get(objectName);
        if (fieldMap == null) {
            // Haven't examined this object and field pairing previously, create the map and store
            fieldMap = new Map<String, Boolean>();
            knownFieldType.put(objectName, fieldMap);
        }
        Boolean allowedFieldType = fieldMap.get(fieldName);
        if (allowedFieldType == null) {
            // don't have it cached, need to calculate

            Boolean toReturn = false;
            Schema.DisplayType fieldType = getFieldType(objectName, fieldName);
            if (Schema.DisplayType.String == fieldType || Schema.DisplayType.TextArea == fieldType) {
                toReturn = true;
            }

            fieldMap.put(fieldName, toReturn);
            return toReturn;
        } else {
            return allowedFieldType;
        }
    }

    private static Schema.DisplayType getFieldType(String objectName, String fieldName)
    {
        Schema.DescribeSObjectResult describeObject = getDescribeResult(objectName);
        if (describeObject == null) {
            return null;
        }
        Schema.SObjectField field = describeObject.fields.getMap().get(fieldName);
        if (field == null) {
            return null;
        }
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        return fieldDescribe.getType();
    }

    private static Schema.DescribeSObjectResult getDescribeResult(String objectName)
    {
        Schema.DescribeSObjectResult toReturn = null;
        Schema.SObjectType objectType = globalDescribe.get(objectName);
        if (objectType != null) {
            Schema.DescribeSObjectResult describe = objectType.getDescribe();
            if (describe.isAccessible()) {
                toReturn = describe;
            }
        }
        return toReturn;
    }
}