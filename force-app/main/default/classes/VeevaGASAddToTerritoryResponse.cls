global inherited sharing class VeevaGASAddToTerritoryResponse extends VeevaBaseResponse {
    @TestVisible private final Map<String, Object> meta;
    @TestVisible private final List<Map<String, Object>> data;

    public VeevaGASAddToTerritoryResponse(VeevaGASAccountWithDetails accountWithDetails) {
        this.meta = new Map<String, Object>();
        this.data = new List<Map<String, Object>>();

        meta.put('includedAllRecords', accountWithDetails.includedAllRecords);

        data.addAll(convertValuesToString(new List<Map<String, Object>> { accountWithDetails.getAccountAsMap() }));
        data.addAll(convertValuesToString(accountWithDetails.getAddressAsMapList()));
        data.addAll(convertValuesToString(accountWithDetails.getParentAccountsAsMapList()));
        data.addAll(convertValuesToString(accountWithDetails.getChildAccountsAsMapList()));
    }

    private List<Map<String, String>> convertValuesToString(List<Map<String, Object>> objectValueMaps){
        List<Map<String, String>> results = new List<Map<String, String>>();
        Map<String, String> resultMap;
        for (Map<String, Object> valueMap : objectValueMaps){
            resultMap = new Map<String, String>();
            for (String key : valueMap.keySet()){
                resultMap.put(key, String.valueOf(valueMap.get(key)));
            }
            results.add(resultMap);
        }
        return results;
    }
}