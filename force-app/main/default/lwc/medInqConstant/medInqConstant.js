export default class MedInqConstant {
    static MEDICAL_INQUERY = "Medical_Inquiry_vod__c";
    static PHONE = "Phone_Number_vod__c";
    static FAX = "Fax_Number_vod__c";
    static EMAIL = "Email_vod__c";
    static ZVOD_DELIVERY_METHOD = "zvod_Delivery_Method_vod__c";
    static ZVOD_DISCLAIMER = "zvod_Disclaimer_vod__c";
    static DISCLAIMER = "Disclaimer_vod__c";
    static DELIVERY_METHOD = "Delivery_Method_vod__c";
    static STATE = "State_vod__c";
    static COUNTRY = "Country_vod__c";
    static GROUP_IDENTIFIER = "Group_Identifier_vod__c";
    static ACCOUNT = "Account_vod__c";
    static PRODUCT = "Product__c";
    static INQUIRY_TEXT = "Inquiry_Text__c";

    // veeva messages
    static CAT_MEDICAL_INQUIRY = "MEDICAL_INQUIRY";
    static MSG_MED_INQ_ADDRESS = "MED_INQ_ADDRESS";
    static MSG_MED_INQ_PHONE = "MED_INQ_PHONE";
    static MSG_MED_INQ_FAX = "MED_INQ_FAX";
    static MSG_MED_INQ_EMAIL = "MED_INQ_EMAIL";
    static MSG_DISCLAIMER = "DISCLAIMER";
    static MSG_SHIP_TO_NEW_ADD = "SHIP_TO_NEW_ADD";
    static MSG_SEND_TO_NEW_EMAIL = "SEND_TO_NEW_EMAIL";
    static MSG_NEW_FAX_NUMBER = "NEW_FAX_NUMBER";
    static MSG_NEW_PHONE_NUMBER = "NEW_PHONE_NUMBER";
    static MSG_ADD_SECTION_MPI = "ADD_SECTION_MPI";
    static MSG_SIGNATURE_REQUIRED = "SIGNATURE_REQUIRED";

    static SIGNALS_MAP = { eom: "ana", eoe: "ane", eop: "anp", eof: 'anf' };

    static NEW_FIELDS = {
        "ana": ["Address_Line_1_vod__c", "Address_Line_2_vod__c", "City_vod__c", "State_vod__c", "Zip_vod__c", "Country_vod__c"],
        "ane": [MedInqConstant.EMAIL],
        "anf": [MedInqConstant.FAX],
        "anp": [MedInqConstant.PHONE]
    };

    static REQUIRED_NEW_MAIL_FIELDS = ["Address_Line_1_vod__c", "City_vod__c", "State_vod__c"];
    static SKIP_MPI_COPY = ["Signature_Date_vod__c", "Signature_vod__c", "Status_vod__c", "Lock_vod__c", "Group_Count_vod__c", "Mobile_ID_vod__c", "Mobile_Created_Datetime_vod__c"];
    static CLONE_SKIP_FIELDS = [...MedInqConstant.SKIP_MPI_COPY, "Call2_vod__c"];

    // custom buttons
    static SEND_EMAIL_VOD = "Send_Email_vod";
    static RECORD_A_CALL_VOD = "Record_a_Call_vod";
    static CUSTOM_BUTTONS = [MedInqConstant.SEND_EMAIL_VOD, MedInqConstant.RECORD_A_CALL_VOD];

}