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
 * The VeevaConditionToken is a child class implementation of VeevaSyntaxToken.
 *
 * This specific implementation defines a condition with supporting and overriden methods to retrieve information from the condition.
 */
public inherited sharing class VeevaConditionToken extends VeevaSyntaxToken {

    private VeevaFieldToken field;
    private VeevaValueToken value;
    private VeevaSyntaxToken operator;
    private Integer endingIndex;
    private Integer length;

    /**
     * A VeevaConditionToken is made up of a startingIndex, endingIndex, operator, field, and value.
     */
    public VeevaConditionToken(Integer startingIndex, Integer endingIndex, VeevaSyntaxToken operator, VeevaFieldToken field, VeevaValueToken value) {
        super(startingIndex, '');
        this.operator = operator;
        this.length = endingIndex - startingIndex;
        this.endingIndex = endingIndex;
        this.field = field;
        this.value = value;
    }

    /**
     * Overrides the base method to display the Condition's field, operator and value.
     */
    public override String getTokenText() {
        List<String> tokenTextParts = new List<String>();
        if (field != null && field.getTokenText().length() > 0) {
            tokenTextParts.add(field.getTokenText());
        }
        if (operator != null && operator.getTokenText().length() > 0) {
            tokenTextParts.add(operator.getTokenText());
        }
        if (value != null && value.getTokenText().length() > 0) {
            tokenTextParts.add(value.getTokenText());
        }
        return '(' + String.join(tokenTextParts, ' ') + ')';
    }

    /**
     * Overrides the base method to display an error were error messages for the field, operator, and value
     * will be appended if a specific error message is available. If a specific error was set using setError, that
     * error message will be used.
     */
    public override String getError() {
        String error = '';
        if (super.getError() != null && super.getError().length() > 0) {
            error = super.getError();
        } else {
            List<String> errors = new List<String>();
            if (field != null && !field.isValid()) {
                errors.add(field.getError());
            }
            if (operator != null && !operator.isValid() && !VeevaSyntaxToken.NULL_TOKEN.equals(operator)) {
                errors.add(operator.getError());
            }
            if (value != null && !value.isValid()) {
                errors.add(value.getError());
            }
            error = String.join(errors, ',');
        }
        return error;
    }

    public override Integer length() {
        return length;
    }

    /**
     * Gets the ending index of the condition from the List of VeevaSyntaxTokens the Condition was created from.
     */
    public Integer getEndingIndex() {
        return endingIndex;
    }

    public override boolean isValid() {
        return super.isValid()
            && field != null && field.isValid()
            && value != null && value.isValid()
            && operator != null && operator.isValid();
    }

    public VeevaFieldToken getField() {
        return field;
    }

    public VeevaSyntaxToken getOperator() {
        return operator;
    }

    public VeevaValueToken getValue() {
        return value;
    }

    public Schema.SObjectType getSObjectTypeForCondition() {
        return field != null ? field.getSObjectTypeOfObjectForField() : null;
    }

    public override String generateSOQL() {
        String fieldSOQL = field != null ? field.generateSOQL() : '';
        String operatorSOQL = operator != null ? operator.generateSOQL() : '';
        String valueSOQL = value != null ? value.generateSOQL() : '';
        String whereClauseSOQL = '';
        if (String.isNotBlank(fieldSOQL) && String.isNotBlank(operatorSOQL) && String.isNotBlank(valueSOQL)) {
            whereClauseSOQL = String.format('{0} {1} {2}', new String[]{fieldSOQL, operatorSOQL, valueSOQL});
        }
        return whereClauseSOQL;
    }
}