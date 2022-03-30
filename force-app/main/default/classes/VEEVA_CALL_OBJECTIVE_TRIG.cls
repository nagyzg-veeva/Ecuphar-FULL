public class VEEVA_CALL_OBJECTIVE_TRIG{
    //http://www.salesforce.com/us/developer/docs/apexcode/index_Left.htm#CSHID=apex_classes_static.htm|StartTopic=Content%2Fapex_classes_static.htm|SkinName=webhelp
    public static boolean invoked = false;

    public static List<Call_Objective_vod__c> objectives = new List<Call_Objective_vod__c>();
    public static Set<Id> objectivesToRollup = new Set<Id>();

    public static boolean isInvoked(){
        return invoked;
    }

    public static void setInvoked(boolean isInvoked){
        invoked = isInvoked;
    }
}