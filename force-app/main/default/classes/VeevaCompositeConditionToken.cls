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
 * The VeevaCompositeConditionToken is a child class implementation of VeevaSyntaxToken.
 *
 * This specific implementation defines a composite condition which contains a list of conditions (zero or more)
 * with supporting and overriden methods to retrieve information from the condition.
 */
public inherited sharing class VeevaCompositeConditionToken extends VeevaSyntaxToken {

    private final List<VeevaConditionToken> conditions;

    public VeevaCompositeConditionToken(Integer startingIndex) {
        super(startingIndex, '');
        this.conditions = new List<VeevaConditionToken>();
    }

    /**
     * Returns a String which is a comma-separated List of conditions texts
     */
    public override String getTokenText() {
        String compositeConditionText = '';
        for (Integer i = 0; i < conditions.size(); i++) {
            if (i > 0) {
                compositeConditionText += ',';
            }
            compositeConditionText += conditions.get(i).getTokenText();
        }
        return compositeConditionText;
    }

    public List<VeevaConditionToken> getConditions() {
        return conditions;
    }

    public void addCondition(VeevaConditionToken condition) {
        conditions.add(condition);
    }

    /**
     * Returns a comma-separated String with all available errors from each condition if there is no syntax errors when this composite condtion was created.
     * If, there was a syntax error when creating this composite condition only that error will be displayed.
     */
    public override String getError() {
        String error = '';
        Integer errorCount = 0;
        String priorErrorMessage = '';
        if (super.isValid() && !conditions.isEmpty()) {
            for (Integer i = 0; i < conditions.size(); i++) {
                String errorMessage = conditions.get(i).getError();
                if (!conditions.get(i).isValid() && errorMessage.length() > 0) {
                    if (!priorErrorMessage.equals(errorMessage)) {
                        if (errorCount > 0) {
                            error += ',';
                        }
                        error += errorMessage;
                        priorErrorMessage = errorMessage;
                        errorCount++;
                    }
                }
            }
        } else if (!super.isValid()) {
            error = super.getError();
        }
        return error;
    }

    /**
     * Checks if this composite is valid (meaning there is not a syntax error).
     * Then check if each condition in the composite condition is valid.
     */
    public override boolean isValid() {
        boolean areConditionsAvailableAndValid = super.isValid() && !conditions.isEmpty();
        for (Integer i = 0; areConditionsAvailableAndValid && i < conditions.size(); i++) {
            areConditionsAvailableAndValid = conditions.get(i).isValid();
        }
        return areConditionsAvailableAndValid;
    }
}