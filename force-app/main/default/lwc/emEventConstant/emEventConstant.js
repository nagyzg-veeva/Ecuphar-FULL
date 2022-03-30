export default class EmEventConstant {
   static ZVOD_EVENT_LAYOUT = "zvod_Event_Layout_vod__c";
   static START_TIME = "Start_Time_vod__c";
   static END_TIME = "End_Time_vod__c";
   static COUNTRY = "Country_vod__c";
   static COUNTRY_LOOKUP = "Country_vod__r";
   static COUNTRY_NAME = "Country_Name_vod__c";
   static EVENT_CONFIG = "Event_Configuration_vod__c";
   static DISPLAY_EVENT_ACTION_DIALOG = "displayEventActionDialog";
   static HANDLE_EVENT_ACTION_DIALOG = "handleEventActionDialog";
   static POPULATE_RELATED_LIST_TABS = "populateRelatedListTabs";
   static APPROVER_ID = "approverId";
   static PLE_SUPPORTED_OBJECTS = [
      "EM_Attendee_vod__c",
      "EM_Event_Budget_vod__c",
      "EM_Event_Session_vod__c",
      "EM_Event_Session_Attendee_vod__c",
      "EM_Event_Speaker_vod__c",
      "EM_Event_Team_Member_vod__c",
      "Expense_Header_vod__c",
      "Expense_Line_vod__c",
      "EM_Expense_Estimate_vod__c",
      "EM_Event_Material_vod__c",
   ];
   static EVENT = "Event_vod__c";
}