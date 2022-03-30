trigger SMB_UPDATE_DELETE_EXPENSE_LINES_FROM_CALL_EXPENSE on Call2_Expense_vod__c (before update, before delete) {

    Set<Id> CallExpenseIds = new Set<Id>();            // Updated event expenses
    Map<Id,Decimal> Amounts = new Map<Id,Decimal>();    // Update expense amount if event expense amount has been update
    Map<Id,String> Notes = new Map<Id,String>();        // Update expense note if event expense note has been update
    Map<Id,String> Types = new Map<Id,String>();        // Update expense type if event expense note has been update    
    List<Expenses_Line_Item__c> ELIs = new List<Expenses_Line_Item__c>();   // Expense line items to be updated
    
    Set<Id> IdstoDelete = new Set<Id>();                // Ids to Delete

    // UPDATE EXPENSES
    if (Trigger.isUpdate)
    {
        for (Call2_Expense_vod__c CE:Trigger.new)
        {
            CallExpenseIds.add(CE.Id);
            Amounts.put(CE.Id, CE.Amount_vod__c);
            Notes.put(CE.Id, CE.Note_vod__c);   
            Types.put(CE.Id, CE.Type_vod__c);                   
        }
        
        ELIs =  [SELECT Id, Value__c,  Comments__c, Call_Expense__c, Expense_Item__c
                FROM Expenses_Line_Item__c 
                WHERE   Call_Expense__c = :CallExpenseIds]; 

        for (Expenses_Line_Item__c ELI:ELIs)
        {
            ELI.Value__c = Amounts.get(ELI.Call_Expense__c);
            ELI.Comments__c= Notes.get(ELI.Call_Expense__c);
            ELI.Expense_Item__c= Types.get(ELI.Call_Expense__c);       
        }
    
    update ELIs;    
    }
    
    //DELETE EXPENSES
    if (Trigger.isDelete) 
    {
    List<Expenses_Line_Item__c> ELIToDelete = new List<Expenses_Line_Item__c>();
    for (Call2_Expense_vod__c CE:Trigger.old)
        {
        IdstoDelete.add(CE.Id);
        }
    ELIToDelete =  [SELECT Id 
            FROM Expenses_Line_Item__c 
            WHERE   Call_Expense__c = :IdstoDelete]; 
    
    delete ELIToDelete;
    }

}