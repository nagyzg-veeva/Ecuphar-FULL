/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2021 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * VeevaExpenseRuleService checks expense rule violation by event expense and business rules.
 *
 */
global without sharing class VeevaEmExpenseRuleService extends VeevaEmBusRuleService {
    private static final Set<String> PER_EVENT_EXPENSE_TYPES = new Set<String>{'EM_Per_Event_Expense_Limit_Rule_vod', 'EM_Per_Event_Attendee_Expense_Limit_Rule_vod', 'EM_Actual_Versus_Estimate_Expense_Threshold_Rule_vod', 'EM_Per_Event_Speaker_Expense_Limit_Rule_vod'};
    private static final Set<String> PER_ATTENDEE_EXPENSE_TYPES = new Set<String>{'EM_Attendee_Expense_Cap_Rule_vod', 'EM_Per_Event_Attendee_Expense_Limit_Rule_vod', 'EM_Cross_Event_Attendee_Expense_Cap_Rule_vod'};
    private static final Set<String> ATTENDEE_CAP_EXPENSE_TYPES = new Set<String>{'EM_Attendee_Expense_Cap_Rule_vod', 'EM_Cross_Event_Attendee_Expense_Cap_Rule_vod'};
    private static final String ESTIMATE = 'Estimate_vod';
    private static final String ACTUAL = 'Actual_vod';
    private static final String SEPARATOR = ';;';
    private static final String EVENT_RELATIONSHIP = 'Event_vod__r';
    private static final String ATTENDEE_TYPE = 'Attendee_vod';
    private static final String SPEAKER_TYPE = 'Event_Speaker_vod';
    private List<VeevaEmBusRuleModel.BusinessRule> rules;
    private Map<String, VeevaEmBusRuleModel.BusinessRule> ruleMap;
    private ExpenseRequest expenseRequest;
    private ExpenseResult expenseResult = new ExpenseResult();
    
    public ExpenseResult processExpenseRules(ExpenseRequest request) {     
        try {
            expenseRequest = request;
            validateRequest(expenseRequest.eventId, expenseRequest.ruleIds);
            initExpenseRequest();
            expenseResult = findRuleViolations();
            setResponse(expenseResult, res, true, null, 200);
        } catch (VeevaEmBusRuleModel.BadDataException be) {                
            setResponse(expenseResult, res, false, be.getMessage(), 400);           
        } catch (Exception e) {
            setResponse(expenseResult, res, false, e.getMessage(), 500);
        }
        return expenseResult;
    }
    
    public static void setResponse(ExpenseResult result, RestResponse response, boolean success, String errorMessage, Integer statusCode){
        result.success = success;   
        result.errorMessage = errorMessage;
        response.statusCode = statusCode;
    }
    
    private List<ExpenseAttributionRequest> getAttributionRequest(){ 
        List<ExpenseAttributionRequest> allAttributions = new List<ExpenseAttributionRequest>();
        if(VeevaEmBusRuleUtils.isEmpty(expenseRequest.expenseLines)){
            return allAttributions;
        }
        for (ExpenseLineRequest line : expenseRequest.expenseLines){
            List<ExpenseAttributionRequest> attributions = line.expenseAttribution;
            if(VeevaEmBusRuleUtils.isNotEmpty(attributions)){
                allAttributions.addAll(attributions);
            }
        } 
        return allAttributions;
    }
    
    private void initEventRequestRelated() {
        EM_Event_vod__c event = [SELECT RecordTypeId, Country_vod__c, Start_Time_vod__c FROM EM_Event_vod__c WHERE Id = :expenseRequest.eventId];
        expenseRequest.startTime = event.Start_Time_vod__c;
        expenseRequest.eventType = VeevaEmBusRuleUtils.getDeveloperName(Schema.SObjectType.EM_Event_vod__c.getRecordTypeInfosById(), event.RecordTypeId);
        expenseRequest.country = event.Country_vod__c;
    }
    
    private boolean hasAttendee(List<String> eventAttendeeIds){
        boolean hasAttendee = true;
        if(String.isEmpty(expenseRequest.eventAction) && VeevaEmBusRuleUtils.isNotEmpty(expenseRequest.expenseLines)
           && eventAttendeeIds.size() == 0){
               hasAttendee = false;
        }
        return hasAttendee;
    }
    
    private List<EM_Attendee_vod__c> getEventAttendees(List<String> eventAttendeeIds){
        //come from presave without attendee info
        if(!expenseRequest.hasAttendee){
            return null;
        }
        String eventAttendeesQuery = 'SELECT Id, Account_vod__c, User_vod__c, Contact_vod__c, Attendee_Account_Type_vod__c, Status_vod__c, '          
            + ' First_Name_vod__c, Last_Name_vod__c, Attendee_Name_vod__c,'                     
            + ' Event_vod__r.RecordTypeId, Event_vod__r.Country_vod__c, Event_vod__r.Start_Time_vod__c, Event_vod__r.Topic_vod__c'                       
            + ' FROM EM_Attendee_vod__c WHERE Event_vod__c = \'' + expenseRequest.eventId + '\'';
        if(eventAttendeeIds.size() > 0) {
            eventAttendeesQuery += ' AND Id IN ' + VeevaEmBusRuleUtils.toCommaSeparated(eventAttendeeIds);
        }else if(String.isNotEmpty(expenseRequest.expenseHeaderId)) {
            eventAttendeesQuery += ' AND Id IN (SELECT Incurred_Expense_Attendee_vod__c FROM Expense_Attribution_vod__c WHERE Expense_Line_vod__r.Expense_Header_vod__c = \'' + expenseRequest.expenseHeaderId + '\')';
        }
        return Database.query(eventAttendeesQuery);
    }
    
    private void initExpenseTypes(){
        List<String> expenseTypeIds = new List<String>();
        for (VeevaEmBusRuleModel.BusinessRule rule : rules){ 
            if(String.isNotEmpty(rule.expenseType)){
                expenseTypeIds.add(rule.expenseType);  
            }
        }
        if (VeevaEmBusRuleUtils.isEmpty(expenseTypeIds)) {
            return;
        }
        expenseRequest.expenseTypeMap = new Map<String, Set<String>>();
        expenseRequest.expenseTypeNameMap = new Map<String, String>();
        expenseRequest.parentExpenseTypeMap = new Map<String, String>();
        for(Expense_Type_vod__c expenseType : [SELECT Id, Name, (SELECT Id, Name FROM Parent_Expense_Type_vod__r), Parent_Expense_Type_vod__c FROM Expense_Type_vod__c WHERE Id IN : expenseTypeIds]){
            String expenseTypeId = expenseType.Id;
            expenseRequest.expenseTypeNameMap.put(expenseTypeId, expenseType.Name);
            String parentExpenseTypeId = (String)expenseType.get('Parent_Expense_Type_vod__c');
            if (parentExpenseTypeId != null) {
                expenseRequest.parentExpenseTypeMap.put(expenseTypeId, parentExpenseTypeId);
            }
            List<SObject> childExpenseTypes = expenseType.getSObjects('Parent_Expense_Type_vod__r');
            if(childExpenseTypes != null && childExpenseTypes.size() > 0){   
                Set<String> childExpenseTypeIds = new Set<String>();
                for(SObject childExpenseType : childExpenseTypes){
                    expenseRequest.expenseTypeNameMap.put(childExpenseType.Id, (String)childExpenseType.get('Name'));
                    childExpenseTypeIds.add(childExpenseType.Id);
                }
                expenseRequest.expenseTypeMap.put(expenseTypeId, childExpenseTypeIds);
            }else{
                expenseRequest.expenseTypeMap.put(expenseTypeId, new Set<String>());
            }
        }
    }
    
    private void initPreSaveAttributions(List<ExpenseAttributionRequest> attributions){
        String groupKey;
        Map<String, String> eventAttendeeKeys = expenseRequest.eventAttendeeKeys;
        //key is account id or user id or contact id
        expenseRequest.preSaveAttributionMap = new Map<String, List<ExpenseAttributionRequest>>();
        Map<String, ExpenseAttributionRequest> attendeeAttributionMap = new Map<String, ExpenseAttributionRequest>();
        ExpenseAttributionRequest groupAttribution;
        for (ExpenseAttributionRequest attribution : attributions){ 
            if(String.isNotBlank(attribution.attendee)){  
                groupKey = attribution.expenseType + attribution.currencyIsoCode + attribution.attendee;
                if(attendeeAttributionMap.get(groupKey) == null){   
                    groupAttribution = attribution.clone();
                    attendeeAttributionMap.put(groupKey, groupAttribution);
                }else{
                    attendeeAttributionMap.get(groupKey).actual += attribution.actual;
                }
            } 
        }          
        if(attendeeAttributionMap.size() > 0){                
            for (String key : attendeeAttributionMap.keySet()){                   
                groupAttribution = attendeeAttributionMap.get(key);
                if(expenseRequest.preSaveAttributionMap.get(eventAttendeeKeys.get(groupAttribution.attendee)) == null){                
                    List<ExpenseAttributionRequest> preSaveData = new List<ExpenseAttributionRequest>();
                    preSaveData.add(groupAttribution);
                    expenseRequest.preSaveAttributionMap.put(eventAttendeeKeys.get(groupAttribution.attendee), preSaveData);
                }else{
                    expenseRequest.preSaveAttributionMap.get(eventAttendeeKeys.get(groupAttribution.attendee)).add(groupAttribution);                   
                }
            }
        }
    }
    
    private void initAttendeeInfo(List<String> eventAttendeeIds, List<ExpenseAttributionRequest> attributions){
        expenseRequest.attendeeKeyMap = new Map<String, String>();
        expenseRequest.eventAttendeeKeys = new Map<String, String>();
        expenseRequest.ruleAttendees = new Map<String, RuleAttendee>();
        List<EM_Attendee_vod__c> eventAttendees = getEventAttendees(eventAttendeeIds);        
        if (VeevaEmBusRuleUtils.isNotEmpty(eventAttendees)) {
            expenseRequest.accountIds = new Set<String>();
            expenseRequest.userIds = new Set<String>();
            expenseRequest.contactIds = new Set<String>();
            for (EM_Attendee_vod__c attendee : eventAttendees) {
                String attendeeId;
                if (attendee.Account_vod__c != null) {
                    attendeeId = attendee.Account_vod__c;
                    expenseRequest.accountIds.add(attendee.Account_vod__c);
                }
                if (attendee.User_vod__c != null) {
                    attendeeId = attendee.User_vod__c;
                    expenseRequest.userIds.add(attendee.User_vod__c);
                }
                if (attendee.Contact_vod__c != null) {
                    attendeeId = attendee.Contact_vod__c;
                    expenseRequest.contactIds.add(attendee.Contact_vod__c);
                }
                if (String.isNotBlank(attendeeId)) {                    
                    expenseRequest.eventAttendeeKeys.put(attendee.Id, attendeeId);
                    expenseRequest.attendeeKeyMap.put(attendeeId, attendee.Id);
                    if (!expenseRequest.ruleAttendees.containsKey(attendeeId)) { 
                        RuleAttendee ruleAttendee = new RuleAttendee(attendee.Account_vod__c, attendee.User_vod__c, attendee.Contact_vod__c);                  
                        ruleAttendee.attendeeName = attendee.Attendee_Name_vod__c;
                        ruleAttendee.attendeeAccountType = attendee.Attendee_Account_Type_vod__c;
                        ruleAttendee.attendeeFirstName = attendee.First_Name_vod__c;
                        ruleAttendee.attendeeLastName = attendee.Last_Name_vod__c;
                        expenseRequest.ruleAttendees.put(attendeeId, ruleAttendee);                
                    }
                }                
            }
            initPreSaveAttributions(attributions);  
        }
    }
    
    private void initExpenseRequest() {            
        initEventRequestRelated();  
        rules = VeevaEmBusRuleModel.getBusinessRules(expenseRequest.ruleIds, expenseRequest.eventType
                                                             , expenseRequest.country, expenseRequest.startTime);
        //data from memory
        List<sObject> queryRowFromPreSave = new List<sObject>();
        Map<String, List<sObject>> rowFromPreSaveMap = new Map<String, List<sObject>>();
        expenseRequest.attributionIds = new Set<String>();
        
        List<ExpenseAttributionRequest> attributions = getAttributionRequest();
        List<String> eventAttendeeIds = new List<String>();
        for (ExpenseAttributionRequest attribution : attributions){
            expenseRequest.attributionIds.add(attribution.Id);
            if(String.isNotEmpty(attribution.attendee)){
                eventAttendeeIds.add(attribution.attendee);  
            }
        }
        initExpenseTypes();
        expenseRequest.hasAttendee  = hasAttendee(eventAttendeeIds);
        if(!hasRuleType(PER_ATTENDEE_EXPENSE_TYPES)){
            return;
        }
        initAttendeeInfo(eventAttendeeIds, attributions);
    }
    
    private String getParentExpenseType(String expenseType){
        String result;
        Map<String, Set<String>> expenseTypeMap = expenseRequest.expenseTypeMap;
        if(expenseTypeMap != null && expenseTypeMap.size() > 0){
            for (String parentExpenseType : expenseTypeMap.keySet()){
                Set<String> childExpenseTypes = expenseTypeMap.get(parentExpenseType);
                if(childExpenseTypes.contains(expenseType)){
                    result = parentExpenseType;
                    break;
                }   
            }            
        }
        return result;
    }
    
    private void addExpenseTypes(List<ExpenseLineRequest> expenseLines, Set<String> expenseTypes) {
        for(ExpenseLineRequest line : expenseLines) {
            addTypeAndParentType(line.expenseType, expenseTypes);
        }
    }
    
    private boolean hasEstimateCategoryRule(){
        boolean hasEstimateCategory = false;
        for(VeevaEmBusRuleModel.BusinessRule rule : rules){
            if(ESTIMATE.equals(rule.expenseCategory)){
                hasEstimateCategory = true;
                break;
            }  
        }
        return hasEstimateCategory;
    }

    private void queryAndAddExpenseTypesForHeader(Set<String> expenseTypes) {
        String query = 'SELECT Expense_Type_vod__c FROM Expense_Line_vod__c WHERE Event_vod__c = \'' + expenseRequest.eventId + '\'';
        //if has expense header id, just limit the expense types to expense lines, else need fetch from estimate as well
        if(String.isNotEmpty(expenseRequest.expenseHeaderId)){
            query += 'AND Expense_Header_vod__c = \'' + expenseRequest.expenseHeaderId + '\'';
        } else if(hasEstimateCategoryRule()){
            String estimateQuery = 'SELECT Expense_Type_vod__c FROM EM_Expense_Estimate_vod__c WHERE Event_vod__c = \'' + expenseRequest.eventId + '\'';
            for(EM_Expense_Estimate_vod__c estimate : Database.query(estimateQuery)) {
                if(String.isNotEmpty(estimate.Expense_Type_vod__c)){
                    addTypeAndParentType(estimate.Expense_Type_vod__c, expenseTypes);
                }
            }
        }
        for(Expense_Line_vod__c line : Database.query(query)) {
            if(String.isNotEmpty(line.Expense_Type_vod__c)){
                addTypeAndParentType(line.Expense_Type_vod__c, expenseTypes);
            }
        }  
    }

    private void addTypeAndParentType(String expenseType, Set<String> expenseTypes) {
        if(!expenseTypes.contains(expenseType)){
            expenseTypes.add(expenseType);
            String parentExpenseType = getParentExpenseType(expenseType);
            if(String.isNotEmpty(parentExpenseType)){
                expenseTypes.add(parentExpenseType);
            }
        } 
    }
        
    private Set<String> getExpenseTypes(){          
        Set<String> expenseTypes = new Set<String>();  
        List<ExpenseLineRequest> expenseLines = expenseRequest.expenseLines;
        if (VeevaEmBusRuleUtils.isNotEmpty(expenseLines)) {    
            addExpenseTypes(expenseLines, expenseTypes);  
        }else{
            queryAndAddExpenseTypesForHeader(expenseTypes);
        }
        return expenseTypes;
    }
    
    private List<VeevaEmBusRuleModel.BusinessRule> filterBusinessRules(){
        List<VeevaEmBusRuleModel.BusinessRule> validRules = new List<VeevaEmBusRuleModel.BusinessRule>();
        Set<String> expenseTypes = getExpenseTypes();
        if(expenseTypes.size() > 0){
            for(VeevaEmBusRuleModel.BusinessRule rule : rules){                
                if(String.isEmpty(rule.expenseType) || expenseTypes.contains(rule.expenseType)){
                    validRules.add(rule);
                }
            } 
        }else{
            validRules = rules;
        }
        ruleMap = new Map<String, VeevaEmBusRuleModel.BusinessRule>();
        for(VeevaEmBusRuleModel.BusinessRule rule : validRules){                
            ruleMap.put(rule.Id, rule);
        }
        return validRules;
    }
    
    private static List<String> replaceFieldInIdClauseBatch(List<String> idClauseBatch){
        List<String> newIdClauseBatch = new List<String>();
        if(idClauseBatch != null && idClauseBatch.size() > 0){
            String prefix = 'Incurred_Expense_Attendee_vod__r.';
            for(String idClause : idClauseBatch){
                idClause = idClause.replace(VeevaEmBusRuleUtils.ATTENDEE_ACCOUNT, prefix + VeevaEmBusRuleUtils.ATTENDEE_ACCOUNT)
                    .replace(VeevaEmBusRuleUtils.ATTENDEE_USER, prefix + VeevaEmBusRuleUtils.ATTENDEE_USER)
                    .replace(VeevaEmBusRuleUtils.ATTENDEE_CONTACT, prefix + VeevaEmBusRuleUtils.ATTENDEE_CONTACT);
                newIdClauseBatch.add(idClause);
            }
        }
        return newIdClauseBatch;
    }

    private ExpenseResult findRuleViolations() {
        expenseResult.ruleViolations = new List<ExpenseViolation>();
        rules = filterBusinessRules();
        EventExpenseData expenseData; 
        if(hasRuleType(PER_EVENT_EXPENSE_TYPES)){
            //query current event expense related info accordingly
            expenseData = getCurrentEventExpenseData();
        }
        expenseResult.ruleAttendees = new Map<String, RuleAttendee>();
        if(expenseRequest.ruleAttendees != null && !expenseRequest.ruleAttendees.isEmpty()){
            expenseResult.ruleAttendees = expenseRequest.ruleAttendees;
        }
        Set<String> accountNameIds = new Set<String>();
        List<String> accounts = new List<String>(expenseRequest.accountIds);
        List<String> users = new List<String>(expenseRequest.userIds);
        List<String> contacts = new List<String>(expenseRequest.contactIds);  
        List<String> idClauseBatch = VeevaEmBusRuleUtils.composeIdCriteria(accounts, users, contacts);
        if (idClauseBatch.size() * getPerAttendeeRulesCount() > VeevaEmBusRuleUtils.RULE_QUERY_LIMIT) {
            throw new VeevaEmBusRuleModel.BadDataException('Running more than ' + VeevaEmBusRuleUtils.RULE_QUERY_LIMIT + ' queries is not supported');      
        } 
        idClauseBatch = replaceFieldInIdClauseBatch(idClauseBatch);
        boolean hasHardWarningViolation = false;
        boolean isEventAction = String.isNotEmpty(expenseRequest.eventAction);
        for (VeevaEmBusRuleModel.BusinessRule rule : rules){
            //if it comes from event action, and had hard warning previously, doesn't need to run soft rule
            if (isEventAction && SOFT_WARNING.equals(rule.warningType) && hasHardWarningViolation) {
                break;
            }
            ExpenseViolation violation = null;
            //per event expense rule
            if(isPerEventRule(rule)){  
                violation = getPerEventViolation(rule, expenseData);
            }
            //per event attendance rule
            else if(isPerEventAttendeeRule(rule)){
                violation = getPerEventAttendeeViolation(rule, expenseData);
            }
            //expense threshold rule
            else if(isExpensesThresholdRule(rule)){
                violation = getExpensesThresholdViolation(rule, expenseData);
            }
            //speaker expense rule
            else if(isSpeakerExpenseRule(rule)){
                violation = getSpeakerExpenseViolation(rule, expenseData);
            }
            if(violation != null){
                expenseResult.ruleViolations.add(violation);
            }
            //per attendee expense rules
            if(isAttendeeCapRule(rule)){
                List<ExpenseViolation> attendeeCapViolations = getAttendeeCapViolations(rule, idClauseBatch, expenseResult.ruleAttendees);
                if(attendeeCapViolations.size() > 0){
                    expenseResult.ruleViolations.addAll(attendeeCapViolations);
                }
            }
            if ((HARD_WARNING.equals(rule.warningType)) && (expenseResult.ruleViolations.size() > 0)) {
                hasHardWarningViolation = true;
            }
        }
        expenseResult = filterOverrideRule(expenseData);
        if(isEventAction){
           createEventHistory(); 
        }
        return expenseResult;
    }
    
    private void dealWithQueryResult(List<sObject> queryRows, Set<String> accountNameIds, Map<String, List<sObject>> queryMap, Map<String, RuleAttendee> ruleAttendees){
        for(sObject queryRow : queryRows){
            String accountId = (String)queryRow.get('Account_vod__c');
            String userId = (String)queryRow.get('User_vod__c');
            String contactId = (String)queryRow.get('Contact_vod__c');
            if (String.isNotBlank(accountId)) {
                accountNameIds.add(accountId);
            }  
            String attendeeId = VeevaEmBusRuleUtils.getAttendeeId(accountId, userId, contactId);
            if(queryMap.get(attendeeId) == null){
                List<sObject> queryObject = new List<sObject>();
                queryObject.add(queryRow);
                queryMap.put(attendeeId, queryObject);
            }else{    
                queryMap.get(attendeeId).add(queryRow);
            }  
            if (!ruleAttendees.containsKey(attendeeId)) {
                RuleAttendee attendee = new RuleAttendee(accountId, userId, contactId);
                attendee.attendeeName = (String)queryRow.get('Attendee_Name_vod__c');
                attendee.attendeeFirstName = (String)queryRow.get('First_Name_vod__c'); 
                attendee.attendeeLastName = (String)queryRow.get('Last_Name_vod__c');
                ruleAttendees.put(attendeeId, attendee);
            }
        }
    }
 
    private String currentEventQuery(VeevaEmBusRuleModel.BusinessRule rule, String batch){
        //fetch the data from current event
        String query = getQuerySelect() + ' FROM Expense_Attribution_vod__c WHERE '; 
        query += getAttendeeAndExpenseTypeQuery(rule, batch);
        if(String.isNotEmpty(expenseRequest.expenseHeaderId) && expenseRequest.attributionIds != null && !expenseRequest.attributionIds.isEmpty()){ 
            query += ' AND Expense_Line_vod__r.Expense_Header_vod__c != \'' + expenseRequest.expenseHeaderId + '\'';
              
        }
        query += ' AND Expense_Line_vod__r.Event_vod__c = \'' + expenseRequest.eventId + '\''; 
        query += getQueryGroupBy();
        return query;
    }
    
    private List<ExpenseViolation> getAttendeeCapViolations(VeevaEmBusRuleModel.BusinessRule rule, List<String> idClauseBatch, Map<String, RuleAttendee> ruleAttendees){
        List<ExpenseViolation> ruleViolations = new List<ExpenseViolation>();
        String ruleQuery = composeQuery(rule);
        Set<String> accountNameIds = new Set<String>();
        Map<String, List<sObject>> queryMap = new Map<String, List<sObject>>();
        for (String batch : idClauseBatch) {
            if (String.isBlank(batch)) {
                continue;
            }   
            //all matched data according to rule definition, exclude current Event
            String query = composeBatchQuery(rule, ruleQuery, batch);
            List<sObject> queryRows = Database.query(query);
            //current Event expense data
            String currentEventQuery = currentEventQuery(rule, batch);
            List<sObject> currentExpenseRows = Database.query(currentEventQuery);
            if(currentExpenseRows.size() > 0){
                queryRows.addAll(currentExpenseRows);
            }
            dealWithQueryResult(queryRows, accountNameIds, queryMap, ruleAttendees);
        }
        Map<String, List<ExpenseAttributionRequest>> preSaveDataMap = expenseRequest.preSaveAttributionMap;
        // preSave case
        if(preSaveDataMap != null && preSaveDataMap.size() >0){
            List<ExpenseViolation> preSaveViolations = getViolationsFromPreSave(rule, ruleAttendees, preSaveDataMap, queryMap, accountNameIds);   
            if(VeevaEmBusRuleUtils.isNotEmpty(preSaveViolations)){
                ruleViolations.addAll(preSaveViolations);    
            }  
        }else{
            //all data come from db
            List<ExpenseViolation> dbViolations = getViolationsFromDB(rule, ruleAttendees, queryMap);
            if(VeevaEmBusRuleUtils.isNotEmpty(dbViolations)){     
                ruleViolations.addAll(dbViolations); 
            }   
        }
        convertAttendeeName(accountNameIds, ruleAttendees);
        return ruleViolations;
    }
    
    private List<ExpenseViolation> getViolationsFromDB(VeevaEmBusRuleModel.BusinessRule rule, Map<String, RuleAttendee> ruleAttendees, Map<String, List<sObject>> queryMap){
        List<ExpenseViolation> ruleViolations = new List<ExpenseViolation>();
        if(!queryMap.isEmpty()){
            for (String attendeeId : queryMap.keySet()){
                List<sObject> queryObjects = queryMap.get(attendeeId);
                Decimal matchedAmount = 0;
                String eventAttendeeId;           
                for (sObject queryRow : queryObjects){              
                    if(expenseRequest.attendeeKeyMap != null){         
                        eventAttendeeId = expenseRequest.attendeeKeyMap.get(attendeeId);        
                    }     
                    if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                        matchedAmount += MultiCurrencyUtil.convertCurrency((String)queryRow.get('CurrencyIsoCode'), rule.currencyIsoCode, (Decimal)queryRow.get('Total'));
                    }else{
                        matchedAmount += (Decimal)queryRow.get('Total');         
                    }      
                }
                boolean matchedRule = isAccountTypeMatch(rule, attendeeId) && matchSpendLimit(rule, matchedAmount);
                if(matchedRule){    
                    ExpenseViolation violation = getViolation(rule.id, ruleAttendees, attendeeId, eventAttendeeId, matchedAmount);    
                    ruleViolations.add(violation);
                }    
            }    
        } 
        return ruleViolations;
    }
    
    private boolean isAccountTypeMatch(VeevaEmBusRuleModel.BusinessRule rule, String attendeeId){
        boolean matchedRule = false;
        RuleAttendee attendee = getRuleAttendee(attendeeId);
        if(attendee != null){
            matchedRule = matchRuleValue(attendee.attendeeAccountType, rule.attendeeAccountType);
        } 
        return matchedRule;
    }
    
    private List<ExpenseViolation> getViolationsFromPreSave(VeevaEmBusRuleModel.BusinessRule rule, Map<String, RuleAttendee> ruleAttendees
                                                            , Map<String, List<ExpenseAttributionRequest>> preSaveDataMap
                                                            , Map<String, List<sObject>> queryMap, Set<String> accountNameIds){
        List<ExpenseViolation> ruleViolations = new List<ExpenseViolation>();
        for (String attendeeId : preSaveDataMap.keySet()){
            if (String.isNotBlank(attendeeId)) {
                accountNameIds.add(attendeeId);    
            }           
            List<sObject> queryObjects = queryMap.get(attendeeId);
            Decimal matchedAmount = 0;
            //from db excluded preSave data
            if(VeevaEmBusRuleUtils.isNotEmpty(queryObjects)){                   
                for (sObject queryRow : queryObjects){            
                    if(MultiCurrencyUtil.isMultiCurrencyOrg()){             
                        matchedAmount += MultiCurrencyUtil.convertCurrency((String)queryRow.get('CurrencyIsoCode'), rule.currencyIsoCode, (Decimal)queryRow.get('Total'));      
                    }else{      
                        matchedAmount += (Decimal)queryRow.get('Total');       
                    }      
                }       
            }          
            List<ExpenseAttributionRequest> preSaveObjects = preSaveDataMap.get(attendeeId);
            //from preSave data
            String eventAttendeeId;
            for (ExpenseAttributionRequest preSaveData : preSaveObjects){
                eventAttendeeId = preSaveData.attendee;
                Map<String, Set<String>> expenseTypeMap = expenseRequest.expenseTypeMap;
                boolean isExpenseTypeMatch = false;
                if(String.isEmpty(rule.expenseType)
                   || (rule.expenseType.equals(preSaveData.expenseType)
                       || expenseTypeMap.get(rule.expenseType).contains(preSaveData.expenseType))){
                           isExpenseTypeMatch = true;                    
                }   
                if(isExpenseTypeMatch){
                    if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                        matchedAmount += MultiCurrencyUtil.convertCurrency(preSaveData.currencyIsoCode, rule.currencyIsoCode, preSaveData.actual);       
                    }else{        
                        matchedAmount += preSaveData.actual;      
                    }      
                }       
            }
            boolean matchedRule = isAccountTypeMatch(rule, attendeeId) &&  matchSpendLimit(rule, matchedAmount);
            if(matchedRule){
                ExpenseViolation violation = getViolation(rule.id, ruleAttendees, attendeeId, eventAttendeeId, matchedAmount);
                ruleViolations.add(violation);
            }      
        }
        return ruleViolations;  
    }
    
    private void createEventHistory(){
        List<ExpenseViolation> ruleViolations = expenseResult.ruleViolations;
        if(VeevaEmBusRuleUtils.isEmpty(ruleViolations)){
            return;
        }
        RecordTypeInfo recordType = Schema.SObjectType.EM_Event_History_vod__c.getRecordTypeInfosByDeveloperName().get('EM_Business_Rule_History_vod');
        if (recordType == null) {                 
            return;             
        }
        String recordTypeId = recordType.getRecordTypeId();
        List<EM_Event_History_vod__c> histories = new List<EM_Event_History_vod__c>();           
        for(ExpenseViolation violation : ruleViolations) {    
            VeevaEmBusRuleModel.BusinessRule rule = ruleMap.get(violation.ruleId);
            String configId = rule.getConfigurationId(expenseRequest.eventType, expenseRequest.country);
            EM_Event_History_vod__c history = createEventHistoryObject(recordTypeId, expenseRequest.eventId, configId, expenseRequest.eventAction, expenseRequest.platform, rule);
            history.Expense_Type_vod__c = rule.expenseType;                     
            RuleAttendee attendee = getRuleAttendee(violation.attendeeId);                
            if(attendee != null){                    
                history.EM_Attendee_Account_vod__c = attendee.accountId;
                history.EM_Attendee_User_vod__c = attendee.userId;
                history.EM_Attendee_Contact_vod__c = attendee.contactId;                
            }                
            List<String> violatedIds = violation.violatedIds;               
            if(VeevaEmBusRuleUtils.isNotEmpty(violatedIds)){                    
                String violatedId = String.join(violatedIds, ',');                    
                history.Record_Violated_ID_vod__c = violatedId;                
            }                
            history.Record_Violated_Name_vod__c = violation.violatedName;
            histories.add(history);
        } 
        expenseResult.eventHistoryBatchId = executeEventHistoryBatch(histories);
    }
    
    private RuleAttendee getRuleAttendee(String attendeeId){
        RuleAttendee attendee = null;
        if(expenseResult.ruleAttendees != null && !expenseResult.ruleAttendees.isEmpty()){
            attendee = expenseResult.ruleAttendees.get(attendeeId);
        }
        return attendee;
    }
    
    private boolean isViolationNotOverridden(ExpenseViolation violation, EventExpenseData expenseData, Map<String, List<VeevaEmBusRuleModel.BusinessRule>> groupedRuleMap){               
        Map<String, RuleAttendee> ruleAttendees = expenseResult.ruleAttendees;               
        RuleAttendee attendee = ruleAttendees.get(violation.attendeeId); 
        List<ExpenseViolation> ruleViolations = expenseResult.ruleViolations;
        String currencySign;            
        if (!MultiCurrencyUtil.isMultiCurrencyOrg()) { 
            currencySign = ConnectApi.Organization.getSettings().UserSettings.currencySymbol;            
        }
        VeevaEmBusRuleModel.BusinessRule rule = ruleMap.get(violation.ruleId);
        boolean isOverridden = false;
        if (isPerEventAttendeeRule(rule)) {
            //for per event attendee rule, need to validate all attendees 
            List<String> perAttendeeIds = violation.perAttendeeIds ;
            //come from estimate category
            if (VeevaEmBusRuleUtils.isEmpty(perAttendeeIds)) {
                isOverridden = isOverriddenWithAttendee(expenseData, null, violation, groupedRuleMap);
            } else {
                for (Integer i=0; i<perAttendeeIds.size(); i++) {
                    isOverridden = false;
                    String attendeeId = perAttendeeIds.get(i);   
                    attendee = ruleAttendees.get(attendeeId);
                    isOverridden = isOverriddenWithAttendee(expenseData, attendee, violation, groupedRuleMap);
                    // remove the attendee from rule as overridden by other rules
                    if (isOverridden) {
                        perAttendeeIds.remove(i);
                        i--;
                    }
                }
                // reset isOverridden flag by violated attendee id size
                if (VeevaEmBusRuleUtils.isNotEmpty(perAttendeeIds)) {
                    isOverridden = false;
                }
            }
        } else {
            isOverridden = isOverriddenWithAttendee(expenseData, attendee, violation, groupedRuleMap);
        }
        if (!isOverridden) {     
            String currencyIsoCode = rule.currencyIsoCode;           
            if (MultiCurrencyUtil.isMultiCurrencyOrg()) {           
                currencySign = currencyIsoCode != null ? currencyIsoCode : UserInfo.getDefaultCurrency();     
            }
            violation.matchedAmount = currencySign + ' ' + violation.matchedAmount; 
        } 
        return !isOverridden;
    }

    private expenseResult filterOverrideRule(EventExpenseData expenseData){
        List<ExpenseViolation> ruleViolations = expenseResult.ruleViolations;            
        List<ExpenseViolation> ruleViolationResult = new List<ExpenseViolation>();

        Map<String, List<VeevaEmBusRuleModel.BusinessRule>> groupedRuleMap = new Map<String, List<VeevaEmBusRuleModel.BusinessRule>>();
        for (VeevaEmBusRuleModel.BusinessRule eachRule : ruleMap.values()) {
            String key = eachRule.getRuleKey();
            List<VeevaEmBusRuleModel.BusinessRule> groupedRules = groupedRuleMap.get(key);
            if (groupedRules == null) {
                groupedRules = new List<VeevaEmBusRuleModel.BusinessRule>();
                groupedRuleMap.put(key, groupedRules);
            }
            groupedRules.add(eachRule);
        }
        
        for (ExpenseViolation violation : ruleViolations) {
            if (isViolationNotOverridden(violation, expenseData, groupedRuleMap)) {
                ruleViolationResult.add(violation); 
            }
        }
        expenseResult.ruleViolations = ruleViolationResult;
        return expenseResult;
    }
    
    @TestVisible private boolean isAccountTypeOverridden(VeevaEmBusRuleModel.BusinessRule rule, RuleAttendee attendee, Map<String, List<VeevaEmBusRuleModel.BusinessRule>> groupedRuleMap){
        boolean isOverridden = false;
        if (attendee != null) {
            if (String.isBlank(rule.attendeeAccountType)) {
                // Skip the rule violation if other rule match the same key and contains the attendee account type
                List<VeevaEmBusRuleModel.BusinessRule> groupedRules = groupedRuleMap.get(rule.getRuleKey());    
                for (VeevaEmBusRuleModel.BusinessRule eachRule : groupedRules) {
                    Set<String> types = eachRule.getAccountTypes();
                    if (types.contains(attendee.attendeeAccountType)) {
                        isOverridden = true;
                        break;   
                    }
                }
            }
        }
        return isOverridden;
    }
    
    @TestVisible private boolean isEventStatusOverridden(VeevaEmBusRuleModel.BusinessRule rule, String eventStatus, Map<String, List<VeevaEmBusRuleModel.BusinessRule>> groupedRuleMap){
        boolean isOverridden = false;
        if (String.isBlank(rule.eventStatus)) {
            // Skip the rule violation if other rule match the same key and contains the event status
            List<VeevaEmBusRuleModel.BusinessRule> groupedRules = groupedRuleMap.get(rule.getRuleKey());             
            for (VeevaEmBusRuleModel.BusinessRule eachRule : groupedRules) {
                Set<String> status = eachRule.getEventStatus();
                if (status.contains(eventStatus)) {
                    isOverridden = true;
                    break;
                }
            }
        }
        return isOverridden;
    }
    
    private boolean matchValue(String value, Set<String> ruleValues) {
        if (String.isBlank(value)) {
            return ruleValues.isEmpty();
        } else {
            return ruleValues.isEmpty() || ruleValues.contains(value);
        }
    }

    /*
      Check rule override with the logic:
        - If attendee account type and event status attributes are blank, it will be run by default.
        - Rules with an exact match on one of the two attributes take precedence over default.
        - Rules with exact matches on both attributes takes precedence over rules that match only one.
    */
    @TestVisible private boolean isAccountTypeAndEventStatusOverridden(VeevaEmBusRuleModel.BusinessRule rule, RuleAttendee attendee, String eventStatus, Map<String, List<VeevaEmBusRuleModel.BusinessRule>> groupedRuleMap){
        List<VeevaEmBusRuleModel.BusinessRule> groupedRules = groupedRuleMap.get(rule.getRuleKey());
        String attendeeAccountType = attendee.attendeeAccountType;
        List<VeevaEmBusRuleModel.BusinessRule> matchedRules = new List<VeevaEmBusRuleModel.BusinessRule>();
        // overridden by other rule
        boolean isOverridden = false;
        Set<String> ruleAcctTypes = rule.getAccountTypes();
        Set<String> ruleEventStatus = rule.getEventStatus();
        boolean blankRuleAccountType = ruleAcctTypes.isEmpty();
        boolean blankRuleEventStatus = ruleEventStatus.isEmpty();
        // attendee account type and event status both have values in other rules
        boolean hasAcctTypeAndEventStatusValues = false;
        for (VeevaEmBusRuleModel.BusinessRule eachRule : groupedRules) {
            Set<String> types = eachRule.getAccountTypes();
            Set<String> status = eachRule.getEventStatus();
            // check overridden when both attendee account type and event status values match
            if (rule.id != eachRule.id && matchValue(attendeeAccountType, types) && matchValue(eventStatus, status)) {
                boolean eachRuleAccountTypeNotBlank = !types.isEmpty();
                boolean eachRuleEventStatusNotBlank = !status.isEmpty();
                if (!hasAcctTypeAndEventStatusValues) {
                    hasAcctTypeAndEventStatusValues = eachRuleAccountTypeNotBlank && eachRuleEventStatusNotBlank;
                }
                if (blankRuleAccountType && blankRuleEventStatus) {
                    isOverridden = eachRuleAccountTypeNotBlank || eachRuleEventStatusNotBlank;
                } else if (blankRuleAccountType) {
                    isOverridden = hasAcctTypeAndEventStatusValues;                  
                } else if (blankRuleEventStatus) {
                    isOverridden = hasAcctTypeAndEventStatusValues;                     
                } else {
                    break;
                }
                if (isOverridden) {
                    break;
                }
            }
        }
        return isOverridden;
    }

    private boolean isOverriddenWithAttendee(EventExpenseData expenseData, RuleAttendee attendee, ExpenseViolation violation, Map<String, List<VeevaEmBusRuleModel.BusinessRule>> groupedRuleMap) {
        VeevaEmBusRuleModel.BusinessRule rule = ruleMap.get(violation.ruleId);
        boolean isOverridden = false;
        if (isPerEventAttendeeRule(rule) && attendee != null && expenseData != null) {
            isOverridden = isAccountTypeAndEventStatusOverridden(rule, attendee, expenseData.status, groupedRuleMap);
        } else {
            if (isAttendeeCapRule(rule)) {
                isOverridden = isAccountTypeOverridden(rule, attendee, groupedRuleMap);
            } else if (expenseData != null && (isPerEventAttendeeRule(rule) && attendee == null || isPerEventRule(rule) || isSpeakerExpenseRule(rule))) {
                isOverridden = isEventStatusOverridden(rule, expenseData.status, groupedRuleMap);
            }
        }
        return isOverridden;
    }
    
    private ExpenseViolation getViolation(String ruleId, Map<String, RuleAttendee> ruleAttendees, String attendeeId, String eventAttendeeId, Decimal matchedAmount){  
        ExpenseViolation violation = new ExpenseViolation();                                
        violation.matchedAmount = matchedAmount.format();
        violation.ruleId = ruleId;
        violation.attendeeId = attendeeId;
        violation.violatedIds = new List<String>{eventAttendeeId};
        if(ruleAttendees != null && !ruleAttendees.isEmpty()){
            RuleAttendee attendee = ruleAttendees.get(attendeeId);
            if(attendee != null){
                violation.violatedName = attendee.attendeeName;
            }
        }
        return violation;
    }
    
    private boolean matchSpendLimit(VeevaEmBusRuleModel.BusinessRule rule, Decimal matchedAmount){
        boolean matchRule = false;
        double minimumSpend = rule.minimumSpendLimit;
        double maximumSpend = rule.maximumSpendLimit;
        if(minimumSpend != null){
            matchRule = matchedAmount < minimumSpend;
        }
        if(!matchRule && maximumSpend != null){         
            matchRule = matchedAmount > maximumSpend;
        }
        return matchRule;
    }
    
    private void convertAttendeeName(Set<String> accountNameIds, Map<String, RuleAttendee> ruleAttendees) {
        if (VeevaSettings.isEnableAccountParentDisplay() && !accountNameIds.isEmpty() && !ruleAttendees.isEmpty()) {
            List<Account> accounts = [SELECT Id, Formatted_Name_vod__c, Primary_Parent_vod__r.Formatted_Name_vod__c FROM Account WHERE Id IN :accountNameIds];
            for (Account account : accounts) {
                String id = account.Id;
                if (ruleAttendees.containsKey(id)) {
                    String name = account.Formatted_Name_vod__c;
                    if (account.Primary_Parent_vod__r != null) {
                        name += ' @ ' + account.Primary_Parent_vod__r.Formatted_Name_vod__c;
                    }
                    RuleAttendee ruleAttendee = ruleAttendees.get(id);
                    ruleAttendee.attendeeName = name;
                }
            }
        }
    }
    
    private ExpenseViolation getMatchedAmountByEstimate(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        double matchedAmount = 0;
        String expenseType = rule.expenseType;
        List<ExpenseDataObject> expenseEstimates = expenseData.expenseEstimates;           
        expenseEstimates = getValidRows(rule, expenseEstimates);        
        double totalAmount = 0;
        boolean matchRule = false;
        List<String> violatedIds = new List<String>();
        if(VeevaEmBusRuleUtils.isNotEmpty(expenseEstimates)){
            for (ExpenseDataObject row : expenseEstimates) {
                ExpenseEstimate estimateRow = (ExpenseEstimate)row;
                violatedIds.add(estimateRow.id);
                totalAmount += toRuleAmount(estimateRow.currencyIsoCode, rule.currencyIsoCode, estimateRow.estimate);        
            }        
            double estimateAttendance = expenseData.estimatedAttendance;
            if(estimateAttendance != null){
                matchedAmount = totalAmount / estimateAttendance;
                matchRule = matchSpendLimit(rule, matchedAmount);
            }
        }        
        ExpenseViolation violation = null;
        if(matchRule){
            violation = getViolation(rule, null, expenseRequest.expenseTypeNameMap, matchedAmount, violatedIds);
        }  
        return violation;
    }
    
    private ExpenseViolation getViolation(VeevaEmBusRuleModel.BusinessRule rule, String attendeeId, Map<String, String> expenseTypeNameMap, double matchedAmount, List<String> violatedIds){
        ExpenseViolation violation = new ExpenseViolation();
        violation.matchedAmount = matchedAmount.format();
        violation.ruleId = rule.id;        
        violation.violatedIds = violatedIds;
        violation.attendeeId = attendeeId;
        if(String.isNotEmpty(rule.expenseType) && expenseTypeNameMap != null && !expenseTypeNameMap.isEmpty()){                       
            violation.violatedName = expenseTypeNameMap.get(rule.expenseType);     
        }
        return violation;
    }
    
    private List<String> getCurrentExpenseIncurred(List<ExpenseDataObject> expenseLines, String incurredType){
        List<String> expenseIncurred = new List<String>();
        if(VeevaEmBusRuleUtils.isEmpty(expenseLines) || String.isEmpty(expenseRequest.expenseHeaderId)){
            return expenseIncurred;
        }
        for (ExpenseDataObject lineDataObject : expenseLines) {
            ExpenseLine lineRow = (ExpenseLine)lineDataObject;
            if(expenseRequest.expenseHeaderId.equals(lineRow.expenseHeader)){
                List<ExpenseAttribution> expenseAttribution = lineRow.expenseAttribution;
                if(VeevaEmBusRuleUtils.isNotEmpty(expenseAttribution)){
                    for (ExpenseAttribution attribution : expenseAttribution) {
                        if(ATTENDEE_TYPE.equals(incurredType)){
                            expenseIncurred.add(attribution.attendee);  
                        }else if(SPEAKER_TYPE.equals(incurredType)){
                            expenseIncurred.add(attribution.speaker);
                        }
                    }                    
                }             
            }            
        }
        return expenseIncurred;
    }
    
    private List<ExpenseAttribution> getValidAttributions(List<ExpenseDataObject> expenseLines){
        List<ExpenseAttribution> validData = new List<ExpenseAttribution>();
        if(VeevaEmBusRuleUtils.isEmpty(expenseLines)){
            return validData;
        }
        for (ExpenseDataObject lineDataObject : expenseLines) {
            ExpenseLine lineRow = (ExpenseLine)lineDataObject;
            List<ExpenseAttribution> expenseAttribution = lineRow.expenseAttribution;
            if(VeevaEmBusRuleUtils.isNotEmpty(expenseAttribution)){
               validData.addAll(expenseAttribution); 
            }
        }
        return validData;
    }
    
    private ExpenseViolation getMatchedAmountByActual(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        List<ExpenseDataObject> expenseLines = expenseData.expenseLines;
        expenseLines = getValidRows(rule, expenseLines);
        if(VeevaEmBusRuleUtils.isEmpty(expenseLines)){
            return null;
        }
        Set<String> violatedIds = new Set<String>();
        Map<String, List<ExpenseAttribution>> attributionPerHead = new Map<String, List<ExpenseAttribution>>();
        List<ExpenseAttribution> expenseAttributions = getValidAttributions(expenseLines);
        List<String> expenseAttendees = getCurrentExpenseIncurred(expenseLines, ATTENDEE_TYPE);
        List<EventAttendee> validAttendees = getValidAttendees(rule, expenseData.attendees, expenseAttendees);
        if(VeevaEmBusRuleUtils.isNotEmpty(expenseAttributions)){
            for (ExpenseAttribution attributionRow : expenseAttributions) {
                if(isValidAttendee(validAttendees, attributionRow.attendee)){
                    violatedIds.add(attributionRow.expenseLine);
                    if(attributionPerHead.get(attributionRow.attendee) == null){
                        attributionPerHead.put(attributionRow.attendee, new List<ExpenseAttribution>{attributionRow});
                    }else{ 
                        attributionPerHead.get(attributionRow.attendee).add(attributionRow);
                    } 
                } 
            } 
        }
        
        return getViolationPerHeadByActual(rule, attributionPerHead, new List<String>(violatedIds));
    }
    
    private ExpenseViolation getViolationPerHeadByActual(VeevaEmBusRuleModel.BusinessRule rule, Map<String, List<ExpenseAttribution>> attributionPerHead, List<String> violatedIds){
        ExpenseViolation violation = null;
        List<String> allMatchedAttendeeIds = new List<String>();
        for(String attendee : attributionPerHead.keySet()){
            double matchedAmountPerHead = 0;
            List<ExpenseAttribution> perHeadAttribution = attributionPerHead.get(attendee);
            for (ExpenseAttribution attributionRow : perHeadAttribution) {   
                matchedAmountPerHead += toRuleAmount(attributionRow.currencyIsoCode, rule.currencyIsoCode, attributionRow.actual);
            } 
            boolean matchRule = matchSpendLimit(rule, matchedAmountPerHead);
            if(matchRule){
                String attendeeId;
                if(expenseRequest.eventAttendeeKeys != null && expenseRequest.eventAttendeeKeys.size() > 0){
                    attendeeId = expenseRequest.eventAttendeeKeys.get(attendee);
                }
                allMatchedAttendeeIds.add(attendeeId);
                //per event attendee rule just need create one violation
                if(violation == null){
                    violation = getViolation(rule, null, expenseRequest.expenseTypeNameMap, matchedAmountPerHead, violatedIds);
                }
            }
        }
        if(violation != null){
            violation.perAttendeeIds = allMatchedAttendeeIds;  
        }
        return violation;
    }
    
    private ExpenseViolation getPerEventAttendeeViolation(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        boolean matchRule = verifyEventStatus(rule, expenseData);
        double matchedAmount = 0;
        ExpenseViolation violation = null;
        if(matchRule){
            if(ESTIMATE.equals(rule.expenseCategory)){
                violation = getMatchedAmountByEstimate(rule, expenseData);
            }
            if(ACTUAL.equals(rule.expenseCategory)){
                violation = getMatchedAmountByActual(rule, expenseData);
            }
        }
        return violation;
    }
    
    private List<EventAttendee> getValidAttendees(VeevaEmBusRuleModel.BusinessRule rule, List<EventAttendee> attendees, List<String> expenseAttendees){
        String accountType = rule.attendeeAccountType;
        List<EventAttendee> validAttendees = new List<EventAttendee>();
        //If Attendee Account Type is not defined in the rule, then the rule applies to all EM Attendees, regardless of value in <Attendee_Account_Type_vod> field
        if(VeevaEmBusRuleUtils.isNotEmpty(attendees)){
            //the EM Attendee records associated with the event where <Attendee_Account_Type_vod>  of the EM Attendee record matches the <Attendee_Account_Type_vod> defined in the Rule
            for (EventAttendee row : attendees) {
                boolean isValid = String.isEmpty(expenseRequest.expenseHeaderId) || expenseAttendees.contains(row.id);
                if(isValid && matchRuleValue(row.accountType, accountType)){
                    validAttendees.add(row);
                }
            }
        }
        return validAttendees;
    }
    
    private ExpenseViolation getSpeakerExpenseViolationByEstimate(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        List<ExpenseDataObject> expenseEstimates = expenseData.expenseEstimates; 
        double totalAmount = 0;
        double matchedAmount = 0;
        ExpenseViolation violation;
        List<String> violatedIds = new List<String>();
        expenseEstimates = getValidRows(rule, expenseEstimates);
        if(VeevaEmBusRuleUtils.isNotEmpty(expenseEstimates)){
            for (ExpenseDataObject row : expenseEstimates) {
                violatedIds.add(row.id);
                ExpenseEstimate estimateRow = (ExpenseEstimate)row;
                totalAmount += toRuleAmount(row.currencyIsoCode, rule.currencyIsoCode, estimateRow.estimate);                   
            }
            if(VeevaEmBusRuleUtils.isNotEmpty(expenseData.speakers)){
                Integer speakerCount = expenseData.speakers.size();
                matchedAmount = totalAmount / speakerCount;
                boolean matchRule = matchSpendLimit(rule, matchedAmount);
                if(matchRule){
                    violation = getViolation(rule, null, expenseRequest.expenseTypeNameMap, matchedAmount, violatedIds);
                }
            }
        }
        return violation;
    }
    
    private ExpenseViolation getViolationPerSpeakerByActual(VeevaEmBusRuleModel.BusinessRule rule, Map<String, List<ExpenseAttribution>> attributionPerHead, List<String> violatedIds){
        ExpenseViolation violation = null;
        for(String speaker : attributionPerHead.keySet()){
            double matchedAmountPerHead = 0;
            List<ExpenseAttribution> perHeadAttribution = attributionPerHead.get(speaker);
            for (ExpenseAttribution attributionRow : perHeadAttribution) {
                matchedAmountPerHead += toRuleAmount(attributionRow.currencyIsoCode, rule.currencyIsoCode, attributionRow.actual);
            }
            boolean matchRule = matchSpendLimit(rule, matchedAmountPerHead);
            if(matchRule){
                violation = getViolation(rule, null, expenseRequest.expenseTypeNameMap, matchedAmountPerHead, violatedIds);
            }
        }
        return violation;
    }
    
    private ExpenseViolation getSpeakerExpenseViolationByActual(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        List<ExpenseDataObject> expenseLines = expenseData.expenseLines;
        expenseLines = getValidRows(rule, expenseLines);
        if(VeevaEmBusRuleUtils.isEmpty(expenseLines)){
            return null;
        }
        Set<String> violatedIds = new Set<String>();
        Map<String, List<ExpenseAttribution>> attributionPerHead = new Map<String, List<ExpenseAttribution>>();
        List<ExpenseAttribution> expenseAttributions = getValidAttributions(expenseLines);       
        if(VeevaEmBusRuleUtils.isNotEmpty(expenseAttributions)){
            List<String> expenseSpeakers = getCurrentExpenseIncurred(expenseLines, SPEAKER_TYPE);
            for (ExpenseAttribution attributionRow : expenseAttributions) {
                if(attributionRow.speaker == null){
                    continue;
                }
                if(String.isEmpty(expenseRequest.expenseHeaderId) || expenseSpeakers.contains(attributionRow.speaker)){  
                    violatedIds.add(attributionRow.expenseLine);
                    if(attributionPerHead.get(attributionRow.speaker) == null){                                           
                        attributionPerHead.put(attributionRow.speaker, new List<ExpenseAttribution>{attributionRow});               
                    }else{ 
                        attributionPerHead.get(attributionRow.speaker).add(attributionRow);
                    }
                }                  
            } 
        }
        return getViolationPerSpeakerByActual(rule, attributionPerHead, new List<String>(violatedIds));
    }
    
    private ExpenseViolation getSpeakerExpenseViolation(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        boolean matchRule = verifyEventStatus(rule, expenseData);
        ExpenseViolation violation;
        if(matchRule){
            if(ESTIMATE.equals(rule.expenseCategory)){
                violation = getSpeakerExpenseViolationByEstimate(rule, expenseData);
            }
            if(ACTUAL.equals(rule.expenseCategory)){
                violation = getSpeakerExpenseViolationByActual(rule, expenseData);
            }
        }
        return violation;
    }
    
    private ExpenseViolation getExpensesThresholdViolation(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        double matchedAmount = 0;
        double estimateAmount = 0;
        List<ExpenseDataObject> expenseEstimates = expenseData.expenseEstimates;
        expenseEstimates = getValidRows(rule, expenseEstimates);
        List<ExpenseDataObject> expenseLines = expenseData.expenseLines;
        expenseLines = getValidRows(rule, expenseLines);
        boolean matchRule = false;
        List<String> violatedIds = new List<String>();
        if(VeevaEmBusRuleUtils.isNotEmpty(expenseEstimates) && VeevaEmBusRuleUtils.isNotEmpty(expenseLines)){
            for (ExpenseDataObject row : expenseEstimates) {
                ExpenseEstimate estimateRow = (ExpenseEstimate)row;
                estimateAmount += toRuleAmount(estimateRow.currencyIsoCode, rule.currencyIsoCode, estimateRow.estimate);
            }
            for (ExpenseDataObject row : expenseLines) { 
                ExpenseLine lineRow = (ExpenseLine)row;
                violatedIds.add(lineRow.id);
                matchedAmount += toRuleAmount(lineRow.currencyIsoCode, rule.currencyIsoCode, lineRow.actual);
            }
            if(estimateAmount != 0){
                double percent = ((matchedAmount - estimateAmount) / estimateAmount) * 100;
                matchRule = percent > rule.percentThreshold;
            }
        }
        ExpenseViolation violation = null;
        if(matchRule){
            violation = getViolation(rule, null, expenseRequest.expenseTypeNameMap, matchedAmount, violatedIds);
        }
        return violation;
    }
    
    private ExpenseViolation getPerEventViolation(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        boolean matchRule = verifyEventStatus(rule, expenseData);
        double matchedAmount = 0;
        List<String> violatedIds = new List<String>();
        if(matchRule){
            if(ESTIMATE.equals(rule.expenseCategory)){
                List<ExpenseDataObject> expenseEstimates = expenseData.expenseEstimates;
                expenseEstimates = getValidRows(rule, expenseEstimates);
                if(VeevaEmBusRuleUtils.isNotEmpty(expenseEstimates)){
                    for (ExpenseDataObject row : expenseEstimates) {
                        violatedIds.add(row.id);
                        ExpenseEstimate estimateRow = (ExpenseEstimate)row;
                        matchedAmount += toRuleAmount(row.currencyIsoCode, rule.currencyIsoCode, estimateRow.estimate);
                    }
                    matchRule = matchSpendLimit(rule, matchedAmount);
                }else{
                    matchRule = false;
                }
                
            }
            if(ACTUAL.equals(rule.expenseCategory)){
                List<ExpenseDataObject> expenseLines = expenseData.expenseLines;
                expenseLines = getValidRows(rule, expenseLines);
                if(VeevaEmBusRuleUtils.isNotEmpty(expenseLines)){
                    for (ExpenseDataObject row : expenseLines) {
                        violatedIds.add(row.id);
                        matchedAmount += toRuleAmount(row.currencyIsoCode, rule.currencyIsoCode, row.actual);
                    } 
                    matchRule = matchSpendLimit(rule, matchedAmount);
                }else{
                    matchRule = false;
                }
            }
        }
        ExpenseViolation violation = null;
        if(matchRule){
            violation = getViolation(rule, null, expenseRequest.expenseTypeNameMap, matchedAmount, violatedIds);
        }
        return violation;
    }
    
    private boolean isValidAttendee(List<EventAttendee> attendeeRows, String attendeeId){
        boolean isValid = false;
        for (EventAttendee row : attendeeRows) {
            if(row.id.equals(attendeeId)){
                isValid = true;
                break;
            }
        }
        return isValid;
    }
    
    private boolean isRuleParentExpenseType(String rowExpenseType, String ruleExpenseType, Map<String, String> parentExpenseTypeMap) {
        if (parentExpenseTypeMap == null || rowExpenseType == null) {
            return false;
        }
        return rowExpenseType.equals(parentExpenseTypeMap.get(ruleExpenseType));
    }

    private List<ExpenseDataObject> getValidRows(VeevaEmBusRuleModel.BusinessRule rule, List<ExpenseDataObject> rows){
        String ruleExpenseType = rule.expenseType;
        List<ExpenseDataObject> validRows = new List<ExpenseDataObject>();
        //If Expense Type is not defined in the rule, then the rule applies to all rows regardless of <Expense_Type_vod> value
        if(ruleExpenseType != null){
            if(VeevaEmBusRuleUtils.isNotEmpty(rows)){
                boolean isEstimateData = rows.get(0) instanceof ExpenseEstimate;
                for (ExpenseDataObject row : rows) {
                    Map<String, Set<String>> expenseTypeMap = expenseRequest.expenseTypeMap;
                    String rowExpenseType = row.expenseType;
                    if (ruleExpenseType.equals(rowExpenseType)
                        || (isExpensesThresholdRule(rule) && isEstimateData 
                            && isRuleParentExpenseType(rowExpenseType, ruleExpenseType, expenseRequest.parentExpenseTypeMap))
                        || (expenseTypeMap.get(ruleExpenseType) != null && expenseTypeMap.get(ruleExpenseType).contains(rowExpenseType))) {
                        validRows.add(row);
                    }
                }
            }
        }else{
            validRows = rows;
        }
        return validRows;
    }
    
    private double toRuleAmount(String fromIsoCode, String toIsoCode, double amount){
        if(!MultiCurrencyUtil.isMultiCurrencyOrg()){
            return amount;
        }
        return MultiCurrencyUtil.convertCurrency(fromIsoCode, toIsoCode, amount);
    }

    private boolean hasRuleType(Set<String> ruleTypes) {
        boolean result = false;
        for (VeevaEmBusRuleModel.BusinessRule rule : rules) {
            if(ruleTypes.contains(rule.developerName)) {
                result = true;
                break;
            }
        }
        return result;
    }
     
    private boolean isPerEventRule(VeevaEmBusRuleModel.BusinessRule rule) {
        return 'EM_Per_Event_Expense_Limit_Rule_vod'.equals(rule.developerName);
    }
    
    private boolean isPerEventAttendeeRule(VeevaEmBusRuleModel.BusinessRule rule) {
        return 'EM_Per_Event_Attendee_Expense_Limit_Rule_vod'.equals(rule.developerName);
    }
    
    private boolean isExpensesThresholdRule(VeevaEmBusRuleModel.BusinessRule rule) {
        return 'EM_Actual_Versus_Estimate_Expense_Threshold_Rule_vod'.equals(rule.developerName);
    }
    
    private boolean isSpeakerExpenseRule(VeevaEmBusRuleModel.BusinessRule rule) {
        return 'EM_Per_Event_Speaker_Expense_Limit_Rule_vod'.equals(rule.developerName);
    }
     
    private boolean isAttendeeCapRule(VeevaEmBusRuleModel.BusinessRule rule) {
        return ATTENDEE_CAP_EXPENSE_TYPES.contains(rule.developerName);
    }
    
    private Integer getPerAttendeeRulesCount() {
        Integer count = 0;
        for (VeevaEmBusRuleModel.BusinessRule rule : rules) {
            if (!rule.isPerEventExpenseRule()) {
                count ++;
            }
        }
        return count;
    }
    
    private boolean verifyEventStatus(VeevaEmBusRuleModel.BusinessRule rule, EventExpenseData expenseData){
        boolean matchRule = true;
        if(rule.eventStatus != null
            && !matchRuleValue(expenseData.status, rule.eventStatus)){
            matchRule = false;
        }
        return matchRule;
    }
    
    private boolean matchRuleValue(String fieldValue, String ruleFieldValue){
        return (ruleFieldValue == null 
                ||(fieldValue == null && ruleFieldValue == null)
                ||(fieldValue != null && ruleFieldValue != null
                   && ruleFieldValue.split(SEPARATOR).contains(fieldValue)));
    }
    
    private String getQuerySelect(){
       String querySelect = 'SELECT SUM(Actual_vod__c) Total, Expense_Line_vod__r.Expense_Type_vod__c Expense_Type_vod__c,'
            +' Incurred_Expense_Attendee_vod__r.Account_vod__c Account_vod__c, Incurred_Expense_Attendee_vod__r.User_vod__c User_vod__c,'
            +' Incurred_Expense_Attendee_vod__r.Contact_vod__c Contact_vod__c,'
            +' Incurred_Expense_Attendee_vod__r.First_Name_vod__c First_Name_vod__c, Incurred_Expense_Attendee_vod__r.Last_Name_vod__c Last_Name_vod__c,'
            +' Incurred_Expense_Attendee_vod__r.Attendee_Name_vod__c Attendee_Name_vod__c';
        if(MultiCurrencyUtil.isMultiCurrencyOrg()){
            querySelect += ', CurrencyIsoCode ';
        }
        return querySelect;
    }
    
    private String getQueryGroupBy(){
        String queryGroupBy = ' GROUP BY Expense_Line_vod__r.Expense_Type_vod__c, Incurred_Expense_Attendee_vod__r.Account_vod__c,'
            +' Incurred_Expense_Attendee_vod__r.User_vod__c, Incurred_Expense_Attendee_vod__r.Contact_vod__c,'
            +' Incurred_Expense_Attendee_vod__r.First_Name_vod__c, Incurred_Expense_Attendee_vod__r.Last_Name_vod__c,'
            +' Incurred_Expense_Attendee_vod__r.Attendee_Name_vod__c';
        if(MultiCurrencyUtil.isMultiCurrencyOrg()){
            queryGroupBy += ', CurrencyIsoCode ';
        }
        return queryGroupBy;
    }
    
    private String composeQuery(VeevaEmBusRuleModel.BusinessRule rule) {
        String query = getQuerySelect();
        Datetime startTime = expenseRequest.startTime;
        Datetime minDatetime; 
        Datetime maxDatetime;
        switch on rule.dateThresholdType {
            when 'Rolling_vod' {
                Integer rollingPeriod = rule.rollingPeriod;
                minDatetime = startTime.addDays(rollingPeriod * (-1));
                maxDatetime = startTime.addDays(rollingPeriod);
            } 
            when 'Calendar_Month_vod' {
                minDatetime = datetime.newInstance(startTime.year(), startTime.month(), 1, 0, 0, 0);
                maxDatetime = datetime.newInstance(startTime.year(), startTime.month(), 1, 0, 0, 0);
                maxDatetime = maxDatetime.addMonths(1);
            }
            when 'Calendar_Year_vod' {
                minDatetime = datetime.newInstance(startTime.year(), 1, 1, 0, 0, 0);
                maxDatetime = datetime.newInstance(startTime.year() + 1, 1, 1, 0, 0, 0);
            }
        }
        String datetimeFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
        String formattedMin = minDateTime.formatGmt(datetimeFormat);
        String formattedMax = maxDatetime.formatGmt(datetimeFormat);
        query += ' FROM Expense_Attribution_vod__c WHERE Incurred_Expense_Attendee_vod__c IN (SELECT Id FROM EM_Attendee_vod__c WHERE ' + EVENT_RELATIONSHIP + '.Start_Time_vod__c >= ' + formattedMin + ' AND ' + EVENT_RELATIONSHIP + '.Start_Time_vod__c < ' + formattedMax;
        String status = composeAttendeeStatusCriteria(rule.getEventAttendeeStatus());
        if (status.length() > 0) {
            query += ' AND (' + status + ')';
        }
        String config = composeEventTypeCountryCriteria(rule.configs);
        if (config.length() > 0) {
            query += ' AND (' + config + ')';
        }
        if (!rule.getAccountTypes().isEmpty()) {
            query += ' AND Attendee_Account_Type_vod__c IN ' + VeevaEmBusRuleUtils.toCommaSeparated(new List<String>(rule.getAccountTypes()));
        }
        query += ' )';
        return query;
    }
    
    private String getAttendeeAndExpenseTypeQuery(VeevaEmBusRuleModel.BusinessRule rule, String batch){
        String query = ' (' + batch + ')';
        if (String.isNotEmpty(rule.expenseType)) {
            Map<String, Set<String>> expenseTypeMap = expenseRequest.expenseTypeMap;
            List<String> allExpenseTypes = new List<String>();
            allExpenseTypes.add(rule.expenseType);
            if(expenseTypeMap != null && expenseTypeMap.get(rule.expenseType) != null){
                allExpenseTypes.addAll(expenseTypeMap.get(rule.expenseType));
            }
            query += ' AND ( Expense_Line_vod__r.Expense_Type_vod__c  IN ' + VeevaEmBusRuleUtils.toCommaSeparated(allExpenseTypes) + ')';
        }
        return query;
    }
     
    private String composeBatchQuery(VeevaEmBusRuleModel.BusinessRule rule, String ruleQuery, String batch) {
        String query = ruleQuery;
        query += ' AND ' + getAttendeeAndExpenseTypeQuery(rule, batch);
        //exclude the data from current event
        query += ' AND ( Expense_Line_vod__r.Event_vod__c != \'' + expenseRequest.eventId + '\')';
        query += getQueryGroupBy();
        
        return query;
    }
    
    private String composeAttendeeStatusCriteria(Map<String, Set<String>> statusPairs) {
        String query = '';
        Integer i = 0;
        for (String key : statusPairs.keySet()) {
            Set<String> values = statusPairs.get(key);
            if (!values.isEmpty()) {
                if (i > 0) {
                    query += ' OR ';
                }
                query += '(' + EVENT_RELATIONSHIP + '.Status_vod__c = \'' + key + '\' AND Status_vod__c IN '
                    + VeevaEmBusRuleUtils.toCommaSeparated(new List<String>(values)) + ')';
                i++;
            }
        }
        return query;
    }
    
    private String composeEventTypeCountryCriteria(List<VeevaEmBusRuleModel.BusinessRuleConfig> configs) {
        String query = '';
        Integer i = 0;
        for (VeevaEmBusRuleModel.BusinessRuleConfig config : configs) {
            if (i > 0) {
                query += ' OR ';
            }
            // global rule
            if (String.isBlank(config.country)) {
                query += '(' + EVENT_RELATIONSHIP + '.RecordType.DeveloperName = \'' + config.eventType + '\')';
            } else {
                query += '(' + EVENT_RELATIONSHIP + '.RecordType.DeveloperName = \'' + config.eventType
                    + '\' AND ' + EVENT_RELATIONSHIP + '.Country_vod__c = \'' + config.country + '\')';
            }
            i++;
        }
        return query;
    }
    
    private EM_Event_vod__c getEventData(EventExpenseData eventExpenseData){
        String eventId = expenseRequest.eventId;
        EM_Event_vod__c event;  
        String currencyIsoCode;
        if(MultiCurrencyUtil.isMultiCurrencyOrg()){
            currencyIsoCode = ', CurrencyIsoCode';
        }else{    
            currencyIsoCode = '';
        }
        event = Database.query('SELECT Id,Status_vod__c, Start_Time_vod__c, Estimated_Attendance_vod__c,'     
                                   + '(SELECT Id, Expense_Header_vod__c, Event_vod__c, Actual_vod__c, Expense_Type_vod__c ' 
                                   + currencyIsoCode 
                                   + ' FROM Expense_Lines_Event_vod__r),'
                                   + ' (SELECT Id, Attendee_Account_Type_vod__c FROM EM_Attendee_Event_vod__r), '
                                   + ' (SELECT Id FROM EM_Event_Speaker_vod__r), '
                                   + ' (SELECT Id, Event_vod__c, Estimate_vod__c, Expense_Type_vod__c ' 
                                   + currencyIsoCode 
                                   + ' FROM Expense_Estimate_vod__r)'
                                   + ' FROM EM_Event_vod__c WHERE Id = :eventId ');  
        eventExpenseData.startTime = event.Start_Time_vod__c;
        eventExpenseData.estimatedAttendance = event.Estimated_Attendance_vod__c;
        eventExpenseData.eventId = event.Id;
        eventExpenseData.status = event.Status_vod__c;
        return event;
    }
    
    private void getExpenseLinesFromRequest(List<ExpenseLine> expenseLines, Map<String, ExpenseLine> expenseLineMap, Map<String, ExpenseAttribution> attributionMap){
        //lines from request            
        List<ExpenseLineRequest> lineRequests = expenseRequest.expenseLines; 
        if(VeevaEmBusRuleUtils.isEmpty(lineRequests)){
            return;
        }
        for(ExpenseLineRequest line : lineRequests){
            ExpenseLine lineRow = new ExpenseLine();
            lineRow.actual = line.actual;
            String expenseType = (String)line.expenseType;
            lineRow.expenseType = line.expenseType;
            lineRow.id = line.id;
            lineRow.expenseHeader = expenseRequest.expenseHeaderId;
            if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                lineRow.currencyIsoCode = line.currencyIsoCode; 
            }  
            if(String.isNotEmpty(lineRow.id)){
                expenseLineMap.put(lineRow.id, lineRow);
            }else{
                expenseLines.add(lineRow);
            }
            //attribution from request
            List<ExpenseAttributionRequest> attributionRequests = line.expenseAttribution;
            if(attributionRequests != null && attributionRequests.size() > 0){
                List<ExpenseAttribution> requestAttribution = new List<ExpenseAttribution>();
                for(ExpenseAttributionRequest attribution : attributionRequests){
                    ExpenseAttribution attributionRow = new ExpenseAttribution();                          
                    attributionRow.expenseLine = attribution.expenseLine;
                    attributionRow.attendee = attribution.attendee;
                    attributionRow.speaker = attribution.speaker;
                    attributionRow.actual = attribution.actual;
                    if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                        attributionRow.currencyIsoCode = attribution.currencyIsoCode;  
                    }                        
                    requestAttribution.add(attributionRow);                                    
                    attributionMap.put(attribution.id, attributionRow);                    
                }                    
                lineRow.expenseAttribution = requestAttribution;                
            }             
        }
        if(expenseLineMap.size() > 0){
            expenseLines.addAll(expenseLineMap.values());
        }
    }
    
    private List<String> getExpenseLinesFromRequestDB(EM_Event_vod__c event, List<ExpenseLine> expenseLines, Map<String, ExpenseLine> expenseLineMap){
        //lines from db            
        List<Expense_Line_vod__c> lines = event.getSObjects('Expense_Lines_Event_vod__r');
        List<String> expenseLinesIds = new List<String>();
        if(VeevaEmBusRuleUtils.isEmpty(lines)){
            return expenseLinesIds;
        }
        for (Expense_Line_vod__c line : lines){
            String lineId = line.Id;
            if(expenseLineMap.get(lineId) == null){
                expenseLinesIds.add(lineId);
                ExpenseLine lineRow = new ExpenseLine();
                double actual = line.Actual_vod__c;
                lineRow.expenseHeader = line.Expense_Header_vod__c;
                lineRow.actual = actual;
                String expenseType = line.Expense_Type_vod__c;
                lineRow.expenseType = expenseType;
                lineRow.id = line.Id;
                if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                    lineRow.currencyIsoCode = (String)line.get('CurrencyIsoCode');  
                }   
                expenseLines.add(lineRow);
            }    
        }
        return expenseLinesIds;
    }
    
    private void getExpenseData(EM_Event_vod__c event, EventExpenseData eventExpenseData){
        List<ExpenseLine> expenseLines = new List<ExpenseLine>();
        //all valid expense lines map, key is line id, if presave, expense line should fetched from request
        Map<String, ExpenseLine> expenseLineMap = new Map<String, ExpenseLine>();
        //all valid expense attribution map, key is attribution id, if presave, expense attribution should fetched from request
        Map<String, ExpenseAttribution> attributionMap = new Map<String, ExpenseAttribution>();
        getExpenseLinesFromRequest(expenseLines, expenseLineMap, attributionMap);
        List<String> expenseLinesIds = getExpenseLinesFromRequestDB(event, expenseLines, expenseLineMap);       
        eventExpenseData.expenseLines = expenseLines;
        getExpenseAttributions(eventExpenseData, expenseLinesIds, attributionMap);
    }
    
    private void getExpenseAttributions(EventExpenseData eventExpenseData, List<String> expenseLinesIds, Map<String, ExpenseAttribution> attributionMap){
        List<Expense_Attribution_vod__c> expenseAttributions = new List<Expense_Attribution_vod__c>();
        if(VeevaEmBusRuleUtils.isNotEmpty(expenseLinesIds)){  
            String currencyIsoCode;
            if(MultiCurrencyUtil.isMultiCurrencyOrg()){
                currencyIsoCode = ', CurrencyIsoCode';
            }else{    
                currencyIsoCode = '';        
            }
            expenseAttributions = Database.query('SELECT Expense_Line_vod__c, Actual_vod__c, Incurred_Expense_Attendee_vod__c, Incurred_Expense_Speaker_vod__c '                                                         
                                                     + CurrencyIsoCode + ' FROM Expense_Attribution_vod__c WHERE Expense_Line_vod__c IN :expenseLinesIds ') ;              
        }                      
        Map<String, List<ExpenseAttribution>> expenseAttributionMap = new Map<String, List<ExpenseAttribution>>();
        List<ExpenseAttribution> requestAttributions = attributionMap.values();
        //attribution from db
        if(VeevaEmBusRuleUtils.isNotEmpty(expenseAttributions)){              
            for (Expense_Attribution_vod__c attribution : expenseAttributions){                  
                ExpenseAttribution attributionRow = new ExpenseAttribution();
                String expenseLineId = attribution.Expense_Line_vod__c;
                if(attributionMap.get(expenseLineId) == null){                      
                    attributionRow.expenseLine = expenseLineId;
                    attributionRow.attendee = attribution.Incurred_Expense_Attendee_vod__c;
                    attributionRow.speaker = attribution.Incurred_Expense_Speaker_vod__c;
                    double actual = attribution.Actual_vod__c;
                    attributionRow.actual = actual;
                    if(MultiCurrencyUtil.isMultiCurrencyOrg()){                          
                        attributionRow.currencyIsoCode = (String)attribution.get('CurrencyIsoCode');                      
                    }
                    if(expenseAttributionMap.get(expenseLineId) == null){                          
                        List<ExpenseAttribution> attributionList = new List<ExpenseAttribution>();                          
                        attributionList.add(attributionRow);                          
                        expenseAttributionMap.put(expenseLineId, attributionList);                      
                    }else{                          
                        expenseAttributionMap.get(expenseLineId).add(attributionRow);                     
                    }                   
                }              
            }            
        }
        if(VeevaEmBusRuleUtils.isNotEmpty(eventExpenseData.expenseLines)){               
            for (ExpenseLine lineRow : eventExpenseData.expenseLines){                    
                String expenseLineId = lineRow.id;                    
                if(expenseAttributionMap.get(expenseLineId) != null){                        
                    lineRow.expenseAttribution = expenseAttributionMap.get(expenseLineId);       
                }
            } 
        }
    }
    
    private void getEstimateData(EM_Event_vod__c event, EventExpenseData eventExpenseData){
        List<EM_Expense_Estimate_vod__c> estimates = event.getSObjects('Expense_Estimate_vod__r');
        List<ExpenseEstimate> estimateLines = new List<ExpenseEstimate>();
        if(VeevaEmBusRuleUtils.isNotEmpty(estimates)){               
            for (EM_Expense_Estimate_vod__c estimate : estimates){                    
                ExpenseEstimate estimateRow = new ExpenseEstimate();
                double estimateAmount = estimate.Estimate_vod__c;
                estimateRow.estimate = estimateAmount;
                String expenseType = estimate.Expense_Type_vod__c;
                estimateRow.expenseType = expenseType;
                estimateRow.id = estimate.Id;                   
                if(MultiCurrencyUtil.isMultiCurrencyOrg()){                        
                    estimateRow.currencyIsoCode = (String)estimate.get('CurrencyIsoCode');
                }
                estimateLines.add(estimateRow);
            }  
        }                    
        eventExpenseData.expenseEstimates = estimateLines;   
    }
    
    private void getAttendeeData(EM_Event_vod__c event, EventExpenseData eventExpenseData){
        List<EM_Attendee_vod__c> attendees = event.getSObjects('EM_Attendee_Event_vod__r');
        List<EventAttendee> attendeeLines = new List<EventAttendee>();
        if(expenseRequest.hasAttendee && VeevaEmBusRuleUtils.isNotEmpty(attendees)){               
            for (EM_Attendee_vod__c attendee : attendees){                
                EventAttendee attendeeRow = new EventAttendee();
                attendeeRow.id = attendee.Id;
                attendeeRow.accountType = attendee.Attendee_Account_Type_vod__c;
                attendeeLines.add(attendeeRow);               
            }            
        }            
        eventExpenseData.attendees = attendeeLines; 
    }
    
    private void getSpeakerData(EM_Event_vod__c event, EventExpenseData eventExpenseData){
        List<EM_Event_Speaker_vod__c> speakers = event.getSObjects('EM_Event_Speaker_vod__r');
        if(VeevaEmBusRuleUtils.isNotEmpty(speakers)){               
            eventExpenseData.speakers = speakers;            
        }
    }
    
    private EventExpenseData getCurrentEventExpenseData() {
        EventExpenseData eventExpenseData = new EventExpenseData(); 
        EM_Event_vod__c event = getEventData(eventExpenseData);            
        getExpenseData(event, eventExpenseData);
        getEstimateData(event, eventExpenseData);
        getAttendeeData(event, eventExpenseData);
        getSpeakerData(event, eventExpenseData);
        return eventExpenseData;
    }
    
    private class EventExpenseData{
        private String eventId;
        private Datetime startTime;
        private double estimatedAttendance;
        private String status;
        private List<EM_Event_Speaker_vod__c> speakers;
        private List<ExpenseLine> expenseLines;
        private List<ExpenseEstimate> expenseEstimates;
        private List<EventAttendee> attendees;
    }
    
    private class EventAttendee{
        private String id;
        private String accountType;
    }
    
    private abstract class ExpenseDataObject{
        protected String id;
        protected String expenseType;
        protected String currencyIsoCode;
        protected double actual;
    }

    private class ExpenseEstimate extends ExpenseDataObject{
        private double estimate;
    }

    private class ExpenseLine extends ExpenseDataObject{
        private String expenseHeader;
        private List<ExpenseAttribution> expenseAttribution;
    }

    private class ExpenseAttribution extends ExpenseDataObject{
        private String expenseLine;
        private String attendee;
        private String speaker;
    }
    
    private class ExpenseAttributionRequest{
        private String id;
        private String expenseType;
        private String currencyIsoCode;
        private double actual;
        private String expenseLine;
        private String attendee;
        private String speaker;
    }

    private class ExpenseLineRequest{
        protected String id;
        protected String expenseType;
        protected String currencyIsoCode;
        protected double actual;
        private List<ExpenseAttributionRequest> expenseAttribution;
    }

    public class ExpenseRequest {
        private String eventId;
        private String eventAction;
        private String platform;
        private Datetime startTime;
        private String eventType;
        private String country;
        private String expenseHeaderId;
        private Set<String> ruleIds;
        private Set<String> accountIds;
        private Set<String> userIds;
        private Set<String> contactIds;
        private Set<String> attributionIds;
        private Map<String, String> attendeeKeyMap;
        private Map<String, String> eventAttendeeKeys;
        private List<ExpenseLineRequest> expenseLines;
        private boolean hasAttendee;
        //key is accountid or user id or contact id, group by expense type and currency code and attendee
        Map<String, List<ExpenseAttributionRequest>> preSaveAttributionMap;
        public Map<String, RuleAttendee> ruleAttendees;
        //key is parent expense type id, value is related child expense types id
        private Map<String, Set<String>> expenseTypeMap;
        //key is expense type id, value is expense type name
        private Map<String, String> expenseTypeNameMap;
        //key is expense type id, value is parent expense type id
        private Map<String, String> parentExpenseTypeMap;
    }

    private class ExpenseViolation {
        private String ruleId;
        private String attendeeId;
        private List<String> perAttendeeIds;
        private String matchedAmount;
        private List<String> violatedIds;
        private String violatedName;
    }
  
    public class RuleAttendee {
        private String accountId;
        private String userId;
        private String contactId;
        public String attendeeAccountType;
        public String attendeeName;
        private String attendeeFirstName;
        private String attendeeLastName;

        public RuleAttendee(String accountId, String userId, String contactId) {
            this.accountId = accountId;
            this.userId = userId;
            this.contactId = contactId;
        }
    }

    global class ExpenseResult{
        public boolean success;
        public List<ExpenseViolation> ruleViolations;
        public Map<String, RuleAttendee> ruleAttendees;
        public String errorMessage;
        public String eventHistoryBatchId;
    }
}