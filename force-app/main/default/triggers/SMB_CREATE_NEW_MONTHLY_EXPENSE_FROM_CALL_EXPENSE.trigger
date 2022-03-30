trigger SMB_CREATE_NEW_MONTHLY_EXPENSE_FROM_CALL_EXPENSE on Call2_Expense_vod__c (after insert) {
/*This trigger creates an expense record when a Call Expense is created*/
/*If the Expenses record for the month and year does not exist, creates it first*/
/*CAREFUL : This trigger does not deal with the Call Expense update scenario*/

List<Expenses_Line_Item__c> ELIs = new List<Expenses_Line_Item__c>();

for (Call2_Expense_vod__c EE:Trigger.new)
    {
    /*get Event Expenses date to retrieve month and year*/
    Date EEDay = EE.Call_Date_vod__c;
    String EEMonth = String.valueOf(EEDay.month());
    Integer EEYear = EEDay.year();
    Id EECurrentUser = EE.CreatedById;
    String result = '';
    Integer counter = 0;
    
    /*default current Expense record if not found later*/
    Expenses__c CurrentMonthExp = new Expenses__c(User__c=EECurrentUser,Financial_Year__c=EEYear,Month__c=String.valueOf(EEMonth));
    
    /*Parse List of Monthly Expenses to retrieve the correct one CurrentMonthExp*/
    List<Expenses__c> MonthExp = new List<Expenses__c>();
    MonthExp = [SELECT Id,Month__c, Financial_Year__c,User__c FROM Expenses__c WHERE (Month__c=:EEMonth) AND (Financial_Year__c=:EEYear) AND (User__c=:EECurrentUser) ];
    if (MonthExp.size()==0){insert CurrentMonthExp;}/*if all Expenses records are skipped, then create new one*/
    else {CurrentMonthExp=MonthExp[0];}
    Expenses_Line_Item__c ELI = new Expenses_Line_Item__c(Call_Expense__c=EE.Id,Expenses__c=CurrentMonthExp.Id,Call__c=EE.Call2_vod__c,Value__c=EE.Amount_vod__c,Comments__c=EE.Note_vod__c,Expense_Item__c=EE.Type_vod__c);
    ELIs.add(ELI);
    }
insert ELIs;


}