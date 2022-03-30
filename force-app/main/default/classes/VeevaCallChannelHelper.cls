public with sharing class VeevaCallChannelHelper {

    public static void setCallChannel (Boolean isAfter, Boolean isUpdate, List<Call2_vod__c> calls) {
        //check for FLS
        Schema.DescribeFieldResult callChannelFormulaField = Schema.SObjectType.Call2_vod__c.fields.Call_Channel_Formula_vod__c;
        Schema.DescribeFieldResult lastDeviceField = Schema.SObjectType.Call2_vod__c.fields.Last_Device_vod__c;
        if (callChannelFormulaField.isAccessible() && lastDeviceField.isAccessible()) {
            //get picklist values
            Set<String> callChannelValues = new Set<String>{'Email_vod', 'Face_to_face_vod', 'Message_vod', 'Other_vod', 'Phone_vod', 'Video_vod'};
            List<Call2_vod__c> callsToSetChannel = new List<Call2_vod__c>();
            List<Call2_vod__c> childCallsToSetChannel = new List<Call2_vod__c>();
            List<Id> parentCallIds = new List<Id>();
            List<Id> parentIds = new List<Id>();
            //loop through calls and check for all calls with submitted or saved status
            for (Call2_vod__c currCall : calls) {
                String currCallChannel = currCall.Call_Channel_vod__c;
                String lastDevice = currCall.Last_Device_vod__c;
                Boolean offlineCheck = !String.isBlank(lastDevice) && lastDevice != 'Online_vod';
                if ((currCall.Status_vod__c == 'Submitted_vod' || currCall.Status_vod__c == 'Saved_vod') && !offlineCheck) {
                    //if we create parent and child calls on insert
                    if (currCall.Parent_Call_vod__c != null && isAfter) {
                        if (!parentCallIds.contains(currCall.Parent_Call_vod__c)) {
                            parentCallIds.add(currCall.Parent_Call_vod__c);
                        }
                        childCallsToSetChannel.add(currCall);
                    }
                    //if parent call formula is updated, we update existing child calls
                    else if (currCall.Is_Parent_Call_vod__c == 1.0 && isAfter && isUpdate) {
                        parentIds.add(currCall.Id);
                    }
                    //for calls with no parents or children, set channel on before insert, before update
                    else if (currCall.Parent_Call_vod__c == null && !isAfter) {
                        callsToSetChannel.add(currCall);
                    }
                }
            }
            //evaluate the call formulas and set the call channel field value
            evaluateCallChannelFormula(callsToSetChannel, callChannelValues);
            evaluateParentCallChannelFormula(childCallsToSetChannel, parentCallIds, callChannelValues);
            evaluateChildCallChannelFormula(parentIds, callChannelValues);
        }
    }
    
    private static void evaluateCallChannelFormula(List<Call2_vod__c> callsToSetChannel, Set<String> callChannelValues) {
        if (!callsToSetChannel.isEmpty()) {
            for (Call2_vod__c currCall : callsToSetChannel) {
                String formula = currCall.Call_Channel_Formula_vod__c;
                if (!String.isBlank(formula) && callChannelValues.contains(formula)) {
                    currCall.Call_Channel_vod__c = formula;
                }
                else if (!callChannelValues.contains(formula)) {
                    currCall.Call_Channel_vod__c = '';
                }
            }
        }
        
    }
    private static void evaluateParentCallChannelFormula(List<Call2_vod__c> childCalls, List<String> parentIds, Set<String> callChannelValues) {
        if (!childCalls.isEmpty()) {
            Map<Id, Call2_vod__c> queriedCalls = getCallMapFromIds(parentIds);
            List<Call2_vod__c> callsToUpdate = new List<Call2_vod__c>();
            for (Integer i = 0; i < childCalls.size(); i++) {
            
                Call2_vod__c currCall = new Call2_vod__c(Id = childCalls[i].Id, Parent_Call_vod__c = childCalls[i].Parent_Call_vod__c,
                Call_Channel_vod__c = childCalls[i].Call_Channel_vod__c);
                Call2_vod__c parentCall = queriedCalls.get(currCall.Parent_Call_vod__c);
                String formula = parentCall.Call_Channel_Formula_vod__c;
                
                if (callChannelValues.contains(formula) && currCall.Call_Channel_vod__c != formula) {
                    currCall.Call_Channel_vod__c = formula;
                    callsToUpdate.add(currCall);
                }
            }
            update callsToUpdate;
        }
    }
    private static void evaluateChildCallChannelFormula(List<Id> parentIds, Set<String> callChannelValues) {
        if (!parentIds.isEmpty()) {
            List<Call2_vod__c> parentCalls = [SELECT Call_Channel_vod__c, (SELECT Call_Channel_vod__c FROM Call2_vod__r) FROM Call2_vod__c WHERE Id=:parentIds];
            List<Call2_vod__c> updateChildCalls = new List<Call2_vod__c>();
            for (Call2_vod__c parent : parentCalls) {
                String formula = parent.Call_Channel_vod__c;
                for (Call2_vod__c child : parent.Call2_vod__r) {
                    Call2_vod__c childObj = new Call2_vod__c(Id = child.Id, Call_Channel_vod__c = formula, Override_Lock_vod__c = true);
                    updateChildCalls.add(childObj);
                }
            }
            update updateChildCalls;
        }
    }
    private static Map<Id, Call2_vod__c> getCallMapFromIds(List<String> callIds) {
        List<Call2_vod__c> queriedCalls = [SELECT Id, Call_Channel_vod__c, Call_Channel_Formula_vod__c, Parent_Call_vod__c FROM Call2_vod__c WHERE Id=:callIds];
        Map<Id, Call2_vod__c> callMap = new Map<Id, Call2_vod__c>();
        for (Call2_vod__c call : queriedCalls) {
            callMap.put(call.Id, call);
        }
        return callMap;
    }
    
    
}