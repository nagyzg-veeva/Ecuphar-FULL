public inherited sharing class VeevaUserTerritory {

    @AuraEnabled
    public String value { get; private set; }
    @AuraEnabled
    public String label { get; private set; }

    public VeevaUserTerritory(String value, String label) {
        this.value = value;
        this.label = label;
    }
}