/******************************************************************************
 *                                                                              
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Verticals onDemand, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Verticals onDemand.
 * 
 * Copyright (c) 2009 Verticals onDemand, Inc.  All Rights Reserved.
 *
 ******************************************************************************/
public with sharing class VOD_UserTerritoryExtension {
    private final Account acct;
    private List<UserTerritoryRow> theList = null;
    
    public VOD_UserTerritoryExtension(ApexPages.StandardController controller) {
        this.acct = (Account)controller.getRecord();
    }

    public List<UserTerritoryRow> getUserTerritories() {
        TerritoryManagement tm = TerritoryManagementFactory.getInstance();

        if (theList != null) {
            return theList;
        }

        String acctId = acct.id;
        if ((acctId == null) || (acctId == '')) {
            return null;
        }

        Set<String> groupIds = new Set<String>();
        for (AccountShare acctShare : [Select UserOrGroupId From AccountShare Where AccountId=:acctId And RowCause In ('Rule','Territory','TerritoryManual','Territory2AssociationManual')]) {
            groupIds.add(acctShare.UserOrGroupId);
        }

        if (groupIds.size() <= 0) {
            return null;
        }

        Set<Id> territoryIds = new Set<Id>();
        for (Group gr : [Select RelatedId From Group Where Id In :groupIds]) {
            territoryIds.add(gr.RelatedId);
        }

        if (territoryIds.size() <= 0) {
            return null;
        }

        Map<Id, Map<String, String>> userTerritories = tm.getUserTerritories(null, territoryIds);

        Set<String> userIds = new Set<String>();
        for (Map<String, String> userTerritory : userTerritories.values()) {
            userIds.add(userTerritory.get('UserId'));
        }

        Map<Id,User> users = null;
        if (userIds.size() > 0) {
            users = new Map<Id, User>([Select Id,Name From User Where Id In :userIds]);
        } else {
            users = new Map<Id, User>();
        }

        Map<Id, Map<String, String>> territories = tm.getTerritories(territoryIds);

        Map<String, UserTerritoryRow> tempMap = new Map<String,UserTerritoryRow>();
        for (Map<String, String> terr : territories.values()) {
            UserTerritoryRow utr = new UserTerritoryRow();
            utr.Territory = terr.get('Name');
            utr.Users = '';
            if (terr.get('Description') != null) {
                utr.Description = terr.get('Description');
            } else {
                utr.Description = '';
            }
            tempMap.put(terr.get('Name')+'   '+terr.get('Id'), utr);  // just in case Name is not unique
        }

        for (Map<String, String> ut : userTerritories.values()) {
            String territoryId = ut.get('territoryId');
            if (territoryId == null) {
                territoryId = ut.get('TerritoryId');
            }
            Map<String, String> tempTerr = territories.get(territoryId);
            if (tempTerr == null) {
                continue;
            }
            String keyValue = tempTerr.get('Name')+'   '+tempTerr.get('Id');
            UserTerritoryRow terrRow = tempMap.get(keyValue);
            if (terrRow == null) {
                continue;
            }
            String userId = ut.get('UserId');
            User usr = users.get(userId);
            if (usr != null) {
                if (terrRow.Users.length() > 0) {
                    terrRow.Users += ', ';
                }
                terrRow.Users += usr.Name;
            }
            tempMap.put(keyValue, terrRow);
        }

        List<String> keys = new List<String>(tempMap.keySet());
        keys.sort();

        theList = new List<UserTerritoryRow>();
        for (String key : keys) {
            theList.add(tempMap.get(key));
        }

        return theList;
    }
    
    public String getOnLoadJS() {
        List<UserTerritoryRow> terrs = getUserTerritories();
        return 'if(document.documentElement&&document.documentElement.scrollHeight){window.resizeBy(0,document.documentElement.scrollHeight-200);}else if(document.body.scrollHeight){window.resizeBy(0,document.body.scrollHeight-200);}';
    }
    
    public class UserTerritoryRow {
        public String territory{get; set;}
        public String users{get; set;}
        public String description{get; set;}
    }
}