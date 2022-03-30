/*  @Author             :   Stephanie Dos Santos 
*   @Created            :   03 Mar 2020
*   @Description        :   Batch que actualiza el brick de las addres de las cuentas hijas(Porque está desactivado lo standart de veeva y aunque lanzaramos el batch las address que ya
*                           existen no tienen external id, solución momentanea mientras se define correctamente bricks).
*
*   Modification Log
*   ----------------------------------------------------------------------------------------------------------------------------
*   #       Developer               Date                    Description
*   ----------------------------------------------------------------------------------------------------------------------------    
*   1       Stephanie Dos Santos    03 Mar 2020             Creation
*   ----------------------------------------------------------------------------------------------------------------------------      
*/
global class PA_BATCH_DuplicateBrickChildAddress implements Database.Batchable<sObject>{
    String query;
    String brick;
    
    global PA_BATCH_DuplicateBrickChildAddress (String brick) {
        this.brick = brick;
        query='SELECT Child_Account_vod__c FROM Child_Account_vod__c where Parent_Account_vod__c IN (select account_vod__c from address_vod__c where Brick_vod__c =\''+brick+'\')';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> setAccount = new Set<Id>();
        list<Address_vod__c> listAddToUpdate = new list<Address_vod__c>();
        
        for(sObject itemScope : scope){
            Child_Account_vod__c accTemp = (Child_Account_vod__c)itemScope;
            setAccount.add(accTemp.Child_Account_vod__c);
        }
        
        if(!setAccount.isempty()){
            for(address_vod__c itemAdd : [select id , Brick_vod__c from address_vod__c where account_vod__c IN :setAccount]){
                if(itemAdd.Brick_vod__c == null){
                    itemAdd.Brick_vod__c = brick;
                    listAddToUpdate.add(itemAdd);
                }
            }
        }

        if(!listAddToUpdate.isempty()){
            system.debug('listAddToUpdate :'+listAddToUpdate);
            system.debug('listAddToUpdate size:'+listAddToUpdate.size());
            Database.update(listAddToUpdate);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }

}