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

public inherited sharing class VeevaDecimalNumberSyntaxValueParser extends VeevaSyntaxValueParser {

    public VeevaDecimalNumberSyntaxValueParser(VeevaSyntaxErrorMessageManager errorMessageManager) {
        super(errorMessageManager);
    }

    protected override boolean isValid(VeevaSyntaxToken token) {
        boolean isValid;
        if (operator != null && VeevaSyntaxToken.NOT_EQUALS.equals(operator) && VeevaSyntaxToken.NULL_VALUE_TOKEN.equals(token)) {
            isValid = true;
        } else {
            isValid = isDecimalNumber(token);
        }
        return isValid;
    }
}