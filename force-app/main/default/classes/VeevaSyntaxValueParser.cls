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
 * VeevaSyntaxValueParser is an abstract class defining reused method across child classes. 
 *
 * This abstract class defines a parse method with an abstract isValid method. Each child class defines what it considers a valid, given a token.
 * The child class can also choose to override the parse logic contained within this class.
 *
 * The naming for this abstract class can use some work.
 */
public abstract class VeevaSyntaxValueParser implements VeevaSyntaxParser {

    private final VeevaSyntaxErrorMessageManager errorMessageManager;

    protected VeevaFieldToken field;
    protected VeevaSyntaxToken operator;

    public VeevaSyntaxValueParser(VeevaSyntaxErrorMessageManager errorMessageManager) {
        this.errorMessageManager = errorMessageManager;
    }

    public void setField(VeevaFieldToken field) {
        this.field = field;
    }

    public void setOperator(VeevaSyntaxToken operator) {
        this.operator = operator;
    }

    /**
     * Parses a given List of VeevaSyntaxTokens and a starting index the token is validated by the specific implementation of
     * isValid and then a VeevaValueToken is returned.
     * 
     * This method can also be overriden by a child class if additional behavior is required when parsing a value.
     */
    public virtual VeevaValueToken parse(List<VeevaSyntaxToken> tokens, Integer startingIndex) {
        VeevaSyntaxToken token = tokens.get(startingIndex);
        VeevaValueToken value = new VeevaValueToken(startingIndex, token.getTokenText(), startingIndex + 1);
        if (!isValid(token)) {
            value.setValid(false);
            value.setError(getValueIsNotSupportedOrDoesNotExistForField(value, field.getFieldName()));
        }
        return value;
    }

    protected abstract boolean isValid(VeevaSyntaxToken token);

    protected boolean isWholeNumber(VeevaSyntaxToken token) {
        boolean isAWholeNumber;
        try {
            Long longValue = Long.valueOf(token.getTokenText());
            isAWholeNumber = longValue != null;
        } catch (Exception ex) {
            isAWholeNumber = false;
        }

        return isAWholeNumber;
    }

    protected boolean isDecimalNumber(VeevaSyntaxToken token) {
        boolean isADecimalNumber;
        try {
            Decimal decimalValue = Decimal.valueOf(token.getTokenText());
            isADecimalNumber = decimalValue != null;
        } catch (Exception ex) {
            isADecimalNumber = false;
        }

        return isADecimalNumber;
    }

    protected boolean isLiteralText(VeevaSyntaxToken token) {
        // we just need to verify that the tokenizer considers this valid
        // and that the token starts and ends with single quotes (this means it's a literal)
        return token.isValid() && token.getTokenText().startsWith('\'')
            && token.getTokenText().endsWith('\'');
    }

    protected String getValueFromLiteralText(VeevaSyntaxToken token) {
        // remove surrounding single quotes
        return token.getTokenText().substring(1, token.getTokenText().length() - 1);
    }

    public String getValueIsNotSupportedOrDoesNotExistForField(VeevaSyntaxToken token, String fieldName) {
        return errorMessageManager.getValueNotSupportedError(token, fieldName);
    }
}