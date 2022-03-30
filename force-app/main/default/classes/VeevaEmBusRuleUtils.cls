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
 * VeevaEmBusRuleUtils provides common functions to be shared by all business rule categories.
 */
global without sharing class VeevaEmBusRuleUtils {

    public static final Integer MAX_SOQL_LINE_LENGTH = 100000;
    public static final Integer MAX_CREATE_BATCH = 10000;
    public static final Integer RULE_COUNT_LIMIT = 50;
    public static final Integer RULE_QUERY_LIMIT = 90;
    public static final boolean OPT_ALL_OR_NONE = false;
    public static final String ATTENDEE_ACCOUNT = 'Account_vod__c';
    public static final String ATTENDEE_USER = 'User_vod__c';
    public static final String ATTENDEE_CONTACT = 'Contact_vod__c';
     
    public static String getAttendeeId(String accountId, String userId, String contactId) {
        String attendeeId;
        if (String.isNotBlank(accountId)) {
            attendeeId = accountId;
        } else if (String.isNotBlank(userId)) {
            attendeeId = userId;
        } else if (String.isNotEmpty(contactId)) {
            attendeeId = contactId;
        }
        return attendeeId;
    }
    
    public static String getDeveloperName(Map<Id, Schema.RecordTypeInfo> recordTypeInfo, String recordTypeId) {
        String developerName = '';
        if (recordTypeInfo.get(recordTypeId) != null) {
            developerName = recordTypeInfo.get(recordTypeId).getDeveloperName();
        }
        return developerName;
    }

    public static String toCommaSeparated(List<String> ids) {
        String result = '(';
        for(Integer ndx = 0; ndx < ids.size(); ndx++) {
            String currentId = ids.get(ndx);
            currentId = String.escapeSingleQuotes(currentId); 
            result += '\'' + currentId + '\'';
            if(ndx+1 < ids.size()) {
                result += ',';
            }
        }
        
        result += ')';
        return result;
    }
    
    public static List<String> toCommaSeparated(List<String> values, Integer maxSize) {
        List<String> allCommaSeparated = new List<String>();
        Integer length = 0;
        Integer start = 0;
        Integer index;
        boolean exceedLimit = false;
        for (index=0; index < values.size(); index++) {
            String value = values.get(index) != null ? values.get(index) : '';
            if (value.length() == 0) {
                continue;
            }
            Integer lenToAdd = value.length() + 3; // start and end quote, plus comma
            if (lenToAdd >= maxSize) { //single element in list is larger than maxSize
                exceedLimit = true;
                break;
            }
            if (length + lenToAdd > maxSize - 1) {//adding current value at index exceeds the maxSize
                allCommaSeparated.add(toCommaSeparated(getSubList(values, start, index)));
                length = lenToAdd;
                start = index;
            } else {
                length += lenToAdd;
            }
        }
        if (exceedLimit) {
            return new List<String>();
        }
        allCommaSeparated.add(toCommaSeparated(getSubList(values, start, index)));
        return allCommaSeparated;
    }

    private static List<String> getSubList(List<String> values, Integer fromIndex, Integer toIndex) {
        List<String> subList = new List<String>();
        for (Integer i=fromIndex; i<toIndex; i++) {
            subList.add(values.get(i));
        }
        return subList;
    }

    private static Integer splitIds(List<String> ids, List<String> batch, Integer maxLength) {
        Integer length = maxLength;
        if (!ids.isEmpty()) {
            List<String> idInClause = toCommaSeparated(ids, maxLength);
            if (!idInClause.isEmpty()) {
                batch.addAll(idInClause);
            }
            if (idInClause.isEmpty() || idInClause.size() > 1) {
                //-1 means the maxLength is consumed, the calling function will split new Ids based on a different length
                length = -1;
            } else {
                length = maxLength - idInClause.get(0).length();
            }
        }
        return length;
    }

    private static String setInClause(String fieldName, List<String> ids, String str) {
        if (!ids.isEmpty()) {
            if (str.length() > 0) {
                str += ' OR ';
            }
            str += fieldName + ' IN ' + toCommaSeparated(ids);
        }
        return str;
    }

    private static void setInClauseFromBatch(String fieldName, List<String> batches, List<String> idClause) {
        for (String batch : batches) {
            idClause.add(fieldName + ' IN ' + batch);
        }
    }

    private static void setInClauseFromIds(Map<String, List<String>> fieldIds, List<String> idClause) {
        String str = '';
        for (String fieldName : fieldIds.keySet()) {
            List<String> batch = fieldIds.get(fieldName);
            if (batch != null && batch.size() == 1) {
                if (String.isNotBlank(str)) {
                    str += ' OR ';
                }
                str += fieldName + ' IN ' + batch.get(0);
            }
        }
        if (String.isNotBlank(str)) {
            idClause.add(str);
        }
    }
    
    public static List<String> composeIdCriteria(List<String> accounts, List<String> users, List<String> contacts) {
        List<String> idClauseBatch = new List<String>();
        List<String> accountIdBatch = new List<String>();
        List<String> userIdBatch = new List<String>();
        List<String> contactIdBatch = new List<String>();
        boolean separateAccountQuery = false;
        boolean separateUserQuery = false;
        boolean separateContactQuery = false;

        Integer initialLimit = MAX_SOQL_LINE_LENGTH - 1000;
        Integer accountLimit = splitIds(accounts, accountIdBatch, initialLimit);
        // Not able to query accounts, users and contacts in one query
        if (accountLimit == -1) {
            separateAccountQuery = true;
            accountLimit = initialLimit;
        }
        Integer userLimit = splitIds(users, userIdBatch, accountLimit);
        if (userLimit == -1) {
            separateUserQuery = true;
            userIdBatch = new List<String>();
            userLimit = splitIds(users, userIdBatch, initialLimit);
            if (userLimit == -1) {
                userLimit = initialLimit;
            }
        } 
        Integer contactLimit = splitIds(contacts, contactIdBatch, userLimit);
        if (contactLimit == -1) {
            separateContactQuery = true;
            contactIdBatch = new List<String>();
            splitIds(contacts, contactIdBatch, initialLimit);
        }
        String str = '';
        if (separateUserQuery) {
            // Account, user, contact in separate query
            setInClauseFromBatch(ATTENDEE_ACCOUNT, accountIdBatch, idClauseBatch);
            setInClauseFromBatch(ATTENDEE_USER, userIdBatch, idClauseBatch);
            setInClauseFromBatch(ATTENDEE_CONTACT, contactIdBatch, idClauseBatch);
        } else if (separateAccountQuery && !separateContactQuery) {
            // Join user and contact query
            Map<String, List<String>> fieldIds = new Map<String, List<String>>();
            fieldIds.put(ATTENDEE_USER, userIdBatch);
            fieldIds.put(ATTENDEE_CONTACT, contactIdBatch);
            setInClauseFromIds(fieldIds, idClauseBatch);
        } else if (!separateAccountQuery && separateContactQuery) {
            // Join account and user query
            Map<String, List<String>> fieldIds = new Map<String, List<String>>();
            fieldIds.put(ATTENDEE_ACCOUNT, accountIdBatch);
            fieldIds.put(ATTENDEE_USER, userIdBatch);
            setInClauseFromIds(fieldIds, idClauseBatch);
            setInClauseFromBatch(ATTENDEE_CONTACT, contactIdBatch, idClauseBatch);
        } else {
            // All attendees in one query
            str = setInClause(ATTENDEE_ACCOUNT, accounts, str);
            str = setInClause(ATTENDEE_USER, users, str);
            str = setInClause(ATTENDEE_CONTACT, contacts, str);
            idClauseBatch.add(str);
        }
        return idClauseBatch;
    }
    
    public static List<String> composeIdClause(List<String> ids, String fieldName) {
        List<String> idClauseBatch = new List<String>();
        List<String> batch = toCommaSeparated(ids, MAX_SOQL_LINE_LENGTH - 1000);
        setInClauseFromBatch(fieldName, batch, idClauseBatch);
        return idClauseBatch;
    }

    public static boolean isNotEmpty(List<Object> objects){
        return objects != null && !objects.isEmpty();
    }
    
    public static boolean isEmpty(List<Object> objects){
        return objects == null || objects.isEmpty();
    }
}