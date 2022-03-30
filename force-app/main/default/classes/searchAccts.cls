/**
 * Global Account search
 *
 * @version 2.3 - mnaidu - update Jan 14, 2014 (see notes below)
 * @version        2.0 
 * @version Update: 2.1 (7/31/13)
 * @author         Veeva Technical Services (Jeff Kelso, Murugesh Naidu, Wayne Abbott)
 * Update: mnaidu - 7/16/13 - Added Custom Filtering mechanism and migrated code to GAS Hierarchical Custom settings
 * Update: jkelso - 8/9/13 - Added ability to align accounts to multiple territories
 * @version Update 2.2 (9/19/2013) 
 * Upate: mnaidu - 9/19/2013 - This change applies ONLY to the Visualforce page "searchAccts.page". Added condition to identify at run time which is the field 
 * element to be hyperlinked in the results. Conditional check Coded in VF page so as to make this purely a VF page change so that it can be easy to integrate 
 * if not a pure GAS 2.2 implementation is used
 * Update: mnaidu v2.3 - 1/9/14 - Performance improvement change: Updated the class (method excludeAccountsIfAny) to send the unfiltered accountIds to avoid full table scans when
 * deciding accounts to be excluded/included
 * Update: mnaidu v2.3 - 1/9/14 -  New feature to allow inclusive filters -  Updated the class (method excludeAccountsIfAny) to recognize Inclusive filters based on Custom setting value
 * Update: mnaidu v2.3 - 2/17/14 - Updated excludeAccountsIfAny() method to handle situation where none of the accounts should be included if the criteria does not match the inclusive criteria
 
 */
public class searchAccts {


    public List<ResultHeader> resultHeaders {set;get;}

    public String wc {get;set;}

    public List <SearchField> acctSearchFields {set;get;}
    public List <SearchField> addrSearchFields {set;get;}

    private List<String> acctSearchFieldSet  ;
    private List<String> addrSearchFieldSet  ;

    private List<String> resultFieldSet  ;
    private Set <String> acctResultFields = new Set<String> () ;
    private Set <String> addrResultFields = new Set<String> () ;


    private Map<String, Schema.SObjectField> acctFieldMap ;
    private Map<String, Schema.SObjectField> addrFieldMap ;

    public Map <String,String> resFieldTypeMap = new Map <String,String> () ;
    private Map <String,String> resFieldLabelMap = new Map <String,String> () ;

    public static List<SelectOption> acctRecTypesPlist ;
    public static List<SelectOption> addrRecTypesPlist ;
    private Map <String,String> recTypeXlation = new Map <String,String> () ;

    public String parentSearch {set;get;}
    public String parentAcctField {set;get;}
    public String returnElemId {set;get;}

    public Boolean showAllAddrs {set;get;}
    public Boolean trackAlignmentHistory {get;set;}

    public SearchResult [] results {get;set;}

    public String sortKey {get;set;}
    public String sortDir {get;set;}

    // Custom Labels
    public String GAS_CANCEL {set;get;}
    public String GAS_SEARCH {set;get;}
    public String GAS_LOOKUP {set;get;}
    public String GAS_SFA {set;get;}
    public String GAS_SFPA {set;get;}
    public String GAS_EM {set;get;}
    public String GAS_SW {set;get;}
    public String GAS_CONTAINS {set;get;}
    public static String GAS_NONE {set;get;}
    public String GAS_RESULTS {set;get;}
    public String GAS_ATT {set;get;}
    public String GAS_NOCRIT {set;get;}
    public String GAS_NAMESEARCH {set;get;}
    public String GAS_NOMATCH {set;get;}
    public String GAS_TOOMANY {set;get;}
    public String GAS_NOTALGN {set;get;}
    public String GAS_MANYALGN {set;get;}
    public String GAS_INTERR {set;get;}
    public String GAS_SUCCESS {set;get;}
    public String GAS_SELECT {set;get;}
    public String GAS_CLEAR {set;get;}
    public Boolean GAS_ALIGN_MULTIPLE {get;set;}
    public User theUser;


