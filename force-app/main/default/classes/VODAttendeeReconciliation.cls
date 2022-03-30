@RestResource(urlMapping='/reconciliation/visibleAccounts/*')
global class VODAttendeeReconciliation {

    @TestVisible private static Integer MAX_RECONCILIATION_ACCOUNT_RESULTS = 1000;
    @TestVisible private static String DEFAULT_ACCOUNT_QUERY_SELECT = 'SELECT FirstName, LastName, Primary_Parent_vod__r.Name, Id, External_ID_vod__c, Country_vod__r.Alpha_2_Code_vod__c, RecordType.DeveloperName, ( SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c FROM Address_vod__r )';

    webService static String searchAccounts(List<String> accountEmailFields, List<String> accountPhoneFields, String lastName, String email, String firstName, String phone) {
        List<sObject> accountQueryResults = Database.query(constructAccountQuery(accountEmailFields, accountPhoneFields, lastName, email, firstName, phone));
        //fill in rest of the results with generic last name query
        accountQueryResults.addAll(Database.query(constructAccountQuery(accountEmailFields, accountPhoneFields, lastName, null, null, null)));

        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject account: accountQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = account.Id;
            currentResult.externalId = (String)account.get('External_ID_vod__c');
            sObject parentAccount = account.getSObject('Primary_Parent_vod__r');
            if(parentAccount != null) {
            	currentResult.parentName = (String)parentAccount.get('Name');
            }
            currentResult.firstName = (String)account.get('FirstName');
            currentResult.lastName = (String)account.get('LastName');

            sObject accRecordType = account.getSObject('RecordType');
            currentResult.accountRecordType = (String)accRecordType.get('DeveloperName');

            sObject accCountry = account.getSObject('Country_vod__r');
            if (accCountry != null) {
            	currentResult.country = (String)accCountry.get('Alpha_2_Code_vod__c');
            }
            List<String> phoneNumbers = new List<String>();
            for(String phoneField : accountPhoneFields) {
                if(account.get(phoneField) != null) {
                    phoneNumbers.add((String) account.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;
            // Replacing List with Set to uniquely save email list
            Set<String> emails = new Set<String>();
            for(String emailField : accountEmailFields) {
                if(account.get(emailField) != null) {
                    emails.add((String) account.get(emailField));
                }
            }
            currentresult.emails = new List<String>(emails);

            List<AddressResult> addresses = new List<AddressResult>();
            for(sObject addressRow :account.getSObjects('Address_vod__r')) {
                AddressResult addressResult = new AddressResult();
                addressResult.addressLine1 = (String)addressRow.get('Name');
                addressResult.addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
                addressResult.city = (String)addressRow.get('City_vod__c');
                addressResult.state = (String)addressRow.get('State_vod__c');
                addressResult.zip = (String)addressRow.get('Zip_vod__c');
                addressResult.country = (String)addressRow.get('Country_vod__c');
                addressResult.Id = (String)addressRow.get('Id');

                addresses.add(addressResult);
            }
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }

        return JSON.serialize(searchResults);
    }

    @TestVisible
    static String constructAccountQuery(List<String> accountEmailFields, List<String> accountPhoneFields, String lastName, String email, String firstName, String phone) {
        String query = DEFAULT_ACCOUNT_QUERY_SELECT;

        if(lastName == null) {
            lastName = '';
        }
        lastName = String.escapeSingleQuotes(lastName);

        if(firstName != null) {
            firstName = String.escapeSingleQuotes(firstName);
        }

        if(phone != null) {
            phone = String.escapeSingleQuotes(phone);
        }

        if(email != null) {
            email = String.escapeSingleQuotes(email);
        }

        List<String> accountEmailAndPhoneFields = new List<String>();
        accountEmailAndPhoneFields.addAll(accountEmailFields);
        accountEmailAndPhoneFields.addAll(accountPhoneFields);
        query = appendWithPrefix(query, ',', accountEmailAndPhoneFields);
        query += ' FROM Account WHERE ';

        List<String> searchTermConditions = new List<String>();

        if (email != null && accountEmailFields.size() > 0) {
            searchTermConditions.add(createOrClause(accountEmailFields, email));
        }

        if (phone != null && accountPhoneFields.size() > 0) {
            searchTermConditions.add(createOrClause(accountPhoneFields, phone));
        }

        if (firstName != null) {
            searchTermConditions.add('(FirstName = \''+firstName+'\' AND LastName = \''+lastName+'\')');
        }

        if(searchTermConditions.size() > 0) {
            query += lastName.length() <= 2 ? 'LastName = \''+lastName+'\'' : 'LastName LIKE \'' + lastName.subString(0,3) + '%\'';
            query += ' AND (';
            for (String condition : searchTermConditions) {
                query += condition;
                if (!condition.equals(searchTermConditions.get(searchTermConditions.size()-1))) {
                    query += ' OR ';
                }
            }
            query += ')';
        } else {
            query += 'LastName = \''+lastName+'\' LIMIT '+ MAX_RECONCILIATION_ACCOUNT_RESULTS;
        }
        return query;
    }

    webService static String searchAddresses(List<String> addressEmailFields, List<String> addressPhoneFields, List<String> accountEmailFields, List<String> accountPhoneFields, String lastName, String email, String phone, String zip, String city, String userId) {
        String query = constructAddressQuery(addressEmailFields, addressPhoneFields, accountEmailFields, accountPhoneFields, lastName, email, phone, zip, city);

        if(query == null) {
            return JSON.serialize(new List<SearchResult>());
        }

        List<sObject> addressQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        Map<String, SearchResult> resultRowMap = new Map<String, SearchResult>();
        for(sObject addressRow: addressQueryResults) {

            sObject account = addressRow.getsObject('Account_vod__r');
            SearchResult resultRow = new SearchResult();
            List<AddressResult> currentAddresses = new List<AddressResult>();
            if(resultRowMap.containsKey((String)account.get('Id'))) {
                resultRow = resultRowMap.get((String) account.get('Id'));
                currentAddresses =  resultRow.addresses;
            } else {
                resultRow.Id = account.Id;
                resultRow.externalId = (String)account.get('External_ID_vod__c');
                sObject parentAccount = account.getSObject('Primary_Parent_vod__r');
                if(parentAccount != null) {
                    resultRow.parentName = (String)parentAccount.get('Name');
                }
                resultRow.firstName = (String)account.get('FirstName');
                resultRow.lastName = (String)account.get('LastName');

                List<String> phoneNumbers = new List<String>();
                for(String phoneField : accountPhoneFields) {
                    if(account.get(phoneField) != null) {
                        phoneNumbers.add((String) account.get(phoneField));
                    }
                }
                resultRow.phoneNumbers = phoneNumbers;

                List<String> emails = new List<String>();
                for(String emailField : accountEmailFields) {
                    if(account.get(emailField) != null) {
                        emails.add((String) account.get(emailField));
                    }
                }
                resultRow.emails = emails;
            }


            AddressResult addressResult = new AddressResult();
            addressResult.addressLine1 = (String)addressRow.get('Name');
            addressResult.addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
            addressResult.city = (String)addressRow.get('City_vod__c');
            addressResult.state = (String)addressRow.get('State_vod__c');
            addressResult.zip = (String)addressRow.get('Zip_vod__c');
            addressResult.country = (String)addressRow.get('Country_vod__c');
            addressResult.Id = (String)addressRow.get('Id');

            currentAddresses.add(addressResult);
            resultRow.addresses = currentAddresses;
            resultRowMap.put((String)account.get('Id'), resultRow);
        }

        for(SearchResult result: resultRowMap.values()) {
            searchResults.add(result);
        }
        return JSON.serialize(searchResults);
    }

    @TestVisible
    static String constructAddressQuery(List<String> addressEmailFields, List<String> addressPhoneFields, List<String> accountEmailFields, List<String> accountPhoneFields, String lastName, String email, String phone, String zip, String city) {
        String query = 'SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c,Account_vod__r.Primary_Parent_vod__r.Name, Account_vod__r.FirstName, Account_vod__r.LastName';

        if(lastName == null) {
            lastName = '';
        }
        lastName = String.escapeSingleQuotes(lastName);

        if(email != null) {
            email = String.escapeSingleQuotes(email);
        }

        if(phone != null) {
            phone = String.escapeSingleQuotes(phone);
        }

        if(city != null) {
            city = String.escapeSingleQuotes(city);
        }

        if(zip != null) {
            zip = String.escapeSingleQuotes(zip);
        }

        List<String> addressEmailAndPhoneFields = new List<String>();
        addressEmailAndPhoneFields.addAll(addressEmailFields);
        addressEmailAndPhoneFields.addAll(addressPhoneFields);

        List<String> accountEmailAndPhoneFields = new List<String>();
        accountEmailAndPhoneFields.addAll(accountEmailFields);
        accountEmailAndPhoneFields.addAll(accountPhoneFields);

        query = appendWithPrefix(query, ',', addressEmailAndPhoneFields);
        query = appendWithPrefix(query, ',Account_vod__r.', accountEmailAndPhoneFields);

        String lastNameWhere = lastName.length() <= 2 ? '= \''+lastName+'\'' : 'LIKE \'' + lastName.subString(0,3) + '%\'';
        query += ' FROM Address_vod__c WHERE Account_vod__c IN (SELECT Id From Account WHERE LastName ' + lastNameWhere + ')';

        boolean needsAnd = true;
        List<String> searchTermConditions = new List<String>();

        if (email != null && addressEmailFields.size() > 0) {
            searchTermConditions.add(createOrClause(addressEmailFields, email));
        }

        if (phone != null && addressPhoneFields.size() > 0) {
            searchTermConditions.add(createOrClause(addressPhoneFields, phone));
        }

        if (zip != null) {
            searchTermConditions.add('((Account_vod__r.LastName = \'' + lastName + '\') AND (Zip_vod__c = \'' + zip  + '\' OR Zip_4_vod__c = \'' + zip + '\'))');
        }

        if (city != null) {
            searchTermConditions.add('(Account_vod__r.LastName = \'' + lastName + '\' AND (City_vod__c = \'' + city + '\'))');
        }

        if(searchTermConditions.size() > 0) {
            query += ' AND (';
            for (String condition : searchTermConditions) {
                query += condition;
                if (!condition.equals(searchTermConditions.get(searchTermConditions.size()-1))) {
                    query += ' OR ';
                }
            }
            query += ')';
        } else {
            return null;
        }
        return query;
    }

    static String appendWithPrefix(String query, String prefix, List<String> fields) {
        for(String field : fields) {
            query += prefix + String.escapeSingleQuotes(field);
        }
        return query;
    }

    static String createOrClause(List<String> fields, String val) {
        String clause = '(';
        for (String field : fields) {
            String currentField = String.escapeSingleQuotes(field);
            clause += currentField + '=\'' + val + '\'';
            if (!field.equals(fields.get(fields.size()-1))) {
                clause += ' OR ';
            }
        }
        clause += ')';
        return clause;
    }

    webService static String searchUsers(List<String> userEmailFields, List<String> userPhoneFields, String lastName, String email, String firstName, String phone, String zip, String city, String userId) {
        String query = 'SELECT Id,FirstName,LastName,City,Country,PostalCode,State,Street';

        if(lastName == null) {
        	lastName = '';
        }
		lastName = String.escapeSingleQuotes(lastName);

        if(firstName != null) {
        	firstName = String.escapeSingleQuotes(firstName);
        }

        if(email != null) {
        	 email = String.escapeSingleQuotes(email);
        }

        if(phone != null) {
        	phone = String.escapeSingleQuotes(phone);
        }

        if(city != null) {
        	city = String.escapeSingleQuotes(city);
        }

        if(zip != null) {
        	zip = String.escapeSingleQuotes(zip);
        }


        for(String userField : userEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        for(String userField : userPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        query += ' FROM User';

        if(lastName.length() <= 2) {
            query += ' WHERE LastName = \'' + lastName + '\'';
        } else {
            query += ' WHERE LastName Like \'' + lastName.subString(0,3) + '%\'';
        }

        query += 'AND ((LastName = \'' + lastName + '\')';

        boolean hasEmail = email != null;
        boolean hasFirstName = firstName != null;
        boolean hasPhone = phone != null;
        boolean hasZip = zip != null;
        boolean hasCity = city != null;


        if(hasEmail) {
            query += ' OR (';
            for(Integer i=0; i < userEmailFields.size(); i++) {
                query += String.escapeSingleQuotes(userEmailFields.get(i)) + '=\'' + email +'\'';
                if(i+1 != userEmailFields.size()) {
                    query +=' OR ';
                }
            }

            query +=')';
        }

        if(hasFirstName) {
            query +=' OR (FirstName =\'' + firstName + '\' AND LastName = \''+ lastName + '\')';
        }

        if(hasPhone) {
            query += ' OR (';
            for(Integer i=0; i < userPhoneFields.size(); i++) {
                query += String.escapeSingleQuotes(userPhoneFields.get(i)) + '=\'' + phone + '\'';
                if(i+1 != userPhoneFields.size()) {
                    query += ' OR ';
                }
            }

            query += ')';
        }

        if(hasZip) {
            query += ' OR (PostalCode =\'' + zip + '\' AND LastName = \''+ lastName + '\')';
        }

        if(hasCity) {
            query += ' OR (City =\'' + city + '\' AND LastName = \''+ lastName + '\')';
        }
        query += ')';

        List<sObject> userQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject user: userQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = user.Id;
            currentResult.isUser = true;
            currentResult.firstName = (String)user.get('FirstName');
            currentResult.lastName = (String)user.get('LastName');

            List<String> phoneNumbers = new List<String>();
            for(String phoneField : userPhoneFields) {
                if(user.get(phoneField) != null) {
                    phoneNumbers.add((String) user.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;

            List<String> emails = new List<String>();
            for(String emailField : userEmailFields) {
                if(user.get(emailField) != null) {
                    emails.add((String) user.get(emailField));
                }
            }
            currentresult.emails = emails;

            List<AddressResult> addresses = new List<AddressResult>();
            AddressResult addressResult = new AddressResult();
            addressResult.addressLine1 = (String)user.get('Street');
            addressResult.city = (String)user.get('City');
            addressResult.state = (String)user.get('State');
            addressResult.zip = (String)user.get('PostalCode');
            addressResult.country  = (String)user.get('Country');
            addressResult.Id = (String)user.get('Id');

            addresses.add(addressResult);
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }
        return JSON.serialize(searchResults);
    }

    webService static String findAccountResult(String Id, List<String> accountEmailFields, List<String> accountPhoneFields) {
        String query = 'SELECT FirstName, LastName, Primary_Parent_vod__r.Name, Id, ( SELECT Id,Name,Address_line_2_vod__c,City_vod__c,toLabel (State_vod__c),toLabel(Country_vod__c),Zip_vod__c,Zip_4_vod__c FROM Address_vod__r )';

        if(Id == null) {
        	Id = '';
        }

        Id = String.escapeSingleQuotes(Id);

        for(String accountField : accountEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(accountField);
        }

        for(String accountField : accountPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(accountField);
        }

        query += ' FROM Account WHERE Id =\'' + Id + '\'';

        List<sObject> accountQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject account: accountQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = account.Id;
            sObject parentAccount = account.getSObject('Primary_Parent_vod__r');
            if(parentAccount != null) {
                currentResult.parentName = (String)parentAccount.get('Name');
            }
            currentResult.firstName = (String)account.get('FirstName');
            currentResult.lastName = (String)account.get('LastName');

            List<String> phoneNumbers = new List<String>();
            for(String phoneField : accountPhoneFields) {
                if(account.get(phoneField) != null) {
                    phoneNumbers.add((String) account.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;

            List<String> emails = new List<String>();
            for(String emailField : accountEmailFields) {
                if(account.get(emailField) != null) {
                    emails.add((String) account.get(emailField));
                }
            }
            currentresult.emails = emails;

            List<AddressResult> addresses = new List<AddressResult>();
            for(sObject addressRow :account.getSObjects('Address_vod__r')) {
                AddressResult addressResult = new AddressResult();
                addressResult.addressLine1 = (String)addressRow.get('Name');
                addressResult.addressLine2 = (String)addressRow.get('Address_line_2_vod__c');
                addressResult.city = (String)addressRow.get('City_vod__c');
                addressResult.state = (String)addressRow.get('State_vod__c');
                addressResult.zip = (String)addressRow.get('Zip_vod__c');
                addressResult.country = (String)addressRow.get('Country_vod__c');
                addressResult.Id = (String)addressRow.get('Id');

                addresses.add(addressResult);
            }
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }

        return JSON.serialize(searchResults);
    }

    webService static String findUserResult(String Id, List<String> userEmailFields, List<String> userPhoneFields) {
        String query = 'SELECT Id,FirstName,LastName,City,Country,PostalCode,State,Street';

        if(Id == null) {
        	Id = '';
        }

        Id = String.escapeSingleQuotes(Id);

        for(String userField : userEmailFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        for(String userField : userPhoneFields) {
            query+= ', ' + String.escapeSingleQuotes(userField);
        }

        query += ' FROM User WHERE Id = \'' + Id + '\'';

        List<sObject> userQueryResults = Database.query(query);
        List<SearchResult> searchResults = new List<SearchResult>();
        for(sObject user: userQueryResults) {
            SearchResult currentResult = new SearchResult();
            currentResult.Id = user.Id;
            currentResult.isUser = true;
            currentResult.firstName = (String)user.get('FirstName');
            currentResult.lastName = (String)user.get('LastName');

            List<String> phoneNumbers = new List<String>();
            for(String phoneField : userPhoneFields) {
                if(user.get(phoneField) != null) {
                    phoneNumbers.add((String) user.get(phoneField));
                }
            }
            currentResult.phoneNumbers = phoneNumbers;

            List<String> emails = new List<String>();
            for(String emailField : userEmailFields) {
                if(user.get(emailField) != null) {
                    emails.add((String) user.get(emailField));
                }
            }
            currentresult.emails = emails;

            List<AddressResult> addresses = new List<AddressResult>();
            AddressResult addressResult = new AddressResult();
            addressResult.addressLine1 = (String)user.get('Street');
            addressResult.city = (String)user.get('City');
            addressResult.state = (String)user.get('State');
            addressResult.zip = (String)user.get('PostalCode');
            addressResult.country  = (String)user.get('Country');
            addressResult.Id = (String)user.get('Id');

            addresses.add(addressResult);
            currentResult.addresses = addresses;
            searchResults.add(currentResult);
        }
        return JSON.serialize(searchResults);
    }

    @HttpGet
    global static List<String> getVisibleAccounts() {
        String userId = RestContext.request.params.get('userId');
        Set<Id> groupIds = new Set<Id>();
        groupIds.add(userId);
        Integer total = 0;
        TerritoryManagement tm = TerritoryManagementFactory.getInstance();

        // user's territory
        Set<Id> userTerrs = tm.getUserTerritories(userId);
        for (Group g: [SELECT Id FROM Group WHERE RelatedId in :userTerrs]) {
          groupIds.add(g.Id);
          total++;
        }

        // user's role
        for (Group g: [SELECT Id FROM Group WHERE RelatedId in (SELECT UserRoleId FROM User WHERE Id = :userId)]) {
          groupIds.add(g.Id);
          total++;
        }

        // get visible accounts
        List<String> visibleAccountIds = new List<String>();
        Integer shareLimit = 50000-total;
        for (AccountShare accountShare: [SELECT AccountId FROM AccountShare WHERE UserOrGroupId in :groupIds LIMIT :shareLimit]) {
          visibleAccountIds.add(accountShare.AccountId);
        }
        return visibleAccountIds;
    }

    global class SearchResult {
        String parentName;
        String Id;
        String externalId;
        String firstName;
        String lastName;
        List<AddressResult> addresses;
        List<String> emails;
        List<String> phoneNumbers;
        boolean isUser;
        boolean inTerritory;
		String accountRecordType;
        String country;

        public String getId() {return Id;}
        public boolean isInTerritory() {return inTerritory;}
        public List<AddressResult> getAddresses() {return addresses;}
    }
    
    global class AddressResult {
        String Id;
        String addressLine1;
        String addressLine2;
        String state;
        String city;
        String zip;
        String country;

        public String getId() {return Id;}
    }
}