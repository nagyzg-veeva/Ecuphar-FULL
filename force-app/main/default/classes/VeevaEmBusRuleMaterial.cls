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
 * VeevaEmBusRuleMaterial Controller for required event material rules.
 */
@RestResource(urlMapping='/veeva/business-rule-materials')
global without sharing class VeevaEmBusRuleMaterial{
    
    @HttpPost
    global static VeevaEmBusRuleMaterialService.MaterialResult processMaterialRules() {        
        VeevaEmBusRuleMaterialService.MaterialResult materialResult = new VeevaEmBusRuleMaterialService.MaterialResult();
        RestResponse res = RestContext.response;
        Blob requestBody = RestContext.request.requestBody;
        try {
            if (requestBody != null) {
                String requestBodyStr = requestBody.toString();
                VeevaEmBusRuleMaterialService.MaterialRequest materialRequest = (VeevaEmBusRuleMaterialService.MaterialRequest)JSON.deserialize(requestBodyStr, VeevaEmBusRuleMaterialService.MaterialRequest.class);
                VeevaEmBusRuleMaterialService service = new VeevaEmBusRuleMaterialService();  
                materialResult = service.processMaterialRules(materialRequest);
            } else {
                VeevaEmBusRuleMaterialService.setResponse(materialResult, res, false, 'Request body is null', 400);
            }
        } catch (Exception e) {
            VeevaEmBusRuleMaterialService.setResponse(materialResult, res, false, e.getMessage(), 500);
        }
        return materialResult;
    }
}