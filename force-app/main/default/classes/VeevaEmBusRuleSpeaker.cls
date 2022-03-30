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
 * VeevaEmBusRuleSpeaker Controller for speaker rules.
 */
@RestResource(urlMapping='/veeva/business-rule-speakers')
global without sharing class VeevaEmBusRuleSpeaker{
    
    @HttpPost
    global static VeevaEmBusRuleSpeakerService.SpeakerResult processSpeakerRules() {        
        VeevaEmBusRuleSpeakerService.SpeakerResult speakerResult = new VeevaEmBusRuleSpeakerService.SpeakerResult();
        RestResponse res = RestContext.response;
        Blob requestBody = RestContext.request.requestBody;
        try {
            if (requestBody != null) {
                String requestBodyStr = requestBody.toString();
                VeevaEmBusRuleSpeakerService.SpeakerRequest speakerRequest = (VeevaEmBusRuleSpeakerService.SpeakerRequest)JSON.deserialize(requestBodyStr, VeevaEmBusRuleSpeakerService.SpeakerRequest.class);
                VeevaEmBusRuleSpeakerService service = new VeevaEmBusRuleSpeakerService();  
                speakerResult = service.processSpeakerRules(speakerRequest);
            } else {
                VeevaEmBusRuleSpeakerService.setResponse(speakerResult, res, false, 'Request body is null', 400);
            }
        } catch (Exception e) {
            VeevaEmBusRuleSpeakerService.setResponse(speakerResult, res, false, e.getMessage(), 500);
        }
        return speakerResult;
    }
}