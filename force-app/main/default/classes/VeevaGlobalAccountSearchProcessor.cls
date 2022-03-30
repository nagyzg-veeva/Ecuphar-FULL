/**
 * VeevaGlobalAccountSearchProcessor Search processor class for Global Account Search
 * This class is responsible for running the actual search process and returning results
 * to the VeevaGlobalAccountSearchController class
 */
public inherited sharing class VeevaGlobalAccountSearchProcessor {
    private static Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();

    private String platform;
    private VeevaGASUserAccess userAccess;
    @TestVisible private VeevaGASSearchClause searchClause;
    @TestVisible VeevaGASConfigBase searchConfig;
    @TestVisible private VeevaGASQuerySortCondition sortCondition;
    
    public VeevaGlobalAccountSearchProcessor(String platformParam, VeevaGASSearchClause clause, VeevaGASQuerySortCondition sortInfo, VeevaGASUserAccess gasUserAccess) {
        platform = platformParam;
        searchConfig = VeevaGASConfigFactory.getGASConfigForPlatform(platform);
        userAccess = gasUserAccess;
        searchClause = clause;
        sortCondition = sortInfo;
    }

    /**
     * Takes search strings and Account Type to perform the search
     * Calls appropriate method to get Address information
     * based on the address search string
     * @returns {Map} returns a Map of search results
     */
    public Map<String, Object> searchAccounts(String searchText, String addressSearchText, String accountType){
        Map<String, Object> results = new Map<String, Object>();
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        List<Map<String, Object>> metadata = new List<Map<String, Object>>();
        List<Account> accountList = new List<Account>();
        VeevaGASSearchResults gasSearchResults = new VeevaGASSearchResults();
        List<String> accountFields = searchConfig.getAccountQueryFields();
        List<String> addressFields = searchConfig.getAddressQueryFields();
        Boolean addressFilter = false;

        if(String.isNotBlank(searchText)) {  
            searchText += (searchText.isNumeric()) ? '*' : '';
            accountList = queryAccounts(searchText, accountType, accountFields, String.isEmpty(addressSearchText));
            if (accountList.size() > 0){
                gasSearchResults.setAccounts(accountList);
                Set<Id> accountIds = gasSearchResults.getAccountMap().keySet();
                List<Address_vod__c> addressList;
                if (!String.isEmpty(addressSearchText)){
                    addressFilter = true;
                    addressList = searchAddressesByText(addressSearchText, accountIds, addressFields);
                } else {
                    addressList = getAddressInfoForAccounts(accountIds, addressFields);
                }
                gasSearchResults.setAddresses(addressList);
                Map<Id, List<Object>> parentAccounts = new Map<Id, List<Object>>();
                if (platform == 'Mobile'){
                    parentAccounts = getParentsForAccounts(accountList, addressFields);
                }
                if (sortCondition != null && sortCondition.getObjectName() == 'Address_vod__c'){
                    records = formatResultsSortByAddress(gasSearchResults, parentAccounts, addressFilter);
                } else {
                    records = formatResultsSortByAccount(gasSearchResults, parentAccounts, addressFilter);
                }
            }
            metadata = getResultSetFieldInfo(accountFields, addressFields);
            results.put('records', records);
            results.put('fields', metadata);
        }
        return results;
    }

    /**
     * Takes in search parameters to perform a query for Accounts
     * @returns {List} returns List of SObjects
     */
    private List<Account> queryAccounts(String searchText, String accountType, List<String> accountFieldList, Boolean isAddressSearchTextEmpty){
        List<Account> accountList = new List<Account>();
        
        String accountFieldNames = String.join(accountFieldList, ',');
        String searchQuery = 'FIND \'' + String.escapeSingleQuotes(searchText) + '\' IN ALL FIELDS RETURNING Account(' + accountFieldNames + 
        ' WHERE IsDeleted = false';
        if (!String.isBlank(accountType)){
            if (accountType == 'HCP'){
                searchQuery += ' AND isPersonAccount = true';
            } else if (accountType == 'HCO') {
                searchQuery += ' AND isPersonAccount = false';
            }
        }
        String accountSearchClause = searchClause.generateSOSLClause('Account');
        if (!String.isBlank(accountSearchClause)) {
            searchQuery += ' AND ' + accountSearchClause + ' ';
        }
        if (sortCondition != null && sortCondition.getObjectName() == 'Account'){
            searchQuery += sortCondition.getOrderByClause();
        }
        //Only apply the limit if no further filtering is required
        if (isAddressSearchTextEmpty){
            searchQuery += ' LIMIT ' + searchConfig.getMaxRowLimit();
        }
        searchQuery += ')';
        //System.debug('queryAccounts SOSL Query : ' + searchQuery);
        List<List<Account>> results = search.query(searchQuery);
        //System.debug('queryAccounts SOSL Results : ' + results);
        if(results != null && !results.isEmpty()) {
            SObjectAccessDecision accountRecordsSecurity = Security.stripInaccessible(AccessType.READABLE, (List<Account>)results[0]);
            accountList = accountRecordsSecurity.getRecords();
        }
        return accountList;
    }

    /**
     * Retrieves an address for each of the Accounts passed, if one exists
     * For each Account, gets the earliest or Primary address
     * @returns {List} returns Account Address information
     */
    private List<Address_vod__c> getAddressInfoForAccounts(Set<Id> accountIds, List<String> addressFieldList){
        Map<Id, Address_vod__c> addressMap = new Map<Id, Address_vod__c>();
        List<Address_vod__c> tempAddressList = new List<Address_vod__c>();
        List<Address_vod__c> finalAddressList = new List<Address_vod__c>();
        String addressFieldNames = String.join(addressFieldList, ',');

        String addressQueryStr = 'SELECT ' + addressFieldNames +
            ' FROM  Address_vod__c ' +
            ' WHERE Account_vod__c IN :accountIds' +
            ' AND IsDeleted = false ';
        if (sortCondition != null && sortCondition.getObjectName() == 'Address_vod__c'){
            addressQueryStr += sortCondition.getOrderByClause();
        } else {
            addressQueryStr += ' ORDER BY Account_vod__c, CreatedDate ';
        }
        //System.debug('Address SOQL: ' + addressQueryStr);
        SObjectAccessDecision addressRecordsSecurity = Security.stripInaccessible(AccessType.READABLE, Database.query(addressQueryStr));
        List<Address_vod__c> addressRecords = addressRecordsSecurity.getRecords();
        for(Address_vod__c addressRecord : addressRecords) {
            Id accId = addressRecord.Account_vod__c;
            //Only replace the address for an Account if the new one is Primary or older
            if (!addressMap.containsKey(accId) || addressRecord.Primary_vod__c || (addressRecord.CreatedDate < addressMap.get(accId).CreatedDate)){
                addressMap.put(accId, addressRecord);
                tempAddressList.add(addressRecord);
            }
        }
        if (sortCondition != null && sortCondition.getObjectName() == 'Address_vod__c'){
            for (Address_vod__c addressRec : tempAddressList){
                if (addressMap.get(addressRec.Account_vod__c).Id == addressRec.Id){
                    finalAddressList.add(addressRec);
                }
            }
        } else {
            finalAddressList = new List<Address_vod__c>(addressMap.values());
        }
        return finalAddressList;
    }

        /**
     * Searches for addresses for each of the Accounts passed, if one exists
     * based on the search text passed
     * @returns {List} returns Address information
     */
    private List<Address_vod__c> searchAddressesByText(String searchText, Set<Id> accountIds, List<String> addressFieldList){
        Map<Id, Address_vod__c> accountAddressMap = new Map<Id, Address_vod__c>();
        List<Address_vod__c> tempAddressList = new List<Address_vod__c>();
        List<Address_vod__c> finalAddressList = new List<Address_vod__c>();
        Integer sizeLimit = Integer.valueOf(searchConfig.getMaxRowLimit());

        String addressFieldNames = String.join(addressFieldList, ',');
        String searchQuery = 'FIND \'' + String.escapeSingleQuotes(searchText) + '\' IN ALL FIELDS RETURNING Address_vod__c(' + addressFieldNames + 
        ' WHERE IsDeleted = false';
        if (!accountIds.isEmpty()){
            searchQuery += ' AND Account_vod__c IN (';
            for (Id accountId : accountIds){
                searchQuery += '\'' + accountId + '\',';
            }
            searchQuery = searchQuery.subString(0, searchQuery.length() - 1);
            searchQuery += ')';
        }
        if (sortCondition != null && sortCondition.getObjectName() == 'Address_vod__c'){
            searchQuery += sortCondition.getOrderByClause();
        } else {
            searchQuery += ' ORDER BY Account_vod__c, CreatedDate ';
        }
        searchQuery += ')';
        //System.debug('queryAccounts SOSL Query : ' + searchQuery);
        List<List<Address_vod__c>> results = search.query(searchQuery);
        //System.debug('queryAccounts SOSL Results : ' + results);
        if(results != null && !results.isEmpty()) {
            SObjectAccessDecision addressRecordsSecurity = Security.stripInaccessible(AccessType.READABLE, results[0]);
            List<Address_vod__c> addresses = addressRecordsSecurity.getRecords();
            for (Address_vod__c addressRec : addresses){
                Id accId = addressRec.Account_vod__c;
                //Only replace the address for an Account if the new one is Primary or older
                if (!accountAddressMap.containsKey(accId) || (addressRec.Primary_vod__c) || (accountAddressMap.get(addressRec.Account_vod__c).CreatedDate > addressRec.CreatedDate)){
                    accountAddressMap.put(accId, addressRec);
                    tempAddressList.add(addressRec);
                    if (accountAddressMap.size() >= sizeLimit) {
                        break;
                    }
                }
            }
            if (sortCondition != null && sortCondition.getObjectName() == 'Address_vod__c'){
                for (Address_vod__c address : tempAddressList){
                    if (accountAddressMap.get(address.Account_vod__c).Id == address.Id){
                        finalAddressList.add(address);
                    }
                }
                return finalAddressList;
            } else {
                finalAddressList = new List<Address_vod__c>(accountAddressMap.values());
            }
        }
        return finalAddressList;
    }

    /**
     * Formats the search results before they are returned to the Controller sorted by Account
     * returns {List} returns list with fields and values for all search results retrieved
     */
    private List<Map<String, Object>> formatResultsSortByAccount(VeevaGASSearchResults gasSearchResults, Map<Id, List<Object>> parentAccountsMap, Boolean addressFilter){
        List<Map<String, Object>> recordList = new List<Map<String, Object>>();
        Map<String, Object> searchResultRecord;
        List<String> accountFields = searchConfig.getAccountObjectFields();
        List<String> addressFields = searchConfig.getAddressObjectFields();
        List<Account> accountList = gasSearchResults.getAccounts();
        Map<Id, Address_vod__c> accountAddressMap = gasSearchResults.getAddressMap();
        Set<Id> accountIdsInUserTerritory = getAccountIdsUserHasAccess(accountList);

        for (Account account : accountList){
            searchResultRecord = new Map<String, Object>();
            if ((!addressFilter) || (addressFilter && accountAddressMap.containsKey(account.Id))){
                for (String field : accountFields){
                    searchResultRecord.put('Account.' + field, getFieldValue(account, field));
                }
                SObject addressRecord = accountAddressMap.get(account.Id);
                if (addressRecord != null){
                    for (String field : addressFields){
                        searchResultRecord.put('Address_vod__c.' + field, getFieldValue(addressRecord, field));
                    }
                }
                List<Object> parentAccounts = (parentAccountsMap.containsKey(account.Id)) ?  parentAccountsMap.get(account.Id)
                    : new List<Object>();
                searchResultRecord.put('Account.Parents', parentAccounts);
                searchResultRecord.put('insideTerritory', accountIdsInUserTerritory.contains(account.Id));
                recordList.add(searchResultRecord);
            }
        }
        return recordList;
    }

    /**
     * Formats the search results before they are returned to the Controller sorted by Address
     * returns {List} returns list with fields and values for all search results retrieved
     */
    private List<Map<String, Object>> formatResultsSortByAddress(VeevaGASSearchResults gasSearchResults, Map<Id, List<Object>> parentAccountsMap, Boolean addressFilter){
        List<Map<String, Object>> recordList = new List<Map<String, Object>>();
        List<Map<String, Object>> recordsWithAddress = new List<Map<String, Object>>();
        List<Map<String, Object>> recordsWithoutAddress = new List<Map<String, Object>>();
        Map<String, Object> searchResultRecord;
        List<String> accountFields = searchConfig.getAccountObjectFields();
        List<String> addressFields = searchConfig.getAddressObjectFields();
        List<Account> accountList = gasSearchResults.getAccounts();
        Map <Id, Account> accountMap = gasSearchResults.getAccountMap();
        Set<Id> accountIdsInUserTerritory = getAccountIdsUserHasAccess(new List<Account>(accountList));
        Set<Id> processedAccounts = new Set<Id>();

        for (Address_vod__c addressRecord : gasSearchResults.getAddresses()){
            Account account = accountMap.get(addressRecord.Account_vod__c);
            processedAccounts.add(account.Id);
            searchResultRecord = extractFieldsToRecord(account, addressRecord);
            List<Object> parentAccounts = (parentAccountsMap.containsKey(account.Id)) ?  parentAccountsMap.get(account.Id)
                : new List<Object>();
            searchResultRecord.put('Account.Parents', parentAccounts);
            searchResultRecord.put('insideTerritory', accountIdsInUserTerritory.contains(account.Id));
            recordsWithAddress.add(searchResultRecord);
        }
        accountMap.keySet().removeAll(processedAccounts);
        if (!addressFilter){
            for (Account account : accountMap.values()){
                searchResultRecord = extractFieldsToRecord(account, null);
                List<Object> parentAccounts = (parentAccountsMap.containsKey(account.Id)) ?  parentAccountsMap.get(account.Id)
                    : new List<Object>();
                searchResultRecord.put('Account.Parents', parentAccounts);
                searchResultRecord.put('insideTerritory', accountIdsInUserTerritory.contains(account.Id));
                recordsWithoutAddress.add(searchResultRecord);
            }
        }
        if (sortCondition.getSortDirection() == 'ASC'){
            recordList.addAll(recordsWithoutAddress);
            recordList.addAll(recordsWithAddress);
        } else {
            recordList.addAll(recordsWithAddress);
            recordList.addAll(recordsWithoutAddress);
        }
        return recordList;
    }

    private Map<String, Object> extractFieldsToRecord(Account account, Address_vod__c addressRecord){
        Map<String, Object> searchResultRecord = new Map<String, Object>();
        List<String> accountFields = searchConfig.getAccountObjectFields();
        List<String> addressFields = searchConfig.getAddressObjectFields();
        for (String field : accountFields){
            searchResultRecord.put('Account.' + field, getFieldValue(account, field));
        }
        if (addressRecord != null){
            for (String field : addressFields){
                searchResultRecord.put('Address_vod__c.' + field, getFieldValue(addressRecord, field));
            }
        }
        return searchResultRecord;
    }

    private static Object getFieldValue(SObject sObj, String field){
        Object value;
        List<String> fieldNameInfo = field.split('\\.');
        //Reference field check
        if ((fieldNameInfo.size() > 1) && sObj.isSet(fieldNameInfo[0])){
            //get relationship name
            String relationshipName = getRelationshipName(sObj.getSObjectType().getDescribe().getName(), fieldNameInfo[0]);
            if (relationshipName != null){
                SObject relObject = sObj.getSObject(relationshipName);
                if (relObject != null){
                    value = relObject.get(fieldNameInfo[1]);
                }
            }
        } else if ((fieldNameInfo.size() == 1) && sObj.isSet(field) && sObj.get(field) != null){
                value = sObj.get(field);
        }
        return value;
    }

    private List<Map<String, String>> getResultSetFieldInfo(List<String> accountFields, List<String> addressFields){
        List<Map<String, String>> fieldInfoList = searchConfig.getResultSetColumnInfo();
        return fieldInfoList;
    }

    private static String getRelationshipName(String objectName, String field){
        String relName;
        Schema.DescribeSObjectResult sObjectDescribe = globalDescribe.get(objectName).getDescribe();        
        Map<String, Schema.SObjectField> objectFieldMap = sObjectDescribe.fields.getMap();
        Schema.SObjectField fldDesc = objectFieldMap.get(field);
        if (fldDesc != null){
            relName = fldDesc.getDescribe().getRelationshipName();
        }
        return relName;
    }

    /**
     * Query and return Parent information for all Accounts passed in prarameters
     * Returns {Map} returns Parent information for Accounts
     */
    private Map<Id, List<Object>> getParentsForAccounts(List<SObject> accountList, List<String> addressFields){
        Map<Id, List<Object>> allParentsInfo = new Map<Id, List<Object>>();
        Map<Id, List<Map<String, Object>>> parentAccountMap = new Map<Id, List<Map<String, Object>>>();
        Set<Id> parentIds = new Set<Id>();
        Map<String, Object> parentAccountObj;
        List<Id> accountIds = new List<Id>();
        for (SObject sObj : accountList){
            accountIds.add(sObj.Id);
        }
        for(Child_Account_vod__c parentAccountInfo : [SELECT Child_Account_vod__c, Parent_Account_vod__r.Id, Parent_Account_vod__r.Name 
         FROM Child_Account_vod__c
         WHERE Child_Account_vod__c IN :accountIds
         AND IsDeleted = false]) {
            parentAccountObj = new Map<String, Object>();
            Id accountId = parentAccountInfo.Child_Account_vod__c;
            parentIds.add(parentAccountInfo.Parent_Account_vod__r.Id);
            parentAccountObj.put('Name', parentAccountInfo.Parent_Account_vod__r.Name);
            parentAccountObj.put('Id', parentAccountInfo.Parent_Account_vod__r.Id);
            if (parentAccountMap.get(accountId) != null){
                parentAccountMap.get(accountId).add(parentAccountObj);
            } else {
                parentAccountMap.put(accountId, new List<Map<String, Object>> { parentAccountObj });
            }            
        }
        Map<Id, SObject> addressMap = getAddressInfoForParentAccounts(parentIds, addressFields);
        allParentsInfo = formatParentInfo(parentAccountMap, addressMap);
        return allParentsInfo;
    }

    private Map<Id, Address_vod__c> getAddressInfoForParentAccounts(Set<Id> accountIds, List<String> addressFieldList){
        Map<Id, Address_vod__c> addressMap = new Map<Id, Address_vod__c>();
        String addressFieldNames = String.join(addressFieldList, ',');

        String addressQueryStr = 'SELECT ' + addressFieldNames +
            ' FROM  Address_vod__c ' +
            ' WHERE Account_vod__c IN :accountIds' +
            ' AND IsDeleted = false ' +
            ' ORDER BY CreatedDate ';
        //System.debug('Address SOQL: ' + addressQueryStr);
        SObjectAccessDecision addressRecordsSecurity = Security.stripInaccessible(AccessType.READABLE, Database.query(addressQueryStr));
        List<Address_vod__c> addressRecords = addressRecordsSecurity.getRecords();
        for (Address_vod__c addressRecord : addressRecords) {
            Id accId = addressRecord.Account_vod__c;
            if (!addressMap.containsKey(accId) || addressRecord.Primary_vod__c){
                addressMap.put(accId, addressRecord);
            }
        }
        return addressMap;
    }

    private Map<Id, List<Object>> formatParentInfo(Map<Id, List<Map<String, Object>>> parentAccountMap, Map<Id, SObject> addressMap){
        Map<Id, List<Object>> allParentsInfo = new Map<Id, List<Object>>();
        List<Map<String, Object>> accountParentsInfo = new List<Map<String, Object>>();
        Map<String, Object> parentRecord;
        List<String> addressResultFields = searchConfig.getAddressObjectFields();

        for (Id accountId : parentAccountMap.keySet()){
            accountParentsInfo = new List<Map<String, Object>>();
            for(Map<String, Object> parentAccountInfo : parentAccountMap.get(accountId)){
                parentRecord = new Map<String, Object>(); 
                Id parentAccountId = (Id) parentAccountInfo.get('Id');
                parentRecord.put('Account.Id', parentAccountId);
                parentRecord.put('Account.Name', parentAccountInfo.get('Name'));
                SObject addressRecord = addressMap.get(parentAccountId);
                if (addressRecord != null){
                    for (String field : addressResultFields){
                        parentRecord.put('Address_vod__c.' + field, getFieldValue(addressRecord, field));
                    }
                }
                accountParentsInfo.add(parentRecord);
            }
            allParentsInfo.put(accountId, accountParentsInfo);
        }
        return allParentsInfo;
    }

    private Set<Id> getAccountIdsUserHasAccess(List<SObject> accountList) {
        Set<Id> accountIds = (new Map<Id, SObject>(accountList)).keySet();
        return userAccess.getUserAccessibleAccountIds(accountIds);
    }
}