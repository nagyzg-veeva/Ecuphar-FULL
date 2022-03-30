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

trigger VeevaProductViewTrigger on Product_View_vod__c(before insert, before update) {
    VeevaProductViewTriggerHandler triggerHandler = new VeevaProductViewTriggerHandler();
    switch on Trigger.operationType {
        when BEFORE_UPDATE, BEFORE_INSERT {
            triggerHandler.handleBeforeSaveNew(Trigger.new);
        }
        when else {
            // do nothing since we are only handling before insert and before update
        }
    }
}