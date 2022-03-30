trigger VEEVA_CREATE_ACCOUNT_FROM_DCR on Data_Change_Request_vod__c (after update) 
{
    set<Id> dcrIDs = new set<Id>();
    list<Data_Change_Request_Line_vod__c> dcrLines = new list<Data_Change_Request_Line_vod__c>();
    system.debug('----- DEBUG dcrLines -----: ' + dcrLines);
    
    //collect the DCR header IDs
    for(Data_Change_Request_vod__c dcr : trigger.new){
    system.debug('----- DEBUG CREATE ACCOUNT TRIGGER -----');
    Data_Change_Request_vod__c dcrOld = trigger.oldMap.get(dcr.Id);
        if(dcr.Status_vod__c == 'Processed_vod' && dcr.Parent_Data_Change_Request_vod__c == null && dcr.Provisional_Account_ID__c == null && dcrOld.Status_vod__c != 'Processed_vod' )
            dcrIds.add(dcr.Id);
    }
    //collect child DCR header record IDs if there is any
    for(Data_Change_Request_vod__c dcr_c : [select Id from Data_Change_Request_vod__c where Parent_Data_Change_Request_vod__c in: dcrIds]){
        dcrIds.add(dcr_c.Id);
    }
    //collect the DCR lines for all the DCR headers
    dcrLines = [select CreatedById, CreatedDate, Data_Change_Request_vod__c, Error_vod__c, External_Field_API_Name_vod__c, 
                       Field_API_Name_vod__c, Field_Name_vod__c, Final_Localized_Value_vod__c, Final_Value_vod__c, 
                       Id, IsDeleted, IsLocked, LastModifiedById, LastModifiedDate, MayEdit, 
                       Mobile_Created_Datetime_vod__c, Mobile_ID_vod__c, Mobile_Last_Modified_Datetime_vod__c, 
                       Name, New_Localized_Value_vod__c, New_Value_vod__c, Old_Localized_Value_vod__c, Old_Value_vod__c, 
                       OwnerId, Resolution_Note_vod__c, Result_vod__c, SystemModstamp 
                from   Data_Change_Request_Line_vod__c 
                where  Data_Change_Request_vod__c in: dcrIds];
                
    system.debug('----- DEBUG dcrIds -----: ' + dcrIds);
    system.debug('----- DEBUG dcrLines.size -----: ' + dcrLines.size());
                
    //pass DCR lines to the handler class to initiate the account creation process          
    if(dcrLines.size() != 0){
        VEEVA_CREATE_ACCOUNT_FROM_DCR DCR_handler = new VEEVA_CREATE_ACCOUNT_FROM_DCR(trigger.isExecuting, dcrLines.size());
        DCR_handler.BHC_onAfterInsert(dcrLines);
    }   
}