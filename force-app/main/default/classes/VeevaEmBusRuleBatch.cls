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
 * VeevaEmBusRuleBatch use batch apex to insert the event history data.
 *
 */
public class VeevaEmBusRuleBatch implements Database.Batchable<EM_Event_History_vod__c> {
    
    private List<EM_Event_History_vod__c> histories;

    public VeevaEmBusRuleBatch(List<EM_Event_History_vod__c> histories){
        this.histories = histories;
    }
    
    public Iterable<EM_Event_History_vod__c> start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return histories;
    }
    
    public void execute(Database.BatchableContext bc, List<EM_Event_History_vod__c> records){
        // process each batch of records
        Database.insert(records, VeevaEmBusRuleUtils.OPT_ALL_OR_NONE);
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}