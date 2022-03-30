global class PA_VEMSwapStatus {
    
    public List<VEM__Package__c> vemPackages{get;set;}
    public List<Id> vemPackagesIds {get;set;}
    public List<VEM__Package__c> vemPackagesToUpdate{get;set;}
    public String msgAux {get; set;}
    public Boolean isDisabled {get;set;}
    
    public PA_VEMSwapStatus(ApexPages.StandardSetController stdSetController){
        vemPackagesIds = new List<Id>();
        List<VEM__Package__c> vemPackagesAux = stdSetController.getSelected();
        for(VEM__Package__c vemPackageItem : vemPackagesAux){
            vemPackagesIds.add(vemPackageItem.Id); 
        }
        if(vemPackagesIds.isEmpty()){
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Please select at least one record.'));
            isDisabled = true;
        }else{
            isDisabled = false;
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO,'Click ok to confirm the status swap.'));
        }
    }
    
    global PageReference updateStatus(){
        this.isDisabled = false;
        vemPackagesToUpdate = new List<VEM__Package__c>();
        vemPackages = new List<VEM__Package__c>([SELECT ID, VEM__Active__c FROM VEM__Package__c WHERE ID IN : vemPackagesIds]);
        for(VEM__Package__c vemPackItem : vemPackages){
            if (vemPackItem.VEM__Active__c == true){
                vemPackItem.VEM__Active__c = false;
            }else{
                vemPackItem.VEM__Active__c = true;
            }
            vemPackagesToUpdate.add(vemPackItem);
        }
        try{
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Successful update.'));
            update vemPackagesToUpdate;
            return null;
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error occurred in update: ' + e.getCause()));
            return null;
        }        
    }
}