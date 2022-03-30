export default class VeevaConstant {
    static OBJECT_ICONS = {
        NoteAndAttachment: "standard:file",
        Account: "standard:account",
        User: "standard:user"
    };

    static DEFAULT_ICON = "standard:default";

    static FILETYPE_ICONS = {
        POWER_POINT_X: "ppt"
    };

    // Although currency is a number field, not including it as such
    // SF returns a string value in displayValue for currency fields
    // Treating currency fields as text fields instead
    static FIELD_TYPE_NUMBER = ["Int", "Double", "Percent", "Long"];
    static FIELD_TYPE_TO_FORMATTER = {
        Percent: 'percent-fixed',
        Int: 'decimal',
        Double: 'decimal'
    }

    static DATATYPE_TO_INPUTTYPE = {
        Currency: "number",
        Date: "date",
        DateTime: "datetime",
        Double: "number",
        Email: "email",
        Int: "number",
        Percent: "number",
        Number: "number",
        Phone: "tel",
        String: "text",
        Time: "time",
        Url: "text", // Use text input type for URL to avoid SF URL validation requiring protocol in URL for lightning-input LWC
        TextArea: "text"
    };

    // delay firing of event handler
    static DEBOUNCE_DELAY = 300;

    // search
    static MIN_SEARCH_TERM_LENGTH = 2; // Min number of chars required to start searching
    static SEARCH_COLUMNS = ['Name', 'Title']; //TODO default

    // Standard fields to include saving a record
    static STANDARD_FIELDS_TO_UPDATE = [
        "CurrencyIsoCode",
        "Name",
    ];

    // common field names
    static FLD_SIGNATURE_DATE_VOD = "Signature_Date_vod__c";
    static FLD_SIGNATURE_VOD = "Signature_vod__c";
    static FLD_STATUS_VOD = "Status_vod__c";
    static FLD_LOCK_VOD = "Lock_vod__c";
    static FLD_MOBILE_ID_VOD = "Mobile_ID_vod__c";
    static FLD_CURRENCY_ISO_CODE = 'CurrencyIsoCode';

    // common values
    static EDIT = "Edit";
    static DELETE = "Delete";
    static SUBMIT_VOD = "Submit_vod";
    static SAVE_VOD = "Save_vod";
    static CLONE_VOD = "Clone_vod";
    static SUBMITTED_VOD = 'Submitted_vod';
    static SAVED_VOD = 'Saved_vod';
    static PUBSUB_RECORD_READY = 'recordReady';
    static PUBSUB_LAYOUT_READY = 'layoutReady';

    static VIEW_LWC = "view-LWC";
    static NEW_LWC = "new-LWC";
    static EDIT_LWC = "edit-LWC";
}