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

public inherited sharing class VeevaBooleanSyntaxValueParser extends VeevaSyntaxValueParser {

    private static final Set<String> validTokens = new Set<String>{'true', 'false'};

    public VeevaBooleanSyntaxValueParser(VeevaSyntaxErrorMessageManager errorMessageManager) {
        super(errorMessageManager);
    }

    public override boolean isValid(VeevaSyntaxToken token) {
        return validTokens.contains(token.getTokenText().toLowerCase());
    }
}