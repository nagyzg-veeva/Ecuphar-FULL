public inherited sharing class VeevaGASAddToTerritoryRequestBody {
    @TestVisible private String accountId;
    @TestVisible private List<String> territoryIds;
    @TestVisible private List<String> parentAccountIds;

    public String getAccountId() {
        return accountId;
    }

    public List<String> getTerritoryIds() {
        return territoryIds;
    }

    public List<String> getParentAccountIds() {
        return parentAccountIds;
    }
}