    // Constructor
    public searchAccts () {
        results = new List<SearchResult> () ;
        parentSearch = ApexPages.currentPage().getParameters().get('parentSearch');
        parentAcctField = ApexPages.currentPage().getParameters().get('parentAcctField');
        returnElemId = ApexPages.currentPage().getParameters().get('returnElemId');
        String lang = UserInfo.getLanguage() ;
        // Get labels from Message_vod__c for user's language
        //mnaidu - 7/18/2013 - This will be moved to a Hierarchical Custom setting in GAS 2.1
       /* Message_vod__c [] labels = [SELECT Name,Text_vod__c 
                                    FROM Message_vod__c 
                                    WHERE Language_vod__c = :lang AND 
                                          Category_vod__c = 'Account' AND 
                                          Name LIKE 'GAS%' AND
                                          Active_vod__c = true] ;
        Map <String,String> labelMap = new Map <String,String> () ;
        for (Message_vod__c label : labels) {
            labelMap.put(label.Name, String.escapeSingleQuotes(label.Text_vod__c)) ;
        }
        */

        // Get values of custom settings
        //mnaidu - 7/16/2013 - We should leverage Hierarchy Custom settings for this as it is more suited to this type of transaction. Also should
        //give us the ability to have different search and results columns for different users
        //GASSettings__c gas = [select Account_Search_Field_Set__c,Address_Search_Field_Set__c,Result_Field_Set__c,Show_All_Addresses__c, Track_Alignment_History__c from GASSettings__c where name = 'Main'] ;
        GAS_Hierarchical_Setting__c   gas = GAS_Hierarchical_Setting__c.getInstance();//this returns the appropriate settings for the user based on his user profile  
        GAS_CANCEL = gas.GAS_Message_Cancel__c ;
        GAS_SEARCH = gas.GAS_Message_Search__c;
        GAS_LOOKUP = gas.GAS_Message_Lookup__c ;
        GAS_SFA = gas.GAS_Message_SFA__c ;
        GAS_SFPA = gas.GAS_Message_SFPA__c ;
        GAS_EM = gas.GAS_Message_EM__c ;
        GAS_SW = gas.GAS_Message_STARTS_WITH__c ;
        GAS_CONTAINS = gas.GAS_Message_CONTAINS__c ;
        GAS_NONE = gas.GAS_Message_NONE__c ;
        GAS_RESULTS = gas.GAS_Message_RESULTS__c ;
        GAS_ATT = gas.GAS_Message_ATT__c ;
        GAS_NOCRIT = gas.GAS_Message_NoCriteria__c;
        GAS_NAMESEARCH = gas.GAS_Message_NameSearch__c ;
        GAS_NOMATCH = gas.GAS_Message_NOMATCH__c ;
        GAS_TOOMANY = gas.GAS_Message_TOO_MANY__c ;
        GAS_NOTALGN = gas.GAS_Message_NOTALIGNED__c ;
        GAS_MANYALGN = gas.GAS_Message_MANYALIGN__c;
        GAS_INTERR = gas.GAS_Message_INTERR__c ;
        GAS_SUCCESS = gas.GAS_Message_SUCCESS__c ;
        GAS_SELECT = gas.GAS_Message_SELECT__c ;
        GAS_CLEAR = gas.GAS_Message_CLEAR__c ;
        GAS_ALIGN_MULTIPLE = gas.Align_Multiple_Territory__c;

        
     /*   GAS_CANCEL = labelMap.get('GAS_CANCEL') ;
        GAS_SEARCH = labelMap.get('GAS_SEARCH') ;
        GAS_LOOKUP = labelMap.get('GAS_LOOKUP') ;
        GAS_SFA = labelMap.get('GAS_SFA') ;
        GAS_SFPA = labelMap.get('GAS_SFPA') ;
        GAS_EM = labelMap.get('GAS_EM') ;
        GAS_SW = labelMap.get('GAS_SW') ;
        GAS_CONTAINS = labelMap.get('GAS_CONTAINS') ;
        GAS_NONE = labelMap.get('GAS_NONE') ;
        GAS_RESULTS = labelMap.get('GAS_RESULTS') ;
        GAS_ATT = labelMap.get('GAS_ATT') ;
        GAS_NOCRIT = labelMap.get('GAS_NOCRIT') ;
        GAS_NAMESEARCH = labelMap.get('GAS_NAMESEARCH') ;
        GAS_NOMATCH = labelMap.get('GAS_NOMATCH') ;
        GAS_TOOMANY = labelMap.get('GAS_TOOMANY') ;
        GAS_NOTALGN = labelMap.get('GAS_NOTALGN') ;
        GAS_MANYALGN = labelMap.get('GAS_MANYALGN') ;
        GAS_INTERR = labelMap.get('GAS_INTERR') ;
        GAS_SUCCESS = labelMap.get('GAS_SUCCESS') ;
        GAS_SELECT = labelMap.get('GAS_SELECT') ;
        GAS_CLEAR = labelMap.get('GAS_CLEAR') ;
        */

        // Get Record Types for Accounts and Addresses
        // We need to use the translation table, and also filter by sObjectType
        acctRecTypesPlist = new List<SelectOption> () ;
        acctRecTypesPlist.add(new SelectOption('',GAS_NONE)) ;
        for (RecordTypeLocalization rtl : [select ParentId, Parent.Name, Value from RecordTypeLocalization where ParentId in (select Id FROM RecordType where SobjectType = 'Account' AND IsActive = true) and Language = :lang order by Value]) {
            acctRecTypesPlist.add(new SelectOption(rtl.ParentId,rtl.Value));
            recTypeXlation.put (rtl.Parent.Name, rtl.Value) ;
        }
        // Also need to pick up those Record Types not in RecordTypeLocalization
        for (RecordType rt :[select Id,Name from RecordType where SobjectType = 'Account' AND IsActive = true and Id not in (select ParentId FROM RecordTypeLocalization where Language = :lang)]) {
            acctRecTypesPlist.add(new SelectOption(rt.Id,rt.Name));
            recTypeXlation.put (rt.Name, rt.Name) ;
        }
        acctRecTypesPlist = SortOptionList(acctRecTypesPlist) ;
        // Address Record Types
        addrRecTypesPlist = new List<SelectOption> () ;
        addrRecTypesPlist.add(new SelectOption('',GAS_NONE)) ;
        for (RecordTypeLocalization rtl : [select ParentId, Parent.Name, Value from RecordTypeLocalization where ParentId in (select Id FROM RecordType where SobjectType = 'Address_vod__c' AND IsActive = true) and Language = :lang order by Value]) {
            addrRecTypesPlist.add(new SelectOption(rtl.ParentId,rtl.Value));
            recTypeXlation.put (rtl.Parent.Name, rtl.Value) ;
        }
        // Also need to pick up those Record Types not in RecordTypeLocalization
        for (RecordType rt :[select Id,Name from RecordType where SobjectType = 'Address_vod__c' AND IsActive = true and Id not in (select ParentId FROM RecordTypeLocalization where Language = :lang)]) {
            addrRecTypesPlist.add(new SelectOption(rt.Id,rt.Name));
            recTypeXlation.put (rt.Name, rt.Name) ;
        }
        addrRecTypesPlist = SortOptionList(addrRecTypesPlist) ;


        acctSearchFieldSet = gas.Account_Search_Field_Set__c.split(',') ;
        addrSearchFieldSet = gas.Address_Search_Field_Set__c.split(',') ;
        resultFieldSet = gas.Result_Field_Set__c.split(',') ;
        showAllAddrs = gas.Show_All_Addresses__c ;
        trackAlignmentHistory  = gas.Track_Alignment_History__c;
        
        // Set up search fields
        acctSearchFields = new List <SearchField> () ;
        acctFieldMap = Schema.SObjectType.Account.fields.getMap();
        for (String f : acctSearchFieldSet) {
            Schema.DescribeFieldResult  dfr = acctFieldMap.get(f).getDescribe() ;
            acctSearchFields.add (new SearchField('Account',dfr)) ;
        }
        addrSearchFields = new List <SearchField> () ;
        addrFieldMap = Schema.SObjectType.Address_vod__c.fields.getMap();
        for (String f : addrSearchFieldSet) {
            Schema.DescribeFieldResult  dfr = addrFieldMap.get(f).getDescribe() ;
            addrSearchFields.add (new SearchField('Address_vod__c',dfr)) ;
        }
        // Parse resultFieldSet to get result Account and Address fields
        acctResultFields = new Set<String> () ;
        addrResultFields = new Set<String> () ;
        resultHeaders = new List<ResultHeader> () ;
        sortKey = '' ;
        sortDir = 'A' ;
        for (String rf : resultFieldSet) {
            if (sortKey == '') {
                // Set sortKey to first result field in list
                sortKey = rf; 
            }
            if (rf.startsWith('ADD.')) {
                String dataType = addrFieldMap.get(rf.replace('ADD.', '')).getDescribe().getType().name() ;
                resFieldTypeMap.put (rf, dataType) ;
                String label = addrFieldMap.get(rf.replace('ADD.', '')).getDescribe().getLabel() ;
                if (dataType == 'Reference') {
                    // We need to add Relationship.Name to acctResultFields
                    String rel = addrFieldMap.get(rf.replace('ADD.', '')).getDescribe().getRelationshipName() ;
                    addrResultFields.add(rel + '.Name') ;
                    // Remove trailing ' ID' from label
                    label = label.replaceFirst(' ID$', '') ;
                }
                resFieldLabelMap.put (rf, label) ;
                addrResultFields.add (rf.replace('ADD.', '')) ;
                ResultHeader rh = new ResultHeader () ;
                rh.label = label ;
                rh.apiname = rf ;
                resultHeaders.add (rh) ;
            }
            else {
                String dataType = acctFieldMap.get(rf).getDescribe().getType().name() ;
                resFieldTypeMap.put (rf, dataType) ;
                String label = acctFieldMap.get(rf).getDescribe().getLabel() ;
                if (dataType == 'Reference') {
                    // We need to add Relationship.Name to acctResultFields
                    String rel = acctFieldMap.get(rf).getDescribe().getRelationshipName() ;
                    acctResultFields.add(rel + '.Name') ;
                    // Remove trailing ' ID' from label
                    label = label.replaceFirst(' ID$', '') ;
                }
                resFieldLabelMap.put (rf, label) ;
                acctResultFields.add (rf) ;
                ResultHeader rh = new ResultHeader () ;
                rh.label = label ;
                rh.apiname = rf ;
                resultHeaders.add (rh) ;
            }
        }
        // Add the fields which we always need for Account and Address
        acctResultFields.add('Id') ;
        acctResultFields.add('FirstName') ;
        acctResultFields.add('LastName') ;
        acctResultFields.add('Name') ;
        acctResultFields.add('IsPersonAccount') ;
        addrResultFields.add('Id') ;
        addrResultFields.add('Account_vod__c') ;
        addrResultFields.add('Primary_vod__c') ;
               
    }

