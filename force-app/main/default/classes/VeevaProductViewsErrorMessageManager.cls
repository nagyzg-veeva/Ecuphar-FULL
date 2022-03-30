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
 * This class defines a Product View Implementation of VeevaSyntaxErrorMessageManager.
 *
 * This means that Product View specific error messages will be used when retrieving error messages when parsing syntax.
 */
public inherited sharing class VeevaProductViewsErrorMessageManager implements VeevaSyntaxErrorMessageManager {

    @TestVisible
    private static final String DEFAULT_SYNTAX_ERROR = 'Incorrect syntax. Make sure the clauses are opened and closed with parenthesis and that the object and field are separated by a period';
    @TestVisible
    private static final String DEFAULT_EMPTY_ERROR = 'The field Filter Criteria is not populated';
    @TestVisible
    private static final String DEFAULT_INVALID_FIELD_ERROR = 'The field {0} does not exist';
    @TestVisible
    private static final String DEFAULT_NOT_SUPPORTED_FIELD_ERROR = 'The field {0} is of a type that is not supported';
    @TestVisible
    private static final String DEFAULT_INVALID_VALUE_ERROR = 'The value {1} does not exist for the field {0}';
    @TestVisible
    private static final String DEFAULT_NOT_SUPPORTED_OPERATOR_ERROR = 'The selected operator {1} is not supported for {0}';

    private String syntaxError;
    private String emptyError;
    private String invalidFieldSyntaxError;
    private String notSupportedFieldError;
    private String invalidValueError;
    private String notSupportedOperatorError;

    public String getSyntaxError() {
        String error;
        if (syntaxError != null) {
            error = syntaxError;
        } else {
            error = VOD_VEEVA_MESSAGE.getMsgWithDefault('PRODUCT_VIEW_SYNTAX_ERROR', 'ORDER_MANAGEMENT', DEFAULT_SYNTAX_ERROR);
            syntaxError = error;
        }
        return error;
    }

    public String getInvalidFieldSyntaxError(String fieldName) {
        String error;
        if (invalidFieldSyntaxError != null) {
            error = invalidFieldSyntaxError;
        } else {
            error = VOD_VEEVA_MESSAGE.getMsgWithDefault('PRODUCT_VIEW_FIELD_ERROR', 'ORDER_MANAGEMENT', DEFAULT_INVALID_FIELD_ERROR);
            invalidFieldSyntaxError = error;
        }
        error = formatEscapingSingleQuotes(error, new List<String>{fieldName});
        return error;
    }

    public String getFieldNotSupportedError(String fieldName) {
        String error;
        if (notSupportedFieldError != null) {
            error = notSupportedFieldError;
        } else {
            error = VOD_VEEVA_MESSAGE.getMsgWithDefault('PRODUCT_VIEW_FIELD_TYPE_ERROR', 'ORDER_MANAGEMENT', DEFAULT_NOT_SUPPORTED_FIELD_ERROR);
            notSupportedFieldError = error;
        }
        error = formatEscapingSingleQuotes(error, new List<String>{fieldName});
        return error;
    }

    public String getValueNotSupportedError(VeevaSyntaxToken token, String fieldName) {
        String error;
        if (invalidValueError != null) {
            error = invalidValueError;
        } else {
            error = VOD_VEEVA_MESSAGE.getMsgWithDefault('PRODUCT_VIEW_FIELD_VALUE_ERROR', 'ORDER_MANAGEMENT', DEFAULT_INVALID_VALUE_ERROR);
            invalidValueError = error;
        }
        error = formatEscapingSingleQuotes(error, new List<String>{fieldName, token.getTokenText()});
        return error;
    }

    public String getOperatorNotSupportedError(VeevaSyntaxToken token, String fieldName) {
        String error;
        if (notSupportedOperatorError != null) {
            error = notSupportedOperatorError;
        } else {
            error = VOD_VEEVA_MESSAGE.getMsgWithDefault('PRODUCT_VIEW_OPERATOR_ERROR', 'ORDER_MANAGEMENT', DEFAULT_NOT_SUPPORTED_OPERATOR_ERROR);
            notSupportedOperatorError = error;
        }
        error = formatEscapingSingleQuotes(error, new List<String>{fieldName, token.getTokenText()});
        return error;
    }

    public String getEmptyError() {
        String error;
        if (emptyError != null) {
            error = emptyError;
        } else {
            error = VOD_VEEVA_MESSAGE.getMsgWithDefault('PRODUCT_VIEW_NO_FILTER_ERROR', 'ORDER_MANAGEMENT', DEFAULT_EMPTY_ERROR);
            emptyError = error;
        }
        return error;
    }

    private String formatEscapingSingleQuotes(String valueToFormat, List<String> formatParams) {
        // Apex's String.format uses Java's MessageFormat from my current understanding
        // because of this '{0}' will look like {0} after the format call.
        // So to prevent this we will have to use '' to escape the single quote to allow
        // single quotes in the string. For instance, ''{0}'' => 'some value passed in the format params'
        String escapeSingleQuotes = valueToFormat.replace('\'', '\'\'');
        return String.format(escapeSingleQuotes, formatParams); 
    }
}