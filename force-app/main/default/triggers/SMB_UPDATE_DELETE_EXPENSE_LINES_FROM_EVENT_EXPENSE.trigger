trigger SMB_UPDATE_DELETE_EXPENSE_LINES_FROM_EVENT_EXPENSE on Event_Expenses__c (before update, before delete) {

    Set<Id> EventExpenseIds = new Set<Id>();            // Updated event expenses
    Map<Id,Decimal> Amounts = new Map<Id,Decimal>();    // Update expense amount if event expense amount has been update
    Map<Id,String> Notes = new Map<Id,String>();        // Update expense note if event expense note has been update
    Map<Id,String> Types = new Map<Id,String>();        // Update expense type if event expense note has been update    
    List<Expenses_Line_Item__c> ELIs = new List<Expenses_Line_Item__c>();   // Expense line items to be updated
    
    Set<Id> IdstoDelete = new Set<Id>();                // Ids to Delete

    // UPDATE EXPENSES
    if (Trigger.isUpdate)
    {
       for (Event_Expenses__c CE:Trigger.new)
        {
            EventExpenseIds.add(CE.Id);
            Amounts.put(CE.Id, CE.Amount__c);
            Notes.put(CE.Id, CE.Description__c);   
            Types.put(CE.Id, CE.Expense_Type__c);           
        }    

        ELIs =  [SELECT Id, Value__c,  Comments__c, Expense_Item__c, Event_Expense__c 
                FROM Expenses_Line_Item__c 
                WHERE   Event_Expense__c = :EventExpenseIds]; 

        for (Expenses_Line_Item__c ELI:ELIs)
        {
            ELI.Value__c = Amounts.get(ELI.Event_Expense__c);
            ELI.Comments__c= Notes.get(ELI.Event_Expense__c);
            ELI.Expense_Item__c= Types.get(ELI.Event_Expense__c);        
        }
    update ELIs;
    }
    
    //DELETE EXPENSES
    if (Trigger.isDelete) 
    {
    List<Expenses_Line_Item__c> ELIToDelete = new List<Expenses_Line_Item__c>();
    for (Event_Expenses__c CE:Trigger.old)
        {
        IdstoDelete.add(CE.Id);
        }
    ELIToDelete =  [SELECT Id 
            FROM Expenses_Line_Item__c 
            WHERE   Event_Expense__c = :IdstoDelete]; 
    
    delete ELIToDelete;
    }

}