    public PageReference sortResults() {
        String newSortKey = ApexPages.currentPage().getParameters().get('sortKey');
        if (newSortKey == sortKey) {
            // Just change sortDir
            if (sortDir == 'A') {
                sortDir = 'D' ;
            }
            else {
                sortDir = 'A' ;
            }
        }
        else {
            sortKey = newSortKey ;
            sortDir = 'A' ;
        }
        results = SortSearchResults(results, sortKey, sortDir) ;
        return null ;
    }

    public PageReference doSearch() {
        
        try {
            results = new List<SearchResult> () ;
            Set <Id> gotAccts = new Set<Id> ();
            List <ID> acctIds = new List <String> () ;
            String whereClause = '' ;
            Boolean searchAddrFirst = false ;
            String prefix = '' ;
            // Determine if user has enetered any values for address search fields
            for (SearchField sf : addrSearchFields) {
                if (sf.value != '' && sf.value != 'null' && sf.value != null) {
                searchAddrFirst = true  ;
                prefix = 'Account_vod__r.' ;
                    break ;
                }
            } 
            // Boolean got_csz = false; // Got City, State or Zip
            // Boolean got_noncsz = false; // Other than City, State or Zip
            Boolean got_pname = false; // Got person name
            Boolean got_name = false; // Got full name

            // Combine the search fields
            List <SearchField> allSearchFields = new List <SearchField> () ;
            allSearchFields.addAll(acctSearchFields) ;
            allSearchFields.addAll(addrSearchFields) ;

            // Go thru each search field
            for (SearchField sf : allSearchFields) {
                if (sf.value != '' && sf.value != 'null' && sf.value != null) {
                    String field = sf.apiname ;
                    String op = '=' ;
                    String value = sf.value ;
                    // Escape any quotes in the value
                    //JK - changing to use escapeSingleQuotes method
                    //value = value.replace('\'', '\\\'') ;
                    value = String.escapeSingleQuotes(value);
                    
                    if (sf.obj == 'Account') {
                        field = prefix + field ;
                    }

                    if (sf.opt_value == 'Starts With') {
                        op = 'like' ;
                        value = value + '%' ;
                    }
                    if (sf.opt_value == 'Contains') {
                        op = 'like' ;
                        value = '%' + value + '%' ;
                    }

                    if (sf.is_phone) {
                        op = 'like' ;
                        value = getPhoneRegex(value) ;
                    }
                    
                    // Put quotes around val for relevant types
                    if(!sf.no_quote) {
                        value = '\'' + value + '\'' ;
                    }
                    if (whereClause != '') {
                        whereClause += ' AND ' ;
                    }
                    whereClause += ' ' + field + ' ' + op + ' ' + value;

                    if (sf.obj == 'Account') {
                        if (sf.apiname == 'Name') {
                            got_name = true ;
                        }
                        if (sf.apiname == 'FirstName' || sf.apiname == 'LastName') {
                            got_pname = true ;
                        }
                    }
                }
            }
            wc = whereClause ;
            if (whereClause == '') {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_NOCRIT));
                return null ;
            }
            if (got_pname == true && got_name == true) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_NAMESEARCH));
                return null ;
            }
            // if (got_csz == true && got_noncsz == false) {
                // ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, 'When enterting city, state or zip, at least one other search criteria must be provided'));
                // return null ;
            // }
            if (searchAddrFirst) {
                for (Address_vod__c ad : Database.query('select Account_vod__c, Account_vod__r.IsPersonAccount from Address_vod__c where ' + whereClause)) {
                        acctIds.add(ad.Account_vod__c) ;
                }
            }
            else {
                String resFields = joinStrings(acctResultFields,',') ;
                // Add Formatted_Name_vod__c if it's not there
                if (!resFields.contains('Formatted_Name_vod__c')) {
                    resFields += ',Formatted_Name_vod__c' ;
                }
                for (Account a : Database.query('select Id,IsPersonAccount from Account where ' + whereClause + ' order by Name,Id')) {
                        acctIds.add(a.Id) ;
                }
            }
