public without sharing class VPROF_GASAccountDetailsControllerExt {

   public  Account acct {set;get;}
   public String accountRTDeveloperName {set;get;}
    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public VPROF_GASAccountDetailsControllerExt() {
    	ID aId = ApexPages.currentPage().getParameters().get('Id');
    	accountRTDeveloperName = [Select RecordType.DeveloperName from Account where Id = :aId].RecordType.DeveloperName;
    	System.debug('Account RT Dev Name: ' + accountRTDeveloperName);
        this.acct = getAccountDetails(aId);
    }


    public List<Schema.FieldSetMember> getFields() {
    	
    	List<Schema.FieldSetMember> fieldSetMembers;
    	String delim = GAS_Hierarchical_Setting__c.getInstance().Summary_View_Delimiter_String__c;
    	fieldSetMembers = GASUtilities.readFieldSet(GAS_Hierarchical_Setting__c.getInstance().Summary_View_Default_Acct_Field_Set_Name__c, 
    												accountRTDeveloperName,
    												'Account',
    												delim);
    	if(fieldSetMembers == null){
    		ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.ERROR, 'Please specify either a default Field Set name in Custom Settings or Create ' + 
    		'an Account Field Set corresponding to a valid Account RecordType. Naming convention for Field set name is: ' + delim + 'RecTypeDeveloperName' 
    										+ delim +'OptionalFreeText'));
    	}
    	
        return fieldSetMembers;
    }

    private Account getAccountDetails(ID acctId) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id FROM Account where Id = \'' + acctId + '\'';
        return Database.query(query);
    }


}