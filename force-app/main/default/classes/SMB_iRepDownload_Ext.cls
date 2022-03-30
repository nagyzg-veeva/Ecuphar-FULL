public with sharing class SMB_iRepDownload_Ext 
{

public Id accountId {get;set;}          // Account id. Taken from the button "Download to iRep" in Account layout
public List<Account> CCGs {get;set;} 

public SMB_iRepDownload_Ext(ApexPages.StandardController controller) 
{
        
    this.accountId=ApexPages.currentPage().getParameters().get('acct');             // ---------- Level 1        
    CCGs =  [SELECT Name FROM Account WHERE Id =:this.accountId];
    
}

public PageReference Submit(){
    // --------------------------------------------------    
    List<Child_Account_vod__c > AccountList;
    List<Child_Account_vod__c > AccountList2;
    List<String> ChildIds = new List <String>();

    System.debug('ACC ID ' + this.accountId );
    AccountList=[SELECT Child_Account_vod__r.Id, Child_Account_vod__r.Name FROM Child_Account_vod__c WHERE Parent_Account_vod__r.Id =:this.accountId]; // ---------- Level 2
    for (Child_Account_vod__c a: AccountList)
    {   
            System.debug('AccountList: ' + a.Child_Account_vod__r.Id);
            ChildIds.add(a.Child_Account_vod__r.Id);
    }    
    AccountList2= [SELECT Child_Account_vod__r.Id, Child_Account_vod__r.Name FROM Child_Account_vod__c WHERE Parent_Account_vod__r.Id=:ChildIds];
    AccountList.addall(AccountList2);
    
    // ---------- Level3
    ChildIds.clear();        
    for (Child_Account_vod__c a: AccountList2)
    {   
            System.debug('AccountList: ' + a.Child_Account_vod__r.Id);
            ChildIds.add(a.Child_Account_vod__r.Id);
    } 
    AccountList2 = [SELECT Child_Account_vod__r.Id, Child_Account_vod__r.Name FROM Child_Account_vod__c WHERE Parent_Account_vod__r.Id=:ChildIds];
    AccountList.addall(AccountList2);
    
    // ---------- Level4
    ChildIds.clear();        
    for (Child_Account_vod__c a: AccountList2)
    {   
            System.debug('AccountList: ' + a.Child_Account_vod__r.Id);
            ChildIds.add(a.Child_Account_vod__r.Id);
    } 
    AccountList2 = [SELECT Child_Account_vod__r.Id, Child_Account_vod__r.Name FROM Child_Account_vod__c WHERE Parent_Account_vod__r.Id=:ChildIds];
    AccountList.addall(AccountList2);   
    
   // ---------- Level5
    ChildIds.clear();        
    for (Child_Account_vod__c a: AccountList2)
    {   
            System.debug('AccountList: ' + a.Child_Account_vod__r.Id);
            ChildIds.add(a.Child_Account_vod__r.Id);
    } 
    AccountList2 = [SELECT Child_Account_vod__r.Id, Child_Account_vod__r.Name FROM Child_Account_vod__c WHERE Parent_Account_vod__r.Id=:ChildIds];
    AccountList.addall(AccountList2);    
    
    // ---------- Level6
    ChildIds.clear();        
    for (Child_Account_vod__c a: AccountList2)
    {   
            System.debug('AccountList: ' + a.Child_Account_vod__r.Id);
            ChildIds.add(a.Child_Account_vod__r.Id);
    } 
    AccountList2 = [SELECT Child_Account_vod__r.Id, Child_Account_vod__r.Name FROM Child_Account_vod__c WHERE Parent_Account_vod__r.Id=:ChildIds];
    AccountList.addall(AccountList2);    
    
    // Remove duplicates
    Set<Child_Account_vod__c > myset = new Set<Child_Account_vod__c >();
    myset.addall(AccountList);
    AccountList.clear();
    AccountList.addall(myset);     
    
    
    
    // --------------------------------------------------
    List<TSF_vod__c> TSFs = new List<TSF_vod__c>();
    List<TSF_vod__c> TSFs_update = new List<TSF_vod__c>();
    List<TSF_vod__c> TSFs_insert = new List<TSF_vod__c>();
    List<String> TSF_ExternalIds = new List <String>();

    
    TSF_vod__c TSF;
    Id currentUserId = UserInfo.getUserId();
    List<UserTerritory > myList = [SELECT TerritoryId FROM UserTerritory WHERE UserId =: currentUserId];     
    List<String> myListIds = new List<String>();
    
    for (UserTerritory ut: myList )
    {
        myListIds.add(ut.TerritoryId );
    }
    
    List<Territory> myList2 = [SELECT Name FROM Territory WHERE Id =: myListIds];     

    // Build TSF records for all Terrs-Accs    
    for (Child_Account_vod__c a: AccountList)
    {
            TSF = new TSF_vod__c();
            
            TSF.External_Id_vod__c=a.Child_Account_vod__r.Id + '__' + myList2[0].Name;
            TSF.Account_vod__c =  a.Child_Account_vod__r.Id ;
            TSF.Territory_vod__c = myList2[0].Name;
            TSF.Target_Manager_QS__c  = true;
            TSFs.add(TSF);
            TSF_ExternalIds.add(TSF.External_Id_vod__c);
            System.debug('Adding TSF ' + TSF.Account_vod__c );
    }
    // Create TSF for selected account
    TSF = new TSF_vod__c();
    
    TSF.External_Id_vod__c=this.accountId  + '__' + myList2[0].Name;
    TSF.Account_vod__c = this.accountId ;
    TSF.Territory_vod__c = myList2[0].Name;
    TSF.Target_Manager_QS__c  = true;
    TSFs.add(TSF);
    TSF_ExternalIds.add(TSF.External_Id_vod__c);
    System.debug('Adding TSF ' + TSF.Account_vod__c );
  
    // Some TSFs need to be updated
    TSFs_update = [SELECT Id, External_Id_vod__c, Account_vod__c, Target_Manager_QS__c, Territory_vod__c FROM TSF_vod__c WHERE External_Id_vod__c=:TSF_ExternalIds];    
    for (TSF_vod__c b: TSFs_update )
    {
        b.Target_Manager_QS__c = true;
    }

    // Some TSFs need to be inserted
    for (TSF_vod__c a: TSFs)
    {  
        Boolean ins = true;     
        for (TSF_vod__c b: TSFs_update )
        {
            System.debug('Compare: ' + b.External_Id_vod__c  + ' vs ' +  a.External_Id_vod__c);
            if (b.External_Id_vod__c == a.External_Id_vod__c)
            {
                ins = false;
                break;
            }
        }    
        if (ins == true)
        {
            System.debug('Inserting: ' +  a.External_Id_vod__c);
            a.External_Id_vod__c = '';
            TSFs_insert.add(a);
        }
    }
    


//     System.debug('Following TSFs will be inserted');
//     for (TSF_vod__c a: TSFs_insert)
//     { 
//         System.debug(a.Account_vod__c+';'+a.Territory_vod__c + ';');
//     }
    
    // Remove duplicates before insert
    Set<TSF_vod__c > myset2 = new Set<TSF_vod__c>();    
    myset2.addall(TSFs_insert);
    TSFs_insert.clear();
    TSFs_insert.addall(myset2);
    insert TSFs_insert;
    
   // Remove duplicates before update
   myset2.clear();
   myset2.addall(TSFs_update);
   TSFs_update.clear();
   TSFs_update.addall(myset2);
   
   update TSFs_update;
    
    return null;    
}
}