wc = 'at 1' ;
            // Error if nothing found
            if (acctIds.size() == 0) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_NOMATCH));
                return null;
            }
            // If this is a search for parent, remove the account IDs we have found which are not parents.  We can do this
            // by using a GROUP BY clause which counts child accounts per parent.  This query will not return those Accounts
            // which have no child accounts.  Since we can't have more than 1000 elements in :acctIds, error out if we have more than 1000
            if (parentSearch == '1' && acctIds.size() > 1000) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_TOOMANY));
                return null;
            }
            Set <ID> distinctAcctIds = new Set<ID>() ;
System.debug ('parentSearch is ' + parentSearch) ;
            if (parentSearch == '1') {
                String query = 'select ' + parentAcctField + ', Count(Id) from Account where Primary_Parent_vod__c  in :acctIds group by ' + parentAcctField + '' ;
                AggregateResult[] groupedResults = database.query(query);
                for (AggregateResult ar : groupedResults)  {
                    System.debug('Primary_Parent_vod__c ID' + ar.get('Primary_Parent_vod__c'));
                    distinctAcctIds.add((String)ar.get('Primary_Parent_vod__c')) ;
                }
            }
            else {
                distinctAcctIds.addAll(acctIds) ;
            }
 /*           // Maximum of 20 distinct Accounts
 //mnaidu - commenting this section to allow users to use max size using a custom setting attribute
            if (distinctAcctIds.size() > 20) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_TOOMANY));
                return null;
            }
*/
            // We now do a Parent to Child query to get the Accounts we want, along with their addresses.  Order addresses by Primary Address
            String resFields = joinStrings(acctResultFields,',') ;
            // Add Formatted_Name_vod__c if it's not there
            if (!resFields.contains('Formatted_Name_vod__c')) {
                resFields += ',Formatted_Name_vod__c' ;
            }
            
            //mnaidu 7/16/2013 - GAS 2.1 enhancement
            //remove the account ids that need to be excluded
            if(GAS_Hierarchical_Setting__c.getInstance().Do_Criteria_Based_Filtering__c){
                acctIds = excludeAccountsIfAny(acctIds);
            }
           // Error if nothing found
            if (acctIds.size() == 0) {
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, GAS_NOMATCH));
                return null;
            }

   			//mnaidu - GAS 2.2 - Allows users to regulate max display size based on custom setting
            if (acctIds!=null && acctIds.size() > (Integer) GAS_Hierarchical_Setting__c.getInstance().MAX_Allowed_Distinct_Accounts__c) {
            	String warnMessage = GAS_TOOMANY + ' ( Found '+ acctIds.size() + ', Allowed ' + (Integer) GAS_Hierarchical_Setting__c.getInstance().MAX_Allowed_Distinct_Accounts__c +' )';
                ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.WARNING, warnMessage));
                return null;
            }

            String q = 'select ' + resFields + ', (select ' + joinStrings(addrResultFields,',') + ' from Address_vod__r order by Primary_vod__c desc, CreatedDate) from Account where Id in :acctIds' ;


            for (Account a : Database.query(q)) {
                SearchResult mainSR ;
                Integer ix = 0 ;
                if (a.Address_vod__r.size() > 0) {
                    for (Address_vod__c ad : a.Address_vod__r) {
                        // Build the searchResults
                        SearchResult sr = new SearchResult () ;
                        sr.acctId = a.Id ;
                        sr.addrId = a.Address_vod__r[ix].Id ;
                        sr.isSelected = false ;
                        // Now get field values 
                        sr.srFields = new List<SearchResultField> () ;
                        for (String rf : resultFieldSet) {
                            SearchResultField srf = new SearchResultField () ;
                            srf.apiname = rf ;
                            String typex  = resFieldTypeMap.get(rf) ;
                            if (rf.startsWith('ADD.')) {
                                srf.value = getObjValue(a.Address_vod__r[ix], rf, typex) ;
                                srf.label = resFieldLabelMap.get(rf) ;
                                srf.is_Addr = true ;
                                srf.is_Acct = false ;
                            }
                            else {
                                srf.value = getObjValue(a, rf, typex) ;
                                srf.label = resFieldLabelMap.get(rf) ;
                                // Use Formatted_Name_vod__c for Name
                                if (rf == 'Name') {
                                    srf.value = getObjValue(a, 'Formatted_Name_vod__c', 'String') ;
                                }
                                srf.is_Addr = false ;
                                srf.is_Acct = true ;
                            }
                            // The rawvalue of the srf will be used for sorting
                            srf.rawvalue = srf.value ;
                            if ((typex == 'Date' || typex == 'Datetime') && srf.value != '') {
                                // For sorting purposes, store rawvalue of Date/Datetime as seconds since epoch
                                String dtval = srf.value ;
                                if (typex == 'Date') {
                                    dtval = Datetime.newInstance(Date.parse(srf.value), Time.newInstance(0, 0, 0, 0)).format() ;
                                }
                                srf.rawvalue = (String) Datetime.parse(dtval).getTime().format() ;
                            }
                            sr.srFields.add(srf) ;
                        }
                        sr.acctName = a.Name ;
                        if (ix == 0) {
                            sr.otherAddrs = new List<SearchResult> () ;
                            mainSR = sr ;
                            results.add(mainSR) ;
                        }
                        else {
                            mainSR.otherAddrs.add(sr) ;
                        }
                        ix++ ;
                        // If we are not showing all addresses, and we are done with the first, then break out of loop
                        if (!showAllAddrs) {
                            break ;
                        }
                    }
                }
                else {
                    // No address, just get and set Account info
                    SearchResult sr = new SearchResult () ;
                    sr.acctId = a.Id ;
                    sr.addrId = '' ;
                    sr.isSelected = false ;
                    // Now get field values 
                    sr.srFields = new List<SearchResultField> () ;
                    for (String rf : resultFieldSet) {
                        SearchResultField srf = new SearchResultField () ;
                        srf.apiname = rf ;
                        String typex  = resFieldTypeMap.get(rf) ;
                        if (rf.startsWith('ADD.')) {
                            srf.value = '' ;
                            srf.label = resFieldLabelMap.get(rf) ;
                            srf.is_Addr = true ;
                            srf.is_Acct = false ;
                        }
                        else {
                            srf.value = getObjValue(a, rf, typex) ;
                            srf.label = resFieldLabelMap.get(rf) ;
                            // Use Formatted_Name_vod__c for Name
                            if (rf == 'Name') {
                                srf.value = getObjValue(a, 'Formatted_Name_vod__c', 'String') ;
                            }
                            srf.is_Addr = false ;
                            srf.is_Acct = true ;
                        }
                        // The rawvalue of the srf will be used for sorting
                        srf.rawvalue = srf.value ;
                        if ((typex == 'Date' || typex == 'Datetime') && srf.value != '') {
                            // For sorting purposes, store rawvalue of Date/Datetime as seconds since epoch
                            String dtval = srf.value ;
                            if (typex == 'Date') {
                                dtval = Datetime.newInstance(Date.parse(srf.value), Time.newInstance(0, 0, 0, 0)).format() ;
                            }
                            srf.rawvalue = (String) Datetime.parse(dtval).getTime().format() ;
                        }
                        sr.srFields.add(srf) ;
                    }
                    sr.acctName = a.Name ;
                    sr.otherAddrs = new List<SearchResult> () ;
                    mainSR = sr ;
                    results.add(mainSR) ;
                }
            }
            // Sort.  Initial sort is by first result field, which has already been set in constructor
            results = SortSearchResults(results, sortKey, sortDir) ;
        }
        catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference addToTerritory() {
        String newAcctId  = '';
        if (results == null || results.size() == 0) {
            return null ;
        }
        // Find the selected Account
        for (SearchResult sr : results) {
            if (sr.isSelected == true) {
                newAcctId = sr.acctId ;
                break ;
            }
        }
        if (newAcctId == '') {
            return null ;
        }

        // Get the territory for the user
        //jkelso - 8/12/13 - build list of multiple territories and territory Ids
        List<UserTerritory2Association> utList = new List<UserTerritory2Association>();
        List<Id> utIds = new List<Id>();
        for (UserTerritory2Association ut :[SELECT Territory2Id FROM UserTerritory2Association WHERE UserId = :UserInfo.getUserId()]) {
            system.debug(LoggingLevel.Info,'ut: ' + ut);
            utList.add(ut);
            utIds.add(ut.Territory2Id);
        }
        system.debug('utList: ' + utList);
        if (utList.size() == 0) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,GAS_NOTALGN));
            return null ;
        }
        //jkelso - 8/12/13 - new custom setting to allow align of multiple territory
        else if (utList.size() > 1 && !GAS_ALIGN_MULTIPLE) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,GAS_MANYALGN));
            return null ;
        }
        // Get the name of the Territory
        List<String> userTerrNames = new List<String>();
        String terrString = '';
        //jkelso - 8/12/13 - build string of multiple territories
        system.debug('utIds: ' + utIds);
        for (Territory2  t : [SELECT Name FROM Territory2  WHERE ID IN :utIds]) {
            userTerrNames.add(t.Name);
            terrString += t.Name + ';';
        }
        terrString  = terrString.Substring(0,terrString.length()-1);
        system.debug('terrString after building territories');
        // Now check for existing territories for the Account
        List <ObjectTerritory2Association > asList = [SELECT ObjectId ,Territory2Id , AssociationCause  FROM ObjectTerritory2Association  WHERE ObjectId  =  :newAcctId //and RowCause in ('TerritoryManual') - mnaidu;04/28/13 - check for any kinds of alignment
        ] ;
        if (asList.size() > 0) {
            // Get all the UserOrGroupIds, and store in a List
            List<Id> idlist1 = new List<Id> () ;
            Set<Id> manuallyAssignedGrpIDs = new Set<ID>();//mnaidu - 4/28/13 - capture what's manually assigned
            Set<Id> manuallyAssignedTerrIDs = new Set<ID>();//mnaidu - 4/28/13 - capture what's manually assigned
            for (ObjectTerritory2Association ash : asList) {
                idlist1.add(ash.Territory2Id ) ;
                if(ash.AssociationCause =='Territory2Manual'){
                    manuallyAssignedGrpIDs.add(ash.Territory2Id );   //mnaidu - 4/28/13 - capture what's manually assigned              
                }
            }
            // Now let's get the IDs of the Territories
            List<Id> idlist2 = new List<Id> () ;
            List<Group> groupList = [select RelatedId from group where Id in :idlist1] ;
            for (Group g : groupList) {
                idlist2.add(g.RelatedId) ;
                if(manuallyAssignedGrpIDs.contains(g.Id)){
                    manuallyAssignedTerrIDs.add(g.RelatedId); //mnaidu - 4/28/13 - capture what's manually assigned
                }
            }
            // Finally, get the names
            List <Territory2 > terrList = [select Id, Name from Territory2  where Id in :idlist2] ;
            for (Territory2  t : terrList) {
                // If the Territory is already there, output a warning and exit
                for (String utn : userTerrNames) {
                    if (t.Name == utn) {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,GAS_INTERR));
                        return null ;
                    }
                }
                if(manuallyAssignedTerrIDs.contains(t.Id)){ //mnaidu - 4/28/13 - only add to the terrString if this is Manually already assigned
                    terrString = terrString + ';' + t.Name ;                    
                }
            }
        }
        
        GAS_Alignment_History_vts__c history = new GAS_Alignment_History_vts__c();
        
        try{
            //track that Account to be aligned
            history.Account__c = newAcctId;
            history.New_Territory__c = terrString;
            
            // Now let's see if the Account Territory Loader already exists
            List <Account_Territory_Loader_vod__c> atlList = [select Id, Territory_vod__c from Account_Territory_Loader_vod__c where Account_vod__c = :newAcctId] ;
            if (atlList.size() == 1) {
                Account_Territory_Loader_vod__c atl = atlList[0] ;
                
                //track ATL and old territory string
                history.Account_Territory_Loader__c = atl.Id;
                history.Old_Territory__c = atl.Territory_vod__c;
                
                //set new ATL territory
                atl.Territory_vod__c = terrString ;
                
                System.debug('Before updating the ATL reco: ' +  atl.Territory_vod__c);

                update (atl) ;
 
                 System.debug('After updating the ATL reco: ' +  atl.Territory_vod__c);
 
                
                //insert history record
                if (trackAlignmentHistory) {
                    insert history;
                }
                
            }
            else {
                Account_Territory_Loader_vod__c atl = new Account_Territory_Loader_vod__c(Account_vod__c=newAcctId,External_ID_vod__c=newAcctId,Territory_vod__c=terrString);
                insert (atl) ;
                
                //track history
                history.Account_Territory_Loader__c = atl.Id;
                if (trackAlignmentHistory) {
                    insert history;
                }
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,GAS_SUCCESS));
        }
        catch(DmlException ex){
            ApexPages.addMessages(ex);
        }
        return null ;
    }

    public PageReference cancel() {
        return null ;
    }



    private static String joinStrings (Set<String> ss, String delim) {
        String retVal = '' ;
        for (String s : ss) {
            if (retVal != '')  {
                retVal += delim ;
            }
            retVal += s ;
        }
        return retVal ;
    }

    private static String getPhoneRegex (String inph) {

        Pattern pt = Pattern.compile('[^0-9]');
        String [] res = pt.split(inph) ;
        String digits = '' ;
        for (Integer i = 0 ; i < res.size(); i++) {
        System.debug ('r1:' + res[i]) ;
            digits = digits + res[i] ;
        }
        System.debug ('r2:' + digits) ;
        String retval= '';

        if (digits.length() == 10) {
            retval = '%' + digits.substring(0,3) + '%' + digits.substring(3,6) + '%' + digits.substring (6,10) + '%' ;
        }
        else if (digits.length() == 7) {
            retval = '%' + digits.substring(0,3) + '%' + digits.substring(3,7) + '%' ;
        }
        else if (digits.length() == 4) {
            retval = '%' + digits ;
        }
        else {
            retval = digits ;
        }
System.debug ('r3:' + retval) ;
        return retval ;
    }

    private String getObjValue (sObject so, String fname, String typex) {
        if (typex == 'Reference') {
            // Get relationship name
            String relship ;
            if (fname.startsWith('ADD.')) {
                relship = addrFieldMap.get(fname.replace('ADD.', '')).getDescribe().getRelationshipName() ;
            }
            else {
                relship = acctFieldMap.get(fname).getDescribe().getRelationshipName() ;
            }
            // Display Name field of lookup value
            SObject so2 = so.getSObject(relship);
            if (!fname.contains('RecordTypeId') && so2 != null) {
                return (String) so2.get('Name') ;
            }
            else if (fname.contains('RecordTypeId') && so2 != null) {
                // We have the value, we need to translate it
                return recTypeXlation.get((String) so2.get('Name'));
            }
            return '' ;
        }
        if (fname.startsWith('ADD.')) {
            fname = fname.replace('ADD.', '') ;
        }
        if (typex == 'Boolean') {
            Boolean b = (Boolean) so.get(fname) ;
            return (b == true ? '[X]' : '[ ]') ;
        }
        else if (typex == 'Date') {
            Date d = (Date) so.get(fname) ;
            if (d != null) {
                return d.format() ;
            }
            else {
                return '' ;
            }
        }
        else if (typex == 'Datetime') {
            Datetime d = (Datetime) so.get(fname) ;
            if (d != null) {
                return d.format() ;
            }
            else {
                return '' ;
            }
        }
        else {
            return (String) so.get(fname) ;
        }
    }


    private List<SelectOption> SortOptionList(List<SelectOption> ListToSort) {

        // Simple quick sort : see http://improveit360.blogspot.com/2010/09/implementing-quicksort-to-sort-list-of.html
        if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
            
        List<SelectOption> Less = new List<SelectOption>();
        List<SelectOption> Greater = new List<SelectOption>();
        integer pivot = ListToSort.size() / 2;
          
        // save the pivot and remove it from the list
        SelectOption pivotValue = ListToSort[pivot];
        ListToSort.remove(pivot);
        
        for(SelectOption x : ListToSort)
        {
            if(x.getLabel() <= pivotValue.getLabel())
                Less.add(x);
            else if(x.getLabel() > pivotValue.getLabel()) Greater.add(x);   
        }
        List<SelectOption> xList = new List<SelectOption> ();
        xList.addAll(SortOptionList(Less));
        xList.add(pivotValue);
        xList.addAll(SortOptionList(Greater));
        // Dedupe
        List<SelectOption> returnList = new List<SelectOption> ();
        Set<String> labelSet = new Set<String> () ;
        returnList.add(new SelectOption('',GAS_NONE)) ;
        labelSet.add(GAS_NONE) ;
        for(SelectOption x : xList) {
            if (!labelSet.contains(x.getLabel())) {
                returnList.add(x) ;
                labelSet.add(x.getLabel()) ;
            }
        }
        return returnList; 
    }  
    
            //mnaidu 7/16/2013 - GAS 2.1 enhancement
            //remove the account ids that need to be excluded
