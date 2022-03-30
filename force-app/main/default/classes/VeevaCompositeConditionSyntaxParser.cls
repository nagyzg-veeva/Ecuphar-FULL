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
 * VeevaCompositeConditionSyntaxParser parses a given List of VeevaSyntaxToken and transforms the VeevaSyntaxTokens into a VeevaCompositeConditionToken.
 */
public inherited sharing class VeevaCompositeConditionSyntaxParser implements VeevaSyntaxParser {

    private final VeevaConditionSyntaxParser conditionParser;
    private final VeevaSyntaxErrorMessageManager errorMessageManager;
    private final List<String> validJoiningOperators;

    /**
     * VeevaCompositeConditionSyntaxParser requires a VeevaConditionSyntaxParser to parse individual conditions, List of valid joining operators,
     * and a VeevaSyntaxErrorMessageManager to generate appropriate errors.
     *
     * Currently only AND is supported properly and nested expressions are not supported
     */
    public VeevaCompositeConditionSyntaxParser(VeevaConditionSyntaxParser conditionParser, List<String> validJoiningOperators, VeevaSyntaxErrorMessageManager errorMessageManager) {
        this.conditionParser = conditionParser;
        this.errorMessageManager = errorMessageManager;
        this.validJoiningOperators = validJoiningOperators;
    }

    /**
     * Given a List of tokens a VeevaCompositeConditionToken will be generated.
     *
     * The returned value may be valid or invalid with the appropriate error message for why the input tokens could not be parsed.
     */
    public VeevaCompositeConditionToken parse(List<VeevaSyntaxToken> tokens, Integer startingIndex) {
        VeevaCompositeConditionToken compositeCondition = new VeevaCompositeConditionToken(startingIndex);
        return parse(tokens, compositeCondition, startingIndex);
    }

    private VeevaCompositeConditionToken parse(List<VeevaSyntaxToken> tokens, VeevaCompositeConditionToken compositeCondition, Integer startingIndex) {
        if (compositeCondition.getConditions().size() > 0 && tokens.size() != startingIndex) {
            // not at the end of the syntax and there appears to be a another condition
            // the VeevaCompositeConditionTokenizer only recognizes supported relationship operators
            areConsecutiveTokensValid(tokens, compositeCondition, startingIndex);
        } else if (compositeCondition.getConditions().isEmpty() && tokens.size() != startingIndex) {
            parseCondition(tokens, compositeCondition, startingIndex);
        }
        // if none of the above match then we have completed parsing the tokens recursively
        validateCompositeCondition(compositeCondition);
        return compositeCondition;
    }

    private void validateCompositeCondition(VeevaCompositeConditionToken compositeCondition) {
        // validate that at least one condition was successfully added
        if (compositeCondition.getConditions().size() == 0) {
            compositeCondition.setValid(false);
            compositeCondition.setError(errorMessageManager.getEmptyError());
        }
    }
    
    private void areConsecutiveTokensValid(List<VeevaSyntaxToken> tokens, VeevaCompositeConditionToken compositeCondition, Integer startingIndex) {
        VeevaSyntaxToken nextToken = startingIndex < tokens.size() ? tokens.get(startingIndex) : VeevaSyntaxToken.NULL_TOKEN;
        if (validJoiningOperators.contains(nextToken.getTokenText().toLowerCase())) {
            parseCondition(tokens, compositeCondition, startingIndex + 1);
        } else {
            determineCauseOfParsingError(compositeCondition);
        }
    }

    private void parseCondition(List<VeevaSyntaxToken> tokens, VeevaCompositeConditionToken compositeCondition, Integer startingIndex) {
        VeevaConditionToken condition = conditionParser.parse(tokens, startingIndex);
        if (condition == null) {
            compositeCondition.setValid(false);
            compositeCondition.setError(errorMessageManager.getSyntaxError());
        } else {
            compositeCondition.addCondition(condition);
            parse(tokens, compositeCondition, condition.getEndingIndex());
        }
    }

    private void determineCauseOfParsingError(VeevaCompositeConditionToken compositeCondition) {
        // we do not need an else condition here since the error message will be retrieved from the tree
        // structure formed by VeevaCompositeConditionToken and its children
        if (compositeCondition.isValid()) {
            // if this is true then that means that none of the previously read tokens have an error
            // this means the current token has an error, at this context this is a syntax error
            compositeCondition.setValid(false);
            compositeCondition.setError(errorMessageManager.getSyntaxError());
        }
    }
}