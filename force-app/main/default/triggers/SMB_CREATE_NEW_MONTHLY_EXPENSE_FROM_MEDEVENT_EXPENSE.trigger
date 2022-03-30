trigger SMB_CREATE_NEW_MONTHLY_EXPENSE_FROM_MEDEVENT_EXPENSE on Event_Expenses__c (after insert) {
/*This trigger creates an expense record when an Event Expense is created*/
/*If the Expenses record for the month and year does not exist, creates it first*/

List<Expenses_Line_Item__c> ELIs = new List<Expenses_Line_Item__c>();


for (Event_Expenses__c EE:Trigger.new)
    {
    /*get Event Expenses date to retrieve month and year*/
    
    if(EE.Date__c == NULL)
       continue;  //CSABA 2017.03.20.  Do not continue  otherwise you got exception in the next 2 lines. make field mandatory to avoid problems
    
    Date EEDay = EE.Date__c;
    String EEMonth = String.valueOf(EEDay.month());
    Integer EEYear = EEDay.year();
    Id EECurrentUser = EE.CreatedById;
    String result = '';
    Integer counter = 0;
    
    /*default current Expense record if not found later*/
    Expenses__c CurrentMonthExp = new Expenses__c(User__c=EECurrentUser,Financial_Year__c=EEYear,Month__c=String.valueOf(EEMonth));
    
    /*Parse List of Monthly Expenses to retrieve the correct one CurrentMonthExp*/
    List<Expenses__c> MonthExp = new List<Expenses__c>();
    
    //CSABA 2017.03.20.  The below  line is  a best of  bread  bad practice. DO NOT PUT  SOQL INSIDE FOR LOOP!
    MonthExp = [SELECT Id,Month__c, Financial_Year__c,User__c FROM Expenses__c WHERE (Month__c=:EEMonth) AND (Financial_Year__c=:EEYear) AND (User__c=:EECurrentUser) ];
    if (MonthExp.size()==0){insert CurrentMonthExp;}/*if all Expenses records are skipped, then create new one*/
    else {CurrentMonthExp=MonthExp[0];}
    
    Expenses_Line_Item__c ELI = new Expenses_Line_Item__c(Event_Expense__c=EE.Id,Expenses__c=CurrentMonthExp.Id,Value__c=EE.Amount__c,Medical_Event__c=EE.Medical_Event__c,Comments__c=EE.Description__c,Expense_Item__c=EE.Expense_Type__c);
    ELIs.add(ELI);
    }
insert ELIs;

}