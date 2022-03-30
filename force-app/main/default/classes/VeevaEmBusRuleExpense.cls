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
 * Copyright (c) 2021 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * VeevaEmBusRuleExpense Controller for expense rules.
 *
 */
@RestResource(urlMapping='/veeva/business-rule-expenses')
global without sharing class VeevaEmBusRuleExpense{
    
    @HttpPost
    global static VeevaEmExpenseRuleService.ExpenseResult processExpenseRules() {        
        VeevaEmExpenseRuleService.ExpenseResult expenseResult = new VeevaEmExpenseRuleService.ExpenseResult();
        RestResponse res = RestContext.response;
        Blob requestBody = RestContext.request.requestBody;
        try {
            if (requestBody != null) {
                String requestBodyStr = requestBody.toString();
                VeevaEmExpenseRuleService.ExpenseRequest expenseRequest = (VeevaEmExpenseRuleService.ExpenseRequest)JSON.deserialize(requestBodyStr, VeevaEmExpenseRuleService.ExpenseRequest.class);
                VeevaEmExpenseRuleService service = new VeevaEmExpenseRuleService();  
                expenseResult = service.processExpenseRules(expenseRequest);
            } else {
                VeevaEmExpenseRuleService.setResponse(expenseResult, res, false, 'Request body is null', 400);
            }
        } catch (Exception e) {
            VeevaEmExpenseRuleService.setResponse(expenseResult, res, false, e.getMessage(), 500);
        }
        return expenseResult;
    }
}