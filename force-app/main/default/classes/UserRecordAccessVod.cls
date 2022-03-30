public with sharing class UserRecordAccessVod {

    @AuraEnabled(cacheable=true)
    public static UserRecordAccess getUserRecordAccess(String recordId){
        return [SELECT HasEditAccess, HasDeleteAccess, RecordId FROM UserRecordAccess WHERE RecordId = :recordId AND UserId = :UserInfo.getUserId()];
    }
}