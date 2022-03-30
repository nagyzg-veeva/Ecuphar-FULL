/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2020 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * The VeevaFieldToken is a child class implementation of VeevaSyntaxToken.
 *
 * This specific implementation defines a field token with supporting and overriden methods to retrieve information from the field.
 */
public inherited sharing class VeevaFieldToken extends VeevaSyntaxToken {
    private final Schema.DescribeFieldResult fieldDescribe;
    private final String objectName;
    private final List<VeevaSyntaxToken> supportedOperators;

    /**
     * A VeevaFieldToken is made up of a startingIndex, objectName, fieldDescribe, and supported operators.
     */
    public VeevaFieldToken(Integer startingIndex, String objectName, Schema.DescribeFieldResult fieldDescribe, List<VeevaSyntaxToken> supportedOperators) {
        super(startingIndex, '');
        this.objectName = objectName;
        this.fieldDescribe = fieldDescribe;
        this.supportedOperators = supportedOperators;
    }

    /**
     * Returns a string representation of the objectname.fieldname.
     * Currently this method may through errors since it is assumed that this method will only be called when valid.
     */
    public override String getTokenText() {
        return getObjectName() + '.' + getFieldName();
    }

    public Schema.DisplayType getType() {
        return fieldDescribe.getType();
    }

    public String getObjectName() {
        return objectName;
    }
    
    public String getFieldName() {
        return fieldDescribe != null ? fieldDescribe.getName() : '';
    }
    public List<VeevaSyntaxToken> getSupportedOperators() {
        return supportedOperators;
    }

    public List<Schema.PicklistEntry> getPicklistValues() {
        return fieldDescribe.getPicklistValues();
    }

    public override String generateSOQL() {
        return getFieldName();
    }

    public Schema.SObjectType getSObjectTypeOfObjectForField() {
        // found that calling getGlobalDescribe will impact performance :
        // https://salesforce.stackexchange.com/questions/218982/why-is-schema-describesobjectstypes-slower-than-schema-getglobaldescribe/219010#219010
        Schema.SObjectType objectType;
        if (String.isNotBlank(objectName)) {
            Type typeOfObject = Type.forName(objectName);
            if (typeOfObject != null) {
                objectType = ((SObject) typeOfObject.newInstance()).getSObjectType();
            } else {
                objectType = ((SObject) Type.forName(objectName + '__c').newInstance()).getSObjectType();
            }
        } else {
            objectType = null;
        }
        return objectType;
    }

    /**
     * Retrieves the List of picklist entries that are supported by this field and checks if we allow non restrictive picklist values.
     *
     * If allowNonRestrictive is true, then we will check to see if a field which is a picklist is not a restrictive picklist. If it is not restrictive then we will allow all values through (true for anything).
     * Otherwise we return true if the passed in picklist value is in the PicklistEntry List.
     */
    public boolean containsPicklistValue(String picklistValue, boolean allowNonRestrictive) {
        boolean containsPicklistValue = false;
        if (fieldDescribe != null && fieldDescribe.getPicklistValues() != null) {
            containsPicklistValue = allowNonRestrictive && !fieldDescribe.isRestrictedPicklist();
            Integer index = 0;
            while (index < fieldDescribe.getPicklistValues().size() && !containsPicklistValue) {
                Schema.PicklistEntry picklistEntry = fieldDescribe.getPicklistValues().get(index);
                containsPicklistValue = picklistEntry.getValue().equals(picklistValue);
                index++;
            }
        }
        return containsPicklistValue;
    }
}