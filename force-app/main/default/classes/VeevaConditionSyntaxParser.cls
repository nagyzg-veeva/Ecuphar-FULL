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
 * VeevaConditionSyntaxParser parses a condition from the tokens provided.
 *
 * Note that this condition parser requires surrounding parenthesis around each condition in order for the condition to be valid.
 * If a new condition parser is required then this class can be turned into an abstract class or interface based on the new condition parser's requirements.
 */
public inherited sharing class VeevaConditionSyntaxParser implements VeevaSyntaxParser {
    private final VeevaFieldSyntaxParser fieldParser;
    private final VeevaValueSyntaxParser valueParser;
    private final VeevaSyntaxErrorMessageManager errorMessageManager;

    /**
     * VeevaConditionSyntaxParser is made up of a field parser, value parser and VeevaSyntaxErrorMessageManager.
     */
    public VeevaConditionSyntaxParser(VeevaFieldSyntaxParser fieldParser, VeevaValueSyntaxParser valueParser, VeevaSyntaxErrorMessageManager errorMessageManager) {
        this.fieldParser = fieldParser;
        this.valueParser = valueParser;
        this.errorMessageManager = errorMessageManager;
    }

    /**
     * Parses a VeevaConditionToken given a List of VeevaSyntaxTokens and a starting index.
     *
     * The returned value may be valid or invalid with the appropriate error message for why the input tokens could not be parsed
     */
    public VeevaConditionToken parse(List<VeevaSyntaxToken> tokens, Integer index) {
        Integer startingIndex = index;
        VeevaConditionToken condition = null;

        // the field is not the first index but the index immediately after
        VeevaFieldToken field = fieldParser.parse(tokens, index + 1);
        // Note: The current needs of the condition parser requires parenthesis this instance will enforce parenthesis around the condition.
        // However, to remove the requirement of parenthesis around the conditions a strategy pattern may be implemented to remove this restriction.
        if (startsWithOpeningParenthesis(tokens, index) && field != null) {
            // increment one for parenthesis
            // increment one for field
            index += 2;
            condition = parserStartingWithParenthesis(field, tokens, startingIndex, index);
        } else {
            condition = generateConditionTokenWithSyntaxError(index, index, VeevaSyntaxToken.NULL_TOKEN, null, null);
        }
        return condition;
    }

    private VeevaConditionToken parserStartingWithParenthesis(VeevaFieldToken field, List<VeevaSyntaxToken> tokens, Integer startingIndex, Integer index) {
        VeevaConditionToken condition;
        if (field.isValid()) {
            condition = parserUsingValidField(field, tokens, startingIndex, index);
        } else {
            condition = new VeevaConditionToken(index, index, VeevaSyntaxToken.NULL_TOKEN, field, null);
            // the error message will be retrieved from field by VeevaConditionToken.getError 
            condition.setValid(false);
        }
        return condition;
    }

    private VeevaConditionToken parserUsingValidField(VeevaFieldToken field, List<VeevaSyntaxToken> tokens, Integer startingIndex, Integer index) {
        VeevaConditionToken condition = null;
        VeevaSyntaxToken nextOperator = nextOperatorToken(tokens, index, field);
        if (nextOperator != null) {
            condition = parseConditionWithAvailableOperator(field, nextOperator, tokens, startingIndex, index + 1);
        } else {
            condition = generateConditionTokenWithSyntaxError(index, index, VeevaSyntaxToken.NULL_TOKEN, field, null);
        }

        return condition;
    }

    private VeevaConditionToken parseConditionWithAvailableOperator(VeevaFieldToken field, VeevaSyntaxToken nextOperator, List<VeevaSyntaxToken> tokens,
                                                                     Integer startingIndex, Integer index) {
        VeevaConditionToken condition;
        if (index < tokens.size()) {
            valueParser.setField(field);
            valueParser.setOperator(nextOperator);
            VeevaValueToken value = valueParser.parse(tokens, index);
            if (value != null) {
                index = value.getEndingIndex();
            }
            if (endsWithClosingParenthesis(tokens, index)) {
                index++;
                condition = new VeevaConditionToken(startingIndex, index, nextOperator, field, value); 
            } else {
                condition = generateConditionTokenWithSyntaxError(startingIndex, index, nextOperator, field, value);
            }
        } else {
            condition = generateConditionTokenWithSyntaxError(startingIndex, index, nextOperator, field, null);
        }
        return condition;
    }

    private VeevaSyntaxToken nextOperatorToken(List<VeevaSyntaxToken> tokens, Integer index, VeevaFieldToken field) {
        VeevaSyntaxToken nextToken = null;
        if (index < tokens.size()) {
            nextToken = tokens.get(index);
            boolean isTokenSupportedOperatorForField = isTokenSupportedOperatorForField(nextToken, field);
            if (!isTokenSupportedOperatorForField) {
                nextToken.setValid(false);
                nextToken.setError(errorMessageManager.getOperatorNotSupportedError(nextToken, field.getFieldName()));

            }
        }
        return nextToken;
    }

    private boolean isTokenSupportedOperatorForField(VeevaSyntaxToken token, VeevaFieldToken field) {
        boolean isTokenSupportedOperator = false;
        List<VeevaSyntaxToken> supportedOperators = field.getSupportedOperators();

        if (supportedOperators != null && !supportedOperators.isEmpty()) {
            Integer index = 0;
            Integer supportedOperatorsSize = field.getSupportedOperators().size();

            while (index < supportedOperatorsSize && !isTokenSupportedOperator) {
                VeevaSyntaxToken supportedOperator = supportedOperators.get(index);
                // VeevaSyntaxToken checks that the text values are equal between the tokens
                isTokenSupportedOperator = supportedOperator.equals(token);
                index++;
            }
        }
        return isTokenSupportedOperator;
    }

    private boolean startsWithOpeningParenthesis(List<VeevaSyntaxToken> tokens, Integer index) {
        return index < tokens.size() && VeevaSyntaxToken.OPENING_PARENTHESIS.equals(tokens.get(index));
    }

    private boolean endsWithClosingParenthesis(List<VeevaSyntaxToken> tokens, Integer index) {
        return index < tokens.size() && VeevaSyntaxToken.CLOSING_PARENTHESIS.equals(tokens.get(index));
    }

    private VeevaConditionToken generateConditionTokenWithSyntaxError(Integer startingIndex, Integer endingIndex,
                                                                      VeevaSyntaxToken nextOperator, VeevaFieldToken field, VeevaValueToken value) {
        VeevaConditionToken condition = new VeevaConditionToken(startingIndex, endingIndex, nextOperator, field, value);
        condition.setValid(false);
        condition.setError(errorMessageManager.getSyntaxError());
        return condition;
    }
}