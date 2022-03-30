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

public with sharing class VeevaProductViewTriggerHandler {

    private final VeevaSyntaxValidator syntaxValidator;

    public VeevaProductViewTriggerHandler() {
        syntaxValidator = VeevaSyntaxValidatorFactory.generateProductViewSyntaxValidator();
    }
    
    public void handleBeforeSaveNew(List<Product_View_vod__c> productViews) {
        for (Integer i = 0; i < productViews.size(); i++) {
            validateFilterCriteria(productViews.get(i));
        }
    }

    private void validateFilterCriteria(Product_View_vod__c productView) {
        String filterCriteria = productView.Filter_Criteria_vod__c;
        if (!syntaxValidator.isValid(filterCriteria)) {
            productView.Filter_Criteria_vod__c.addError(syntaxValidator.getError());
        }
    }
}