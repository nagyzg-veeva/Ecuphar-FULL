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
 * VeevaValueSyntaxParser parses a Field from token provided
 */
public inherited sharing class VeevaFieldSyntaxParser implements VeevaSyntaxParser {

    private final List<String> supportedObjects;
    private final List<Schema.DisplayType> supportedFieldTypes;
    private final Map<Schema.DisplayType, List<VeevaSyntaxToken>> fieldToSupportedOperators;
    private final VeevaSyntaxErrorMessageManager errorMessageManager;

    /**
     * A VeevaFieldSyntaxParser is made up of a supported objects, supported field types, a map of field types to supported operators and VeevaSyntaxErrorMessageManager
     */
    public VeevaFieldSyntaxParser(List<String> supportedObjects, List<Schema.DisplayType> supportedFieldTypes,
                                    Map<Schema.DisplayType, List<VeevaSyntaxToken>> fieldToSupportedOperators, VeevaSyntaxErrorMessageManager errorMessageManager) {
        this.supportedObjects = supportedObjects;
        this.supportedFieldTypes = supportedFieldTypes;
        this.fieldToSupportedOperators = fieldToSupportedOperators;
        this.errorMessageManager = errorMessageManager;
    }

    /**
     * Parses a VeevaFieldToken given a List of VeevaSyntaxTokens and a starting index.
     * 
     * The returned value may be valid or invalid with the appropriate error message for why the input tokens could not be parsed
     */
    public VeevaFieldToken parse(List<VeevaSyntaxToken> tokens, Integer startingIndex) {
        VeevaFieldToken field = null;
        if (startingIndex < tokens.size()) {
            VeevaSyntaxToken token = tokens.get(startingIndex);
            Integer indexOfPeriod = token.getTokenText().indexOf('.');
            String objectName = '';
            String fieldName = '';
            if (indexOfPeriod > 0) {
                objectName = token.getTokenText().substring(0, indexOfPeriod);
                fieldName = token.getTokenText().substring(indexOfPeriod + 1);
            }
            if (objectName.length() > 0 && fieldName.length() > 0 && !fieldName.startsWith('.')) {
                field = parseFieldWith(token, objectName, fieldName, startingIndex);
            } else {
                field = getNotValidField(token, startingIndex);
            }
        }
        return field;
    }

    private VeevaFieldToken getNotValidField(VeevaSyntaxToken token, Integer startingIndex) {
        VeevaFieldToken field = new VeevaFieldToken(startingIndex, token.getTokenText(), null, new List<VeevaSyntaxToken>());
        field.setValid(false);
        field.setError(errorMessageManager.getSyntaxError());
        return field;
    }

    private boolean isTerminalToken(VeevaSyntaxToken token) {
        boolean isTerminal = false;
        Integer i = 0;
        while (i < VeevaSyntaxToken.TERMINALS.size() && !isTerminal) {
            // VeevaSyntaxToken checks to see if the token text's are equal
            isTerminal = VeevaSyntaxToken.TERMINALS.get(i).equals(token);
            i++;
        }
        return isTerminal;
    }

    private VeevaFieldToken parseFieldWith(VeevaSyntaxToken token, String objectName, String fieldName, Integer startingIndex) {
        VeevaFieldToken field = null;
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
        if (fieldDescribe != null && fieldDescribe.isAccessible()) {
            if (isSupportedObject(objectName)) {
                field = parseFieldForSupportedFieldType(objectName, fieldDescribe, startingIndex);
            } else {
                field = new VeevaFieldToken(startingIndex, objectName, null, new List<VeevaSyntaxToken>());
                field.setValid(false); 
                field.setError(errorMessageManager.getFieldNotSupportedError(token.getTokenText()));
            }
        } else {
            field = new VeevaFieldToken(startingIndex, objectName, fieldDescribe, new List<VeevaSyntaxToken>());
            field.setValid(false);
            field.setError(errorMessageManager.getInvalidFieldSyntaxError(token.getTokenText()));
        }
        return field;
    }

    private VeevaFieldToken parseFieldForSupportedFieldType(String objectName, Schema.DescribeFieldResult fieldDescribe, Integer index) {
        VeevaFieldToken field = null;
        Schema.DisplayType fieldType = fieldDescribe.getType();
        field = new VeevaFieldToken(index, objectName, fieldDescribe, fieldToSupportedOperators.get(fieldType));
        if (!supportedFieldTypes.contains(fieldType)) {
            field.setValid(false);
            field.setError(errorMessageManager.getFieldNotSupportedError(field.getFieldName()));
        }
        return field;
    }

    private boolean isSupportedObject(String objectName) {
        return supportedObjects.contains(objectName.toLowerCase());
    }

    private Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = null;
        try {
            Schema.DescribeSObjectResult objectDescribeResult = getObjectDescribe(objectName);
            if (objectDescribeResult != null) {
                Map<String, Schema.SObjectField> fieldMap = objectDescribeResult.fields.getMap();
                Schema.SObjectField sObjectField = fieldMap.get(fieldName);
                if (sObjectField != null) {
                    fieldDescribe = sObjectField.getDescribe();
                }
            }
        } catch (Exception ex) {
            fieldDescribe = null;
        }
        return fieldDescribe;
    }

    private Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objectDescribeResult = null;
        if (sObjectType != null) {
            objectDescribeResult = sObjectType.getDescribe();
            if (objectDescribeResult.isCustom()) {
                objectDescribeResult = null;
            }
        } else {
            sObjectType = Schema.getGlobalDescribe().get(objectName + '__c');
            if (sObjectType != null) {
                objectDescribeResult = sObjectType.getDescribe();
            }
        }
        return objectDescribeResult;
    }
}