public inherited sharing class VeevaGASSearchCondition {
    private final Schema.SObjectType objectType;
    private final Schema.DescribeFieldResult field;
    private final VeevaGASSearchConditionOperator operator;
    private final String value;

    public VeevaGASSearchCondition(Implicit_Filter_Condition_vod__c filterCondition, Implicit_Filter_vod__c filter) {
        this.objectType = getObjectType(filterCondition.Object_Name_vod__c);
        this.field = getSObjectField(filterCondition.Field_Name_vod__c, this.objectType);
        this.operator = filter.Inclusion_vod__c ? VeevaGASSearchConditionOperator.EQUALS : VeevaGASSearchConditionOperator.NOT_EQUALS;
        this.value = filterCondition.Criteria_vod__c;
    }

    public VeevaGASSearchCondition(String objectApiName, String fieldApiName, String selectedOption) {
        this.objectType = getObjectType(objectApiName);
        this.field = getSObjectField(fieldApiName, this.objectType);
        this.operator = VeevaGASSearchConditionOperator.EQUALS;
        this.value = selectedOption;
    }

    public Schema.SObjectType getObject() {
        return objectType;
    }

    public String getObjectName() {
        return objectType.getDescribe().getName();
    }

    public Schema.DescribeFieldResult getField() {
        return field;
    }

    public String getFieldName() {
        return field.getName();
    }

    public VeevaGASSearchConditionOperator getOperator() {
        return operator;
    }

    public String getValue() {
        if (field.getType() == Schema.DisplayType.ID || field.getType() == Schema.DisplayType.STRING
            || field.getType() == Schema.DisplayType.PICKLIST || field.getType() == Schema.DisplayType.REFERENCE) {
            return '\'' + value + '\'';
        }
        return value;
    }

    private static Schema.SObjectType getObjectType(String objectName) {
        Type typeOfObject = Type.forName(objectName);
        Schema.SObjectType objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
        return objectType;
    }

    private static Schema.DescribeFieldResult getSObjectField(String fieldName, Schema.SObjectType objectType) {
        Schema.DescribeSObjectResult objectDescribeResult = objectType.getDescribe();
        return objectDescribeResult.fields.getMap().get(fieldName).getDescribe();
    }
}