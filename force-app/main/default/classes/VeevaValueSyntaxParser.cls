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
 * VeevaValueSyntaxParser follows the command pattern to retrieve an appropriate value parser based on the Schema.DisplayType.
 */
public inherited sharing class VeevaValueSyntaxParser implements VeevaSyntaxParser {

    private final Map<Schema.DisplayType, VeevaSyntaxValueParser> fieldTypeValueParsers;
    private final VeevaSyntaxErrorMessageManager errorMessageManager;

    private VeevaFieldToken field;
    private VeevaSyntaxToken operator;

    public VeevaValueSyntaxParser(Map<Schema.DisplayType, VeevaSyntaxValueParser> fieldTypeValueParsers, VeevaSyntaxErrorMessageManager errorMessageManager) {
        this.fieldTypeValueParsers = fieldTypeValueParsers;
        this.errorMessageManager = errorMessageManager;
    }

    /**
     * A VeevaValueToken will be returned after parsing the given tokens and starting index.
     * The returned VeevaValueToken may be valid or invalid with an error message.
     */
    public VeevaValueToken parse(List<VeevaSyntaxToken> tokens, Integer startingIndex) {
        VeevaValueToken value = null;
        if (field != null) {
            VeevaSyntaxValueParser valueParser = fieldTypeValueParsers.get(field.getType());
            if (valueParser != null) {
                valueParser.setField(field);
                valueParser.setOperator(operator);
                value = valueParser.parse(tokens, startingIndex);
            }
            if (value == null) {
                value = getNotSupportedValue(startingIndex, field);
            }
        } else {
            value = getNotSupportedValue(startingIndex, field);
           
        }
        return value;
    }
    
    /**
     * The VeevaFieldToken must be set in order for the VeevaValueSyntaxParser to determine which specific value parser to use.
     */
    public void setField(VeevaFieldToken field) {
        this.field = field;
    }

    /**
     * The operator must also be set since this operator may impact if a value such as "null" is valid when parsing.
     */
    public void setOperator(VeevaSyntaxToken operator) {
        this.operator = operator;
    }

    private VeevaValueToken getNotSupportedValue(Integer startingIndex, VeevaFieldToken field) {
        VeevaValueToken value = new VeevaValueToken(startingIndex, '', startingIndex);
        String fieldName = field != null ? field.getFieldName() : '';
        value.setError(errorMessageManager.getValueNotSupportedError(value, fieldName));
        return value;
    }
}