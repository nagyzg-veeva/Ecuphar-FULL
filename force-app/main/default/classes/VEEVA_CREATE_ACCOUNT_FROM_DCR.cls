/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 11-23-2021
 * @last modified by  : zoltan.nagy@veeva.com
 * Modifications Log 
 * Ver   Date         Author                  Modification
 * 1.0   06-15-2021   zoltan.nagy@veeva.com   Duplication Fixes
**/
public with sharing class VEEVA_CREATE_ACCOUNT_FROM_DCR 
{
    private Boolean BHC_isExecuting = false;
    private Integer BHC_batchSize = 0;
    public VEEVA_DCR_Helper_Functions dcrHelper = new VEEVA_DCR_Helper_Functions();
    private String BHC_Status_Provisional;
    public static Map<ID, Data_Change_Request_vod__c> mapDCRs = new Map<ID,Data_Change_Request_vod__c>();
    public static Map<ID, List<Data_Change_Request_Line_vod__c>> mapDCRLs = new Map<ID,List<Data_Change_Request_Line_vod__c>>();    
    public static Map<ID, Data_Change_Request_vod__c> mapParentDCRs = new Map<ID,Data_Change_Request_vod__c>();
    public static Map<ID, List<Data_Change_Request_Line_vod__c>> mapParentDCRLs = new Map<ID,List<Data_Change_Request_Line_vod__c>>();           
    //EB 2018-03-23:
    public static Map<ID, RecordType> mapRTs = new Map<ID,RecordType>();
    public static Map<ID, RecordType> mapAccountRTs = new Map<ID,RecordType>();
    public static Map<ID, RecordType> mapChildAccountRTs = new Map<ID,RecordType>();
    public static Map<ID, RecordType> mapAddressRTs = new Map<ID,RecordType>();
    public static Map<ID, RecordType> mapDCRRTs = new Map<ID,RecordType>();
    public static Set<ID> dcrsToAccept = new Set<Id>();
    // new map to track Address modifications without parent dcr
    public static Map<ID, ID> mapDCRAddress = new Map<ID,ID>();           


    public VEEVA_CREATE_ACCOUNT_FROM_DCR(Boolean BHC_isExecuting, Integer BHC_batchSize) {
        this.BHC_isExecuting = BHC_isExecuting;
        this.BHC_batchSize = BHC_batchSize;
        BHC_Status_Provisional = dcrHelper.getStatusCustomSetting('provisional');
        mapAccountRTs = dcrHelper.mapRecordTypeDeveloperNamesForObject('Account');
        //EB 2018-03-23
        mapChildAccountRTs = dcrHelper.mapRecordTypeDeveloperNamesForObject('Child_Account_vod__c');  
        mapAddressRTs = dcrHelper.mapRecordTypeDeveloperNamesForObject('Address_vod__c'); 
        mapRTs = dcrHelper.mapRecordTypeDeveloperNames();         
        mapDCRRTs = dcrHelper.mapRecordTypeDeveloperNamesForObject('Data_Change_Request_vod__c');        
    }
    
    public void BHC_onAfterInsert(List<Data_Change_Request_Line_vod__c> newDCRLs) {
        try {
            
            system.debug('##########  VEEVA_CREATE_ACCOUNT_FROM_DCR->  Size: ' +newDCRLs.size());
            system.debug('##########  VEEVA_CREATE_ACCOUNT_FROM_DCR->  Batch: ' +this.BHC_batchSize);
            //Map the DCRs with their Lines
            buildDCRMap(newDCRLs);
            //Lists for bulk upsert
            List<Account> newProvAccounts = new List<Account>();
            system.debug('##########  VEEVA_CREATE_ACCOUNT_FROM_DCR->  Account size: ' +newProvAccounts.size());
            List<Address_vod__c> newProvAddresses = new List<Address_vod__c>();
            system.debug('##########  VEEVA_CREATE_ACCOUNT_FROM_DCR->  Address size: ' +newProvAddresses.size());
            List<Child_Account_vod__c> newProvChildAccounts = new List<Child_Account_vod__c>();
            system.debug('##########  VEEVA_CREATE_ACCOUNT_FROM_DCR->  ChildAccount size: ' +newProvChildAccounts.size());
            Map<Id, Address_vod__c> mapDCRProvAddresses = new Map<Id, Address_vod__c>();
            Map<Id, Child_Account_vod__c> mapDCRProvChildAccounts = new Map<Id, Child_Account_vod__c>();
            List<Account_Territory_Loader_vod__c> newATLs = new List<Account_Territory_Loader_vod__c>();
            Map<Id, Data_Change_Request_vod__C> updatedDCRsMap = new Map<Id, Data_Change_Request_vod__c>();
            Map<Id, List<Data_Change_Request_vod__c>> mapDCRChildDCR = new Map<Id, List<Data_Change_Request_vod__c>>();
            Set<Id> parentAccountIds = new Set<Id>();
            Map<Id, String> parenAccountIdRtNameMap = new Map<Id, String>();
            Boolean enabledAccountRT = true; 

            for(Data_Change_Request_vod__c DCR: mapDCRs.values()){
                if (DCR.Account_vod__c != null) {
                    parentAccountIds.add(DCR.Account_vod__c);
                }
            }

            if (!parentAccountIds.isEmpty()) {
                for (Account a : [Select Id, RecordType.DeveloperName from Account WHERE Id IN :parentAccountIds]) {
                    parenAccountIdRtNameMap.put(a.Id, a.RecordType.DeveloperName);
                }
            }
            
            //go through in every DCR and create provisional account/address/child account
            //also update DCRs with the new provisional account id
            for(ID dcrId: mapDCRs.keySet()){
                //declare variables and empty objects
                Data_Change_Request_vod__c DCR = new Data_Change_Request_vod__c();
                List<Data_Change_Request_Line_vod__c> DCRLs = new List<Data_Change_Request_Line_vod__c>();                
                Integer fieldAdded = 0;
                DCR = mapDCRs.get(dcrId);
                system.debug('####### DCR-CREATE-ACCOUNT: DCR -> ' + DCR);
                DCRLs = mapDCRLs.get(dcrId);        
                system.debug('####### DCR-CREATE-ACCOUNT: DCR Lines-> ' + DCRLs);
                //Check if it is a new Add request
                if((DCR.Type_vod__c == 'New_vod' || DCR.Type_vod__c == 'Edit_vod') && (DCR.Status_vod__c == 'Processed_vod' || (DCR.Parent_Data_Change_Request_vod__r.Status_vod__c != null && DCR.Parent_Data_Change_Request_vod__r.Status_vod__c == 'Processed_vod')) ){
                    system.debug('####### DCR-CREATE-ACCOUNT: DCR is new and Submitted');
                    //2016.04.20 Adam Kercza <adam.kercza@veeva.com> 
                    //check that account in dcr/parent dcr  is a third party enabled record type, assuming that parent DCR always an account
                    //EB 2018-03-23: not Account as parent anymore.
                    List<Data_Change_Request_Line_vod__c> checkDCRLs = new List<Data_Change_Request_Line_vod__c>();                    
                    system.debug('####### Parent DCR: ' + DCR.Parent_Data_Change_Request_vod__c);
                    if(DCR.Parent_Data_Change_Request_vod__c != null)
                    {  
                       if(mapParentDCRLs.get(DCR.Parent_Data_Change_Request_vod__c) != NULL)
                          checkDCRLs = mapParentDCRLs.get(DCR.Parent_Data_Change_Request_vod__c);                       
                    }
                    else
                    {                        
                        checkDCRLs = DCRLs;
                    }

                    String rtName = mapDCRRTs.get(DCR.RecordTypeId).DeveloperName;
                    
                    system.debug('####### DCR-MAP_RTs: DCRLs ' + checkDCRLs.size());

                    // need to handle standalone Address DCRs separately
                    if (DCR.Parent_Data_Change_Request_vod__c == null && rtName.contains('Address') && DCR.Account_vod__c != null) {
                        enabledAccountRT = dcrHelper.isDCRRecordType(parenAccountIdRtNameMap.get(DCR.Account_vod__c));
                        System.debug('####### DCR-MAP_RTs: enabledAccountRT for Address: ' + enabledAccountRT);       
                    } else {
                        for(Data_Change_Request_Line_vod__c dcrl: checkDCRLs)
                        {                           
                            system.debug('####### DCR-MAP_RTs: DCRLs Item ' + dcrl);
                            if(dcrl.Field_API_Name_vod__c == 'RecordTypeId')
                            {                               
                                system.debug('####### DCR-MAP_RTs: DCRL Field API Name: ' + dcrl.Field_API_Name_vod__c);
                                system.debug('####### DCR-MAP_RTs: DCRL New Value: ' + dcrl.New_Value_vod__c);
                                system.debug('####### DCR-MAP_RTs: DCRL New Value: ' + mapAccountRTs);
                               
                                //EB 2018-03-23: Check if the RT is enbaled on the list of RT in the Veeva Message.
                                //String aRTName = mapAccountRTs.get(dcrl.New_Value_vod__c).DeveloperName;  
                                String aRTName = mapRTs.get(dcrl.New_Value_vod__c).DeveloperName;
                                String aRTObjName = mapRTs.get(dcrl.New_Value_vod__c).SObjectType; 
    
    
                                System.debug('####### DCR-MAP_RTs: Record type: ' + aRTObjName + ' - ' + aRTName);
                                //enabledAccountRT = dcrHelper.isDCRAccountRecordType(aRTName);
                                enabledAccountRT = dcrHelper.isDCRRecordType(aRTName); 
                                System.debug('####### DCR-MAP_RTs: enabledAccountRT: ' + enabledAccountRT);                           
                            }
                        }
                    }
                    
                    
                    //check if DCR has an enabled record type
                    // 2016-05-27 Adam Kercza <adam.kercza@veeva.com>
                    
                    //if the related account RT is not enabled in Custom Settings (BHC_UPA_provisional_account_settings__c) do not create anything 
                    if(enabledAccountRT)
                    {                        
                        //Check if DCR is a Child Account Object
                        if(rtName.contains('Child')){
                            system.debug('####### DCR-CREATE-CHILDACCOUNT: Creating Child Account');
                            Child_Account_vod__c provChildAccount;
                            
                            if(DCR.Type_vod__c == 'Edit_vod' && DCR.Child_Account_vod__c != null)
                                provChildAccount = new Child_Account_vod__c(Id=DCR.Child_Account_vod__c);
                            else
                                provChildAccount = new Child_Account_vod__c();   
                                                        
                            if(DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c != null){
                                provChildAccount.Child_Account_vod__c = DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c;
                            }
                            for(Data_Change_Request_Line_vod__c dcrl: DCRLs){
                                if(dcrHelper.isFieldExcluded(dcrl.Field_API_Name_vod__c, 'Child_Account_vod__c')){
                                    continue;
                                }
                                String FieldType = getFieldType('Child_Account_vod__c', dcrl.Field_API_Name_vod__c);
                                if(FieldType.toUpperCase() == 'BOOLEAN')   
                                    provChildAccount.put(dcrl.Field_API_Name_vod__c, Boolean.valueOf(dcrl.New_Value_vod__c));
                                //2021.11.23 Tamas Hrabovszki <tamas.hrabovszki@veeva.com>: integer/double/decimal values must also be handled
                                else if((FieldType.toUpperCase() == 'DOUBLE') && dcrl.New_Value_vod__c != NULL && (dcrl.New_Value_vod__c.length() > 0))
                                    provChildAccount.put(dcrl.Field_API_Name_vod__c, Decimal.valueOf(dcrl.New_Value_vod__c));   
                                //2016.05.11 Adam Kercza <adam.kercza@veeva.com>
                                else if((FieldType.toUpperCase() == 'DATE') && dcrl.New_Value_vod__c != NULL && (dcrl.New_Value_vod__c.length() > 0)) // CSABA Fix Null
                                    provChildAccount.put(dcrl.Field_API_Name_vod__c, Date.valueOf(dcrl.New_Value_vod__c));      
                                else if(FieldType.toUpperCase() == 'DATETIME')
                                    continue;                                   
                                else
                                    provChildAccount.put(dcrl.Field_API_Name_vod__c, dcrl.New_Value_vod__c);
                                fieldAdded ++;                              
                            }   
                            // child account will be added, check dcr
                            dcrsToAccept.add(dcrId);

                            //2016-05-27 Adam Kercza <adam.kercza@veeva.com>
                            provChildAccount.Activity_Status__c = BHC_Status_Provisional;
                            system.debug('####### DCR-CREATE-CHILDACCOUNT: provChildAccount: ' + provChildAccount);
                            system.debug('####### DCR-CREATE-CHILDACCOUNT: fields added: ' + fieldAdded);
                            system.debug('####### DCR-CREATE-CHILDACCOUNT: Prov account ID: ' + DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c);
                            
                            //handle scenario when DCR records are syched up separated (from Veeva Mobile)
                            if(DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c != null){
                                newProvChildAccounts.add(provChildAccount);
                                DCR.Provisional_Account_ID__c = DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c;
                                //updatedDCRs.add(DCR);
                                updatedDCRsMap.put(DCR.Id, DCR);
                            }
                            //handle New Child Account only request
                            else if(DCR.Parent_Data_Change_Request_vod__c == null){
                                newProvChildAccounts.add(provChildAccount);
                                DCR.Provisional_Account_ID__c = DCR.Account_vod__c;
                                //updatedDCRs.add(DCR);
                                updatedDCRsMap.put(DCR.Id, DCR);
                            } else {
                                mapDCRProvChildAccounts.put(DCR.Parent_Data_Change_Request_vod__c, provChildAccount);
                                //collect DCR for further processing after account created
                                if(mapDCRChildDCR.containsKey(DCR.Parent_Data_Change_Request_vod__c))
                                    mapDCRChildDCR.get(DCR.Parent_Data_Change_Request_vod__c).add(DCR);
                                else
                                    mapDCRChildDCR.put(DCR.Parent_Data_Change_Request_vod__c, new List<Data_Change_Request_vod__c>{DCR});
                            }
                            
                            //Check if DCR is an Address Object
                        }else if(rtName.contains('Address')){
                            system.debug('####### DCR-CREATE-ACCOUNT: Creating Address');
                            Address_vod__c provAddress;

                            if(DCR.Type_vod__c == 'Edit_vod' && DCR.Address_vod__c != null)
                                provAddress = new Address_vod__c(Id=DCR.Address_vod__c);
                            else {
                                provAddress = new Address_vod__c();
                            }
                         
                            
                            if(DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c != null){
                                provAddress.Account_vod__c = DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c;
                                system.debug('####### DCR-CREATE-ACCOUNT: Prov Address account ID: ' + provAddress.Account_vod__c);
                            }
                            

                            for(Data_Change_Request_Line_vod__c dcrl: DCRLs){   
                                if(dcrHelper.isFieldExcluded(dcrl.Field_API_Name_vod__c, 'Address_vod__c')){
                                    continue;
                                }
                                String FieldType = getFieldType('Address_vod__c', dcrl.Field_API_Name_vod__c);
                                if(FieldType.toUpperCase() == 'BOOLEAN')  { 
                                    provAddress.put(dcrl.Field_API_Name_vod__c, Boolean.valueOf(dcrl.New_Value_vod__c));
                                    system.debug('####### DCR-CREATE-ADDRESS: (Boolean) ' +dcrl.Field_API_Name_vod__c + ' - ' + dcrl.New_Value_vod__c);
                                    }
                                //2021.11.23 Tamas Hrabovszki <tamas.hrabovszki@veeva.com>: integer/double/decimal values must also be handled
                                else if((FieldType.toUpperCase() == 'DOUBLE') && dcrl.New_Value_vod__c != NULL && (dcrl.New_Value_vod__c.length() > 0)) {
                                    provAddress.put(dcrl.Field_API_Name_vod__c, Decimal.valueOf(dcrl.New_Value_vod__c)); 
                                    system.debug('####### DCR-CREATE-ADDRESS: (Double)' +dcrl.Field_API_Name_vod__c +' - ' + Decimal.valueOf(dcrl.New_Value_vod__c));    
                                    }  
                                //2016.05.11 Adam Kercza <adam.kercza@veeva.com>
                                else if((FieldType.toUpperCase() == 'DATE') && dcrl.New_Value_vod__c != NULL && (dcrl.New_Value_vod__c.length() > 0)) { //CSABA added middle && 
                                    provAddress.put(dcrl.Field_API_Name_vod__c, Date.valueOf(dcrl.New_Value_vod__c));
                                    system.debug('####### DCR-CREATE-ADDRESS: (Date)' +dcrl.Field_API_Name_vod__c +' - ' + Date.valueOf(dcrl.New_Value_vod__c));    
                                    }   
                                else if(FieldType.toUpperCase() == 'DATETIME')
                                    continue;                                   
                                else{
                                    provAddress.put(dcrl.Field_API_Name_vod__c, dcrl.New_Value_vod__c);
                                    system.debug('####### DCR-CREATE-ADDRESS: (Other)' +dcrl.Field_API_Name_vod__c +' - ' + dcrl.New_Value_vod__c);
                                    system.debug('####### DCR-CREATE-ADDRESS: (Other) DCRL' +dcrl);      
                                    } 
                                fieldAdded ++;
                            }    
                            // address will be added, check dcr
                            dcrsToAccept.add(dcrId);

                            //2016-05-27 Adam Kercza <adam.kercza@veeva.com>
                            provAddress.Status__c = BHC_Status_Provisional;
                            system.debug('####### DCR-CREATE-ADDRESS: provAddress: ' + provAddress);
                            system.debug('####### DCR-CREATE-ADDRESS: fields added: ' + fieldAdded);
                            system.debug('####### DCR-CREATE-ADDRESS: Parent Prov account ID: ' + DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c);
                            
                            if(DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c != null){
                                newProvAddresses.add(provAddress);
                                DCR.Provisional_Account_ID__c = DCR.Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c;    
                                //updatedDCRs.add(DCR);
                                updatedDCRsMap.put(DCR.Id, DCR);
                                system.debug('####### DCR-CREATE-ADDRESS: provAddress (if): ' + provAddress);
                                system.debug('####### DCR-CREATE-ADDRESS: Account ID: ' + DCR.Provisional_Account_ID__c);
                            } 
                            else if(DCR.Parent_Data_Change_Request_vod__c == null){
                                mapDCRProvAddresses.put(DCR.Id, provAddress); // Tamas 2021-11-24
                                newProvAddresses.add(provAddress);
                                
                                DCR.Provisional_Account_ID__c = DCR.Account_vod__c;
                                //updatedDCRs.add(DCR);
                                updatedDCRsMap.put(DCR.Id, DCR);
                            }
////////////////
                            else{
                                mapDCRProvAddresses.put(DCR.Parent_Data_Change_Request_vod__c, provAddress);
                                system.debug('####### DCR-CREATE-ADDRESS: DCRprovAddress (else): ' + mapDCRProvAddresses);
                                //collect DCR for further processing after account created
                                if(mapDCRChildDCR.containsKey(DCR.Parent_Data_Change_Request_vod__c)){
                                    system.debug('####### DCR-CREATE-ADDRESS: mapDCRChildDCR (if): ' + DCR.Parent_Data_Change_Request_vod__c);
                                    mapDCRChildDCR.get(DCR.Parent_Data_Change_Request_vod__c).add(DCR);
                                    system.debug('####### DCR-CREATE-ADDRESS: mapDCRChildDCR (if): ' + mapDCRChildDCR);
                                    }
                                else{
                                    mapDCRChildDCR.put(DCR.Parent_Data_Change_Request_vod__c, new List<Data_Change_Request_vod__c>{DCR});
                                    provAddress.Account_vod__c = DCR.Account_vod__c;
                                    provAddress.Id = DCR.Address_vod__c;
                                    newProvAddresses.add(provAddress);
                                    system.debug('####### DCR-CREATE-ADDRESS: mapDCRChildDCR (else): ' + mapDCRChildDCR);
                                    }
                                    
                            }
                       
                        
                            
                            //Other cases we supposing it is an Account Object
                        }
                        else
                        {                                               
                            system.debug('####### DCR-CREATE-ACCOUNT: Creating Account');
                            Account provAccount;
                            if(DCR.Type_vod__c == 'Edit_vod' && DCR.Account_vod__c != null)
                                provAccount = new Account(Id = DCR.Account_vod__c); 
                            else
                                provAccount = new Account();                                                            
                            //2016.04.20 CXFRA-1699 Adam Kercza <adam.kercza@veeva.com>
                            provAccount.Do_Not_Create_Child_Account_vod__c = true;
                            for(Data_Change_Request_Line_vod__c dcrl: DCRLs){                               
                                                          
                                //we can't modify these fields so skip them
                                if(dcrHelper.isFieldExcluded(dcrl.Field_API_Name_vod__c, 'Account')){
                                    continue;
                                }                            
                                String FieldType = getFieldType('Account', dcrl.Field_API_Name_vod__c);
                                if(FieldType.toUpperCase() == 'BOOLEAN')   
                                    provAccount.put(dcrl.Field_API_Name_vod__c, Boolean.valueOf(dcrl.New_Value_vod__c));
                                //2021.11.23 Tamas Hrabovszki <tamas.hrabovszki@veeva.com>: integer/double/decimal values must also be handled
                                else if((FieldType.toUpperCase() == 'DOUBLE') && dcrl.New_Value_vod__c != NULL && (dcrl.New_Value_vod__c.length() > 0))
                                    provAccount.put(dcrl.Field_API_Name_vod__c, Decimal.valueOf(dcrl.New_Value_vod__c));   
                                //2016.05.11 Adam Kercza <adam.kercza@veeva.com>
                                else if((FieldType.toUpperCase() == 'DATE') && dcrl.New_Value_vod__c != NULL && (dcrl.New_Value_vod__c.length() > 0)) //CSABA fix Null
                                    provAccount.put(dcrl.Field_API_Name_vod__c, Date.valueOf(dcrl.New_Value_vod__c));       
                                else if(FieldType.toUpperCase() == 'DATETIME')
                                    continue;                                   
                                else
                                    provAccount.put(dcrl.Field_API_Name_vod__c, dcrl.New_Value_vod__c);
                                fieldAdded ++;
                            }  
                            // account will be added, check dcr
                            dcrsToAccept.add(dcrId);
                             
                            //2016-05-27 Adam Kercza <adam.kercza@veeva.com>
                            provAccount.Status__c = BHC_Status_Provisional;
                            provAccount.Data_Change_Request__c = dcrId;
                            system.debug('####### DCR-CREATE-ACCOUNT: provAccount: ' + provAccount);
                            system.debug('####### DCR-CREATE-ACCOUNT: fields added: ' + fieldAdded);
                            newProvAccounts.add(provAccount); 
                                            
                        }
                    }   
                }
            }
            //upsert provisional account, address or child account  
            try {              
                System.debug('####### DCR-CREATE-ACCOUNT: Start UPSERTING lists');
                upsert(newProvAccounts);
                system.debug('####### DCR-CREATE-ACCOUNT newProvAccount: ' +newProvAccounts);    
                //List<Data_Change_Request_vod__c> DCRs = new List<Data_Change_Request_vod__c>(); 
                //after inserting the accounts we have some things to do
                for(Account a: newProvAccounts){
                    
                    //stamp DCR head with account id
                    Data_Change_Request_vod__c DCR = mapDCRs.get(a.Data_Change_Request__c);                
                    DCR.Provisional_Account_ID__c = a.Id; 
                    
                    if(DCR.Type_vod__c != 'Edit_vod') 
                    {
                        //Create/Update ATL record for account               
                        newATLs.add(setATLForAccount(a.Id, a.Territory_vod__c, true));
                    }
                    //2016-04-28 Adam Kercza <adam.kercza@veeva.com>
                    //CXANZ-3685 Prov acc id added to Account_vod__c field on DCR
                    DCR.Account_vod__c = a.id;

                    //stamping account id to prov address
                    if(mapDCRProvAddresses.containsKey(DCR.Id)){ //mapDCRChildDCR

                        Address_vod__c provAddr = mapDCRProvAddresses.get(DCR.Id);
                        provAddr.Account_vod__c = a.Id;
                        DCR.Address_vod__c = provAddr.id;

                        if (!newProvAddresses.contains(provAddr)) {
                            newProvAddresses.add(provAddr);
                        }
                    }
                    //stamping account id to prov child account
                    if(mapDCRProvChildAccounts.containsKey(DCR.Id)){
                        Child_Account_vod__c provCA = mapDCRProvChildAccounts.get(DCR.Id);
                        provCA.Child_Account_vod__c = a.Id;
                        DCR.Child_Account_vod__c = provCA.id;
                        newProvChildAccounts.add(provCA);
                    }
                    
                    //stamping account id to all related Child DCR
                    if(mapDCRChildDCR.containsKey(DCR.Id)){
                        for(Data_Change_Request_vod__c cdcr: mapDCRChildDCR.get(DCR.Id)){
                            cdcr.Provisional_Account_ID__c = a.Id;

                            //updatedDCRs.add(cdcr)
                            updatedDCRsMap.put(cdcr.Id, cdcr);
                        }
                    }                    
                    //updatedDCRs.add(DCR);
                    updatedDCRsMap.put(DCR.Id, DCR);
                }




                system.debug('####### DCR-CREATE-ACCOUNT: new accs: ' + newProvAccounts);
                upsert(newATLs);
                system.debug('####### DCR-CREATE-ACCOUNT: new addrs: ' + newProvAddresses);
                upsert(newProvAddresses);
                system.debug('####### DCR-CREATE-ACCOUNT: new cAccs: ' + newProvChildAccounts);
                upsert(newProvChildAccounts);


                //Update the DCR fields
                for(ID dcrId: mapDCRs.keySet()){
                    
                    Data_Change_Request_vod__c DCR = new Data_Change_Request_vod__c();
                    DCR = mapDCRs.get(dcrId);

                    //set DCR result
                    //DCR.Result_vod__c = 'CHANGE_ACCEPTED';
                    DCR.Result_vod__c = dcrsToAccept.contains(dcrId) ? 'CHANGE_ACCEPTED' : 'CHANGE_REJECTED';

                    system.debug('####### DCR-Update dcrId: ' + dcrId);
                    for(Address_vod__c add: newProvAddresses){
                        system.debug('####### DCR-Update addId: ' + add.Id);
                        DCR.Address_vod__c = add.Id;
                        //updatedDCRs.add(DCR);
                        updatedDCRsMap.put(DCR.Id, DCR);
                    }
                    for(Child_Account_vod__c ca: newProvChildAccounts){
                        DCR.Child_Account_vod__c = ca.Id;
                        //updatedDCRs.add(DCR);
                        updatedDCRsMap.put(DCR.Id, DCR);
                    }

                }


                system.debug('####### DCR-CREATE-ACCOUNT: updated DCRs: ' + updatedDCRsMap.values());
                update(updatedDCRsMap.values());
                
                
                
                
            }
            catch (System.DMLException BHC_e) {
                System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Unexpected DML error appeared.');
                System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Message ' + BHC_e.getMessage());
                System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Cause ' + BHC_e.getCause());
                System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Stacktrace ' + BHC_e.getStackTraceString());
            }
        } catch(Exception BHC_e) {
            System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Unexpected error appeared.');
            System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Message ' + BHC_e.getMessage());
            System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Cause ' + BHC_e.getCause());
            System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Stacktrace ' + BHC_e.getStackTraceString());
        }
    }
    
    //Creates a Map from DCR Lines containing every connected DCR with their lines in it
    //Only DCRs with more than 0 DCR Line
    //2016.04.20 Addig the parent DCR's also to the map, if they are existing for the new DCRs
    public static  void buildDCRMap(List<Data_Change_Request_Line_vod__c> newDCRLs){
        List<Id> dcrIds = New List<Id>();
        for(Data_Change_Request_Line_vod__c nDCRL: newDCRLs){
            dcrIds.add(nDCRL.Data_Change_Request_vod__c);            
        }
        
        Data_Change_Request_vod__c[] DCRs = getDCRs(dcrIds);
        //clare the list for storing parent ids
        dcrIds.clear();
        for(Data_Change_Request_vod__c DCR :DCRs){        
            if(DCR.Parent_Data_Change_Request_vod__c != null){
                dcrIds.add(DCR.Parent_Data_Change_Request_vod__c);
            }
            Integer LineSize = DCR.Data_Change_Request_Lines_vod__r.size();
            //system.debug('DCR = ' + DCR.Id + '  Items = ' + LineSize);            
            //add only  real  lines to Map 
            if(LineSize > 0){
                MapDCRs.put(DCR.Id, DCR);
                MapDCRLs.put(DCR.Id, DCR.Data_Change_Request_Lines_vod__r);
            }
        }        
        //add parent DCRs to map too if they exist
        if(dcrIds.size()>0){
            Data_Change_Request_vod__c[] parentDCRs = getDCRs(dcrIds);  
            for(Data_Change_Request_vod__c DCR :parentDCRs){ 
                Integer LineSize = DCR.Data_Change_Request_Lines_vod__r.size();
                //system.debug('DCR = ' + DCR.Id + '  Items = ' + LineSize);            
                //add only  real  lines to Map 
                if(LineSize > 0){
                    if(!mapDCRs.containsKey(DCR.Id)){
                        MapParentDCRs.put(DCR.Id, DCR);
                        MapParentDCRLs.put(DCR.Id, DCR.Data_Change_Request_Lines_vod__r);
                    }                    
                }
            }       
        }
        
        //system.Debug('MapDCRLs size = ' + MapDCRLs.size());   
    }
    
    //Get DCRs and related lines for DCR ids
    private static Data_Change_Request_vod__c[] getDCRs(List<Id> dcrIds){
        
        Data_Change_Request_vod__c[] DCRs = [SELECT Account_vod__c,Account_vod__r.ispersonaccount, Account_vod__r.recordTypeId, Account_vod__r.Do_Not_Call_vod__c,
                                                    Address_vod__c,Child_Account_vod__c,Createddate, Parent_Data_Change_Request_vod__r.Provisional_Account_ID__c,
                                                    External_Status_vod__c, Country_Mapping_vod__c, Parent_Data_Change_Request_vod__c,Parent_Data_Change_Request_vod__r.Status_vod__c, 
                                                    Sent_Datetime_vod__c,Mobile_Created_Datetime_vod__c,Date_Time_vod__c,
                                                    Status_vod__c,Type_vod__c,Result_vod__c, RecordTypeId,
                                             (SELECT Field_Name_vod__c,New_Value_vod__c,Field_API_Name_vod__c,Error_vod__c,
                                                     Resolution_Note_vod__c,Result_vod__c,
                                                     Mobile_Created_Datetime_vod__c,Createddate,
                                                     Data_Change_Request_vod__r.Account_vod__r.Do_Not_Call_vod__c,
                                                     Data_Change_Request_vod__r.Account_vod__r.ispersonaccount,
                                                     Data_Change_Request_vod__r.Account_vod__r.recordTypeId,
                                                     Data_Change_Request_vod__r.Child_Account_vod__r.Parent_account_vod__c
                                              FROM Data_Change_Request_Lines_vod__r)  
                                             FROM Data_Change_Request_vod__c where id in :dcrIds
                                            ];
        
        return DCRs;
    }
    
    private static  String getFieldType(String ObjName, String fieldName)
    {
        Map<String, Schema.SObjectField> M;        
        //system.debug('DCR-CREATE-ACCOUNT:  FieldType for ' + ObjName  +   ' and field: ' + fieldName);
        
        if(ObjName == 'Address_vod__c')
            M = Schema.SObjectType.Address_vod__c.fields.getMap();
        else if (ObjName == 'Account')
            M = Schema.SObjectType.Account.fields.getMap();
        else if (ObjName == 'Child_Account_vod__c')
            M = Schema.SObjectType.Child_Account_vod__c.fields.getMap();
        //else if (ObjName == 'bhc_GLOBAL_Change_Request_Persons__c')
        //    M = Schema.SObjectType.bhc_GLOBAL_Change_Request_Persons__c.fields.getMap();           
        //else if (ObjName == 'bhc_GLOBAL_Change_Request_Organization__c')
        //    M = Schema.SObjectType.bhc_GLOBAL_Change_Request_Organization__c.fields.getMap(); 
        
        Schema.SObjectField field = M.get(fieldName);
        if(field == NULL)
        {
            System.Debug('####### DCR-CREATE-ACCOUNT: No such field: ' + fieldName);  
            return null;
        }
        
        Schema.DisplayType FldType = field.getDescribe().getType();
        //system.Debug('DCR-CREATE-ACCOUNT:  Object = ' + ObjName + ' Field = ' + fieldName + ' type = ' + FldType);
        
        return String.valueof(FldType);
    }
    
    //create or update ATL record for Provisional Account
    //function can update/insert ATL directly, or returning the object for further processing
    // use returnOnly Boolean parameter
    public  static Account_Territory_Loader_vod__c  setATLForAccount(ID newAcctId, String terrString, Boolean returnOnly)
    {               
        // Check if the Account Territory Loader already exists
        List <Account_Territory_Loader_vod__c> atlList = [select Id, Territory_vod__c from Account_Territory_Loader_vod__c where Account_vod__c = :newAcctId] ;
        if (atlList.size() == 1) 
        {
            Account_Territory_Loader_vod__c atl = atlList[0] ;
            
            //set new ATL territory
            atl.Territory_vod__c = terrString ;     
            if(!returnOnly){
                try{
                    update (atl) ;                
                }            
                catch (System.DMLException BHC_e) {
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Unexpected DML error appeared.');
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Message ' + BHC_e.getMessage());
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Cause ' + BHC_e.getCause());
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Stacktrace ' + BHC_e.getStackTraceString());
                }
            }
            return atl;
        }
        else 
        {
            Account_Territory_Loader_vod__c atl = new Account_Territory_Loader_vod__c(Account_vod__c=newAcctId,External_ID_vod__c=newAcctId,Territory_vod__c=terrString);
            if(!returnOnly){
                try{
                    insert (atl);  
                }catch (System.DMLException BHC_e) {
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Unexpected DML error appeared.');
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Message ' + BHC_e.getMessage());
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Cause ' + BHC_e.getCause());
                    System.Debug('####### VEEVA_CREATE_ACCOUNT_FROM_DCR::Stacktrace ' + BHC_e.getStackTraceString());
                }
            }
            return atl;
        }   
    }
    
}