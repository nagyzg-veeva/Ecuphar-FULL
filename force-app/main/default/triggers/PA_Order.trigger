/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-25-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   11-25-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
trigger PA_Order on Order_vod__c (after insert, after update ) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            //PA_TRIGGER_Order.sapIdOrderLine(Trigger.new);
            //PA_TRIGGER_Order.updateTotalAmount(Trigger.new);            
        }
        if(Trigger.isUpdate){
            //PA_TRIGGER_Order.updateTotalAmount(Trigger.new);
        }
    }
}