/**
***** @author = Murugesh Naidu
***** @date = July 17, 2013
***** @param - List of Account Ids to process
***** @return - List of Account Ids after exclusion criteria applied
***** GAS 2.1 enhancements
***** Feb 17, 2014 - Added fix to return empty set (zero accounts) if mode is Retain and no accounts are to be included
**/
    private List<ID> excludeAccountsIfAny(List<ID> accountIds){
        
        if(accountIds==null || accountIds.size() == 0){
            return accountIds;
        }
        Set<ID> originalAcctIds = new Set<ID> ();
        //mnaidu - 1/9/2014 - additionally pass the "accountIds" to avoid full table scans
        Set<ID> idsToIncludeExclude = GASUtilities.getAccountIdsToExclude(UserInfo.getUserId(), accountIds); 
        //mnaidu - 1/9/2014 - check to see if the filters are supposed to be retain the filter results
        // or exclude the filter results from the general unfiltered search
        Boolean retain = (GAS_Hierarchical_Setting__c.getInstance().Enable_CB_Filter_Retain_Mode__c == null) 
        							? false : GAS_Hierarchical_Setting__c.getInstance().Enable_CB_Filter_Retain_Mode__c ;
        if(retain && (idsToIncludeExclude == null || idsToIncludeExclude.size() == 0)){
        	//no accounts should be shown
        	accountIds.clear();
        	return accountIds;
        }
        if(idsToIncludeExclude!=null && idsToIncludeExclude.size() > 0){
            originalAcctIds.addAll(accountIds);
            if(retain){
            	originalAcctIds.retainAll(idsToIncludeExclude);
            }
            else{
            	originalAcctIds.removeAll(idsToIncludeExclude);
            }
            
            accountIds.clear();
            accountIds.addAll(originalAcctIds);
        }
        return accountIds;
    }

    private List<SearchResult> SortSearchResults (List<SearchResult> ListToSort, String keyField, String sortDir) {

        if (keyField != '') {
            // Set key field for each SearchResult
            for(SearchResult x : ListToSort) {
                for (SearchResultField y : x.srFields) {
                    // Find the keyField
                    if (y.apiname == keyField) {
                        x.key = y.rawvalue ;
                        break ;
                    }
                }
            }
        }

        // Ok, now we have the keys, can do a simple quick sort. See : http://improveit360.blogspot.com/2010/09/implementing-quicksort-to-sort-list-of.html
        if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
            
        List<SearchResult> Less = new List<SearchResult>();
        List<SearchResult> Greater = new List<SearchResult>();
        integer pivot = ListToSort.size() / 2;
          
        // save the pivot and remove it from the list
        SearchResult pivotValue = ListToSort[pivot];
        ListToSort.remove(pivot);
        
        if (sortDir == 'A') { // Ascending
            for(SearchResult x : ListToSort)
            {
                if(x.key <= pivotValue.key)
                    Less.add(x);
                else if(x.key > pivotValue.key) Greater.add(x);   
            }
        }
        else { // Descending 
            for(SearchResult x : ListToSort)
            {
                if(x.key <= pivotValue.key)
                    Greater.add(x);
                else if(x.key > pivotValue.key) Less.add(x);   
            }
        }
        List<SearchResult> returnList = new List<SearchResult> ();
        returnList.addAll(SortSearchResults(Less, '', sortDir));
        returnList.add(pivotValue);
        returnList.addAll(SortSearchResults(Greater, '', sortDir));
        return returnList; 
    }  

    public class SearchResult {

        public String acctId {get;set;}
        public String acctName {get;set;}
        public String addrId {get;set;}
        public Boolean isSelected {get;set;}
        public String key {set;get;}
        public List<SearchResultField> srFields {get;set;}
        public List<SearchResult> otherAddrs {get;set;}

    }

    public class SearchResultField {

        public String apiname {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String rawvalue {get;set;}
        public Boolean is_Acct {get;set;}
        public Boolean is_Addr {get;set;}
    }

    public class SearchField {

        public String obj {get;set;}
        public String label {get;set;}
        public String apiname {get;set;}
        public String value {get;set;}
        public String alvalue {get;set;}
        public String opt_value {get;set;}
        public Boolean is_picklist {get;set;}
        public Boolean is_reference {get;set;}
        public Boolean is_phone {get;set;}
        public Boolean is_bool {get;set;}
        public Boolean is_acctlookup {get;set;}
        public Boolean has_es {get;set;}
        public Boolean has_cs {get;set;}
        public Boolean no_quote {get;set;}
        public Boolean no_opt {get;set;}
        public Boolean no_picklist {get;set;}
        public List<SelectOption> plist {set;get;}

        public SearchField (String o, Schema.DescribeFieldResult dfr) {
            obj = o ;
            label = dfr.getLabel() ;
            apiname = dfr.getName () ;
            value = '' ;
            opt_value = '' ;
            is_acctlookup = false ;
            is_reference = (dfr.getType().name() == 'Reference') ;
            is_picklist = (dfr.getType().name() == 'Picklist') ;
            is_phone = (dfr.getType().name() == 'Phone') ;
            is_bool = (dfr.getType().name() == 'Boolean') ;
            no_quote = (dfr.getType().name() == 'Boolean' ||
                        dfr.getType().name() == 'Currency' ||
                        dfr.getType().name() == 'Date' ||
                        dfr.getType().name() == 'Datetime' ||
                        dfr.getType().name() == 'Double' ||
                        dfr.getType().name() == 'Integer' ||
                        dfr.getType().name() == 'Percent' ||
                        dfr.getType().name() == 'Time') ;
            if (is_picklist) {
                plist = new List<SelectOption> () ;
                List<Schema.PicklistEntry> P = dfr.getPicklistValues();
                plist.add(new SelectOption('',searchAccts.GAS_NONE)) ;
                for (Schema.PicklistEntry pe : P) {
                    plist.add(new SelectOption(pe.getValue(),pe.getLabel()));
                }
            }
            if (is_reference) {
                // Make it a picklist of names
                is_picklist = true ;
                // Remove trailing ' ID' from label
                label = label.replaceFirst(' ID$', '') ;
                List <Schema.sObjectType> sobjs = dfr.getReferenceTo() ;
                String objName = sobjs[0].getDescribe().getName() ;
System.debug ('objName is ' + objName) ;
                if (objName == 'RecordType') {
                    // Already calculated
                    plist = obj == 'Account' ? searchAccts.acctRecTypesPlist.clone()  : searchAccts.addrRecTypesPlist.clone() ;
                }
                else if (objName != 'Account') {
                    // All other references
                    plist = new List<SelectOption> () ;
                    plist.add(new SelectOption('',searchAccts.GAS_NONE)) ;
                    String query = 'select Id,Name from ' + objName + ' order by Name' ;
                    for (sObject ox : Database.query(query)) {
                        plist.add(new SelectOption((String)ox.get('Id'), (String)ox.get('Name'))) ;
                    }
                }
                else {
                    // objName is Account.  We don't want to display thousands or more Account names in a picklist,
                    // so we handle this by creating a link to aonther search page.
                    is_acctlookup = true ;
                }
System.debug ('is_acctlookup is ' + is_acctlookup) ;
            }
            has_es = (obj == 'Account' && (apiname == 'Name' || apiname == 'FirstName' || apiname == 'LastName')) ;
            has_cs = (obj == 'Address_vod__c' && apiname == 'Name') ;
            if (has_es) {
                opt_value = 'Exact Match' ;
            }
            if (has_cs) {
                opt_value = 'Starts With' ;
            }
            no_opt = !has_cs && !has_es && !is_acctlookup;
            no_picklist = !is_picklist ;
        }




    } 

    public class ResultHeader {

        public String label {set;get;} 
        public String apiname {set;get;} 

    }
}