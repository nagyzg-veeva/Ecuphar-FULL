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
 * Product Views implementation of VeevaSyntaxValidator.
 */
public inherited sharing class VeevaProductViewSyntaxValidator implements VeevaSyntaxValidator {
    private final VeevaSyntaxTokenizer tokenizer;
    private final VeevaCompositeConditionSyntaxParser compositeConditionParser;

    private VeevaCompositeConditionToken compositeCondition;

    /**
     * VeevaProductViewSyntaxValidator uses a VeevaSyntaxTokenizer and VeevaCompositeConditionSyntaxParser.
     */
    public VeevaProductViewSyntaxValidator(VeevaSyntaxTokenizer tokenizer, VeevaCompositeConditionSyntaxParser compositeConditionParser) {
        this.tokenizer = tokenizer;
        this.compositeConditionParser = compositeConditionParser;
    }

    /**
     * Determines if a given syntax is valid. 
     */
    public boolean isValid(String syntax) {
        List<VeevaSyntaxToken> tokens = tokenizer.tokenize(syntax);
        compositeCondition = compositeConditionParser.parse(tokens, 0);
        return compositeCondition.isValid();
    }

    /**
     * Returns the error if the originally entered syntax when isValid was called was false.
     */
    public String getError() {
        return compositeCondition.getError();
    }
}