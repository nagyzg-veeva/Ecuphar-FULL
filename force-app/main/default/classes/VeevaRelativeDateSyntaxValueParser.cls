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
 * VeevaRelativeDateSyntaxValueParser is an concrete implementation of VeevaSyntaxValueParser. 
 *
 * This class defines an overriden parse method to handle the special logic around parsing relative dates.
 */
public inherited sharing class VeevaRelativeDateSyntaxValueParser extends VeevaSyntaxValueParser {
    
    private static final List<String> VALID_RELATIVE_DAYS = new List<String>{'yesterday', 'today', 'tomorrow'};
    private static final List<VeevaSyntaxToken> VALID_OPERATORS_FOR_RELATIVE_DATES_WITH_NUMBER = new List<VeevaSyntaxToken>{
        VeevaSyntaxToken.EQUALS,
        VeevaSyntaxToken.NOT_EQUALS,
        VeevaSyntaxToken.LESS_THAN
    };

    private final List<VeevaSyntaxToken> validRelativeDatePrefix;
    private final List<String> validUnitsOfTime;
    private final List<String> validPluralUnitsOfTime;

    /**
     * VeevaRelativeDateSyntaxValueParser is made up of a list of valid relative date prefixes (this, last), valid units of time, valid units of time (plural) and VeevaSyntaxErrorMessageManager.
     */
    public VeevaRelativeDateSyntaxValueParser(List<VeevaSyntaxToken> validRelativeDatePrefix, List<String> validUnitsOfTime,  List<String> validPluralUnitsOfTime,
                                                VeevaSyntaxErrorMessageManager errorMessageManager) {
        super(errorMessageManager);

        this.validRelativeDatePrefix = validRelativeDatePrefix;
        this.validUnitsOfTime = validUnitsOfTime;
        this.validPluralUnitsOfTime = validPluralUnitsOfTime;
        // To further improve VeevaRelativeDateSyntaxValueParser a set of expected patterns for relative date can be passed in in the future
    }

    /**
     * This method is overriden since the logical parsing of relative dates is not as simple as some of the other values being parsed
     */
    public override VeevaValueToken parse(List<VeevaSyntaxToken> tokens, Integer startingIndex) {
        VeevaValueToken parsedRelativeDate;
        VeevaSyntaxToken token = tokens.get(startingIndex);
        if (isRelativeDatePrefix(token)) {
            parsedRelativeDate = parseRelativeDateStartingWithPrefix(tokens, token, startingIndex + 1);
        } else {
            parsedRelativeDate = parseRelativeDayFromValue(token, startingIndex);
        }
        return parsedRelativeDate;
    }

    protected override boolean isValid(VeevaSyntaxToken token) {
        // this method will not be called by the abstract class since the parse method is overriden in this class
        // therefore this method is not used
        return false;
    }

    public VeevaValueToken parseRelativeDayFromValue(VeevaSyntaxToken token, Integer startingIndex) {
        VeevaValueToken relativeDay = new VeevaValueToken(startingIndex, token.getTokenText(), startingIndex + 1);
        if (!isValidRelativeDay(token)) {
            relativeDay.setValid(false);
            relativeDay.setError(getValueIsNotSupportedOrDoesNotExistForField(relativeDay, field.getFieldName()));
        }
        return relativeDay;
    }

    public VeevaValueToken parseRelativeDateStartingWithPrefix(List<VeevaSyntaxToken> tokens, VeevaSyntaxToken relativeDatePrefix, Integer index) {
        VeevaSyntaxToken relativeDateNumber;
        VeevaSyntaxToken unitOfTime;
        VeevaSyntaxToken nextToken = tokens.get(index++);
        if (isWholeNumber(nextToken)) {
            relativeDateNumber = nextToken;
            unitOfTime = isParenthetical(tokens.get(index)) ? null : tokens.get(index++);
        } else if (!isParenthetical(nextToken)) {
            relativeDateNumber = null;
            unitOfTime = nextToken;
        } else {
            relativeDateNumber = null;
            unitOfTime = null;
        }

        VeevaRelativeDateToken relativeDate = new VeevaRelativeDateToken(relativeDatePrefix.getStartingIndex(), relativeDatePrefix,
                                                                            relativeDateNumber, unitOfTime, index);
        if (relativeDate.getNumberToken() != null && !isValidRelativeDateWithNumber(relativeDate)) {
            relativeDate.setValid(false);
            relativeDate.setError(getValueIsNotSupportedOrDoesNotExistForField(relativeDate, field.getFieldName()));
        } else if (relativeDate.getNumberToken() == null && !isValidRelativeDate(relativeDate)) {
            // this is a relative date such as "this week"
            relativeDate.setValid(false);
            relativeDate.setError(getValueIsNotSupportedOrDoesNotExistForField(relativeDate, field.getFieldName()));
        }
        return relativeDate;
    }

    private boolean isParenthetical(VeevaSyntaxToken token) {
        return VeevaSyntaxToken.OPENING_PARENTHESIS.equals(token) || VeevaSyntaxToken.CLOSING_PARENTHESIS.equals(token);
    }

    private boolean isValidRelativeDate(VeevaRelativeDateToken value) {
        return isRelativeDatePrefix(value.getRelativeDatePrefixToken())
            && validUnitsOfTime.contains(value.getUnitOfTime().toLowerCase());
    }

    private boolean isValidRelativeDateWithNumber(VeevaRelativeDateToken value) {
        return hasValidOperatorForRelativeDateWithNumber() && VeevaRelativeDateToken.RELATIVE_DATE_PREFIX_LAST.equals(value.getRelativeDatePrefixToken())
            && isWholeNumber(value.getNumberToken())
            && validPluralUnitsOfTime.contains(value.getUnitOfTime().toLowerCase());
    }

    private boolean hasValidOperatorForRelativeDateWithNumber() {
        boolean containsValidOperator = false;
        Integer i = 0;
        while (i < VALID_OPERATORS_FOR_RELATIVE_DATES_WITH_NUMBER.size() && !containsValidOperator) {
            containsValidOperator = VALID_OPERATORS_FOR_RELATIVE_DATES_WITH_NUMBER.get(i).equals(operator);
            i++;
        }
        return containsValidOperator;
    }

    private boolean isValidRelativeDay(VeevaSyntaxToken value) {
        return VALID_RELATIVE_DAYS.contains(value.getTokenText().toLowerCase());
    }

    private boolean isRelativeDatePrefix(VeevaSyntaxToken value) {
        boolean isValidPrefix = false;
        Integer i = 0;
        while (i < validRelativeDatePrefix.size() && !isValidPrefix) {
            isValidPrefix = validRelativeDatePrefix.get(i).equals(value);
            i++;
        }
        return isValidPrefix;
    }

    private boolean isRelativeUnitOfTime(VeevaSyntaxToken value) {
        return validUnitsOfTime.contains(value.getTokenText().toLowerCase()); 
    }
}