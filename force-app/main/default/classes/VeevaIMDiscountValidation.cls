public class VeevaIMDiscountValidation {
    static String invalidName = VOD_VEEVA_MESSAGE.getMsgWithDefault('IM_FIELD_NAME_ERROR_vod','ORDER_MANAGEMENT',
                'Wrong field name! Please verify that the field name is a literal match of the existing field in Inventory Monitoring Lines');
    static String invalidType = VOD_VEEVA_MESSAGE.getMsgWithDefault('IM_FIELD_TYPE_ERROR_vod','ORDER_MANAGEMENT',
                    'Wrong field type! Please verify the IM field named used and its corresponding field value');
    static String invalidValue = VOD_VEEVA_MESSAGE.getMsgWithDefault('IM_FIELD_VALUE_ERROR_vod','ORDER_MANAGEMENT',
                  'Wrong field value! Please verify that the field value is a literal match of the existing field value in Inventory Monitoring Lines');
    //ONLY USED FOR UNIT TEST
    List<String> errorList;

    public VeevaIMDiscountValidation() {
    }
    public void checkFieldName(Set<String> fieldMap, String fieldName, Pricing_Subrule_vod__c priceSub)  {
        if (fieldName == null || fieldName.equals('')) {
            errorList.add(invalidName);
            priceSub.addError(invalidName);
            return;
        }
        //the field names are stored in lower case
        String noCaseFieldName = fieldName.toLowerCase();
        //check if the given object name exists in the Inventory Monitoring Line Object
        if (!fieldMap.contains(noCaseFieldName)) {
            errorList.add(invalidName);
            priceSub.addError(invalidName);
        }
    }
    public void checkFieldType(Set<Schema.DisplayType> validTypeMap, Schema.DisplayType fieldType, Pricing_Subrule_vod__c priceSub) {
        //check if the specified fieldType is a valid IMDiscount Type
        if (!validTypeMap.contains(fieldType)) {
            errorList.add(invalidType);
            priceSub.addError(invalidType);
        }
    }
    public void checkPicklistFieldValue(List<String> picklistValues, Schema.DisplayType fieldType, String fieldValue, Pricing_Subrule_vod__c priceSub) {
         if (fieldValue == null || fieldValue.equals('')) {
             errorList.add(invalidValue);
             priceSub.addError(invalidValue);
             return;
         }
         if (fieldType == Schema.DisplayType.Picklist) {
             if (!picklistValues.contains(fieldValue)) {
                  errorList.add(invalidValue);
                  priceSub.addError(invalidValue);
             }
         }
         else if (fieldType == Schema.DisplayType.MultiPicklist) {
             List<String> splitFieldValues = fieldValue.split(';', 0);
             if (splitFieldValues.size() != 0) {
                 for (String splitValue : splitFieldValues) {
                     if (!picklistValues.contains(splitValue)) {
                         errorList.add(invalidValue);
                         priceSub.addError(invalidValue);
                     }
                 }
             }
             else {
                 errorList.add(invalidValue);
                 priceSub.addError(invalidValue);
             }
         }
    }
    public void checkFieldValue(Schema.DisplayType fieldType, String fieldValue, Pricing_Subrule_vod__c priceSub) {
         if (fieldValue == null || fieldValue.equals('')) {
             errorList.add(invalidValue);
             priceSub.addError(invalidValue);
             return;
         }
         if (fieldType == Schema.DisplayType.Boolean) {
             //check against True, true, False, false, etc.
             String boolCheck = fieldValue.toLowerCase();
             if (!boolCheck.equals('true') && !boolCheck.equals('false')) {
                 errorList.add(invalidValue);
                 priceSub.addError(invalidValue);
             }
         }
         else if (fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Percent) {
             try {
                 String inputValue = fieldValue;
                 if (fieldType == Schema.DisplayType.Percent) {
                     //just to check if there exists a % (ascii value = 37) in the beginning of string
                     if (inputValue.indexOfChar(37) == 0 ) {
                         //to invalidate the double format
                         inputValue = inputValue.replaceFirst('%', 'a');
                     }
                     //will validate string if % is at the end. value unaffected if no % exists
                     inputValue = inputValue.replaceFirst('%', ' ');
                 }
                 Double.valueOf(inputValue);
             }
             catch (Exception e) {
                 errorList.add(invalidValue);
                 priceSub.addError(invalidValue);
             }
         }
    }
    private List<String> getPicklistValues(Schema.SObjectField field) {
        List<Schema.PicklistEntry> imPicklistValue = field.getDescribe().getPicklistValues();
        List<String> imPicklistString = new List<String>();
        for (Schema.PicklistEntry entry : imPicklistValue) {
            imPicklistString.add(entry.getValue());
        }
        return imPicklistString;
    }
    /*This method takes in the map containing the VeevaSObjectFieldWrapper objects as this allows us to use a mocked field map for unit tests
      in VeevaIMDiscountValidationTest. Schema.SObjectFields cannot be stubbed or mocked which would not allow unit tests on this method */
    public List<String> validatePricingRules(List<Pricing_Subrule_vod__c> newPriceSubs, Schema.DescribeSObjectResult validateObject) {
        errorList = new List<String>();
        Set<Schema.DisplayType> validImDiscountTypes = new Set<Schema.DisplayType>{Schema.DisplayType.Boolean,
            Schema.DisplayType.Double, Schema.DisplayType.Picklist, Schema.DisplayType.MultiPicklist,
            Schema.DisplayType.Percent};
        //grab all fields dynamically for Inventory Monitoring Line
        Map<String, Schema.SObjectField> imFields = validateObject.fields.getMap();
        for (Pricing_Subrule_vod__c priceSub : newPriceSubs) {

            String imLineField = priceSub.Inventory_Monitoring_Line_Field_vod__c;
            String imFieldValue = priceSub.Inventory_Monitoring_Field_Value_vod__c;

            //To avoid null pointer exceptions if imLineField is blank and if imFieldValue isn't blank
            if (imLineField == null || imLineField.equals('')) {
                if (imFieldValue != null && !imFieldValue.equals('')) {
                    errorList.add(invalidName);
                    priceSub.addError(invalidName);
                }
                continue;
            }
            else {
                checkFieldName(imFields.keySet(), imLineField, priceSub);
                //else if the field type does exist within the map, check if the type is valid for IM Discounts
                if (imFields.get(imLineField) != null) {
                    Schema.SObjectField validField = imFields.get(imLineField);
                    Schema.DisplayType imLineType = validField.getDescribe().getType();
                    checkFieldType(validImDiscountTypes, imLineType, priceSub);

                    //if field type is valid for IM discounts, check if field is a picklist or multipicklist
                    if (imLineType == Schema.DisplayType.Picklist || imLineType == Schema.DisplayType.MultiPicklist) {
                         List<String> imPickListString = getPicklistValues(validField);
                         checkPicklistFieldValue(imPickListString, imLineType, imFieldValue, priceSub);
                    }
                    //else if it is any of the other fields
                    else if (validImDiscountTypes.contains(imLineType)) {
                         checkFieldValue(imLineType, imFieldValue, priceSub);
                    }
                }
            }
        }
        return errorList;
    }
}