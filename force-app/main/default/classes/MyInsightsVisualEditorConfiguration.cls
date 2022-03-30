/**
 * MyInsightsReportConfiguration defines the default record type names that are available to select.
 * Also, if a object name is specified it will retrieve a list of record types that object supports.
 */
public with sharing class MyInsightsVisualEditorConfiguration {

    private static final Map<String, List<String>> DEFAULT_OBJECT_TO_RECORD_TYPES = new Map<String, List<String>>{
        'Account' => new List<String>{
            'Account_Profile_Override_vod',
            'KOL_Profile_vod',
            'Account_Reports_vod'
        },
        'Account_Plan_vod__c' => new List<String>{
            'Account_Plan_vod',
            'Account_Profile_Override_vod',
            'KOL_Profile_vod',
            'Account_Reports_vod'
        },
        'Inventory_Monitoring_vod__c' => new List<String>{
            'Inventory_Monitoring_vod',
            'Account_Profile_Override_vod',
            'KOL_Profile_vod',
            'Account_Reports_vod'
        },
        'Order_vod__c' => new List<String>{
            'Orders_vod',
            'Account_Profile_Override_vod',
            'KOL_Profile_vod',
            'Account_Reports_vod'
        }
    };

    private static final List<String> DEFAULT_RECORD_TYPES = new List<String>{
        'Territory_Insights_Default_vod',
        'Territory_Insights_vod'
    };

    private final List<String> defaultMyInsightsRecordTypes;
    private final Map<String, List<String>> objectToRecordTypeName;

    public MyInsightsVisualEditorConfiguration() {
        this.defaultMyInsightsRecordTypes = new List<String>(DEFAULT_RECORD_TYPES);
        this.objectToRecordTypeName = initializeObjectToRecordType();
    }

    public List<String> getDefaultRecordTypeNames() {
        return defaultMyInsightsRecordTypes;
    }

    public List<String> getRecordTypesNamesFor(String objectName) {
        return objectToRecordTypeName.get(objectName);
    }

    /**
     * Creates a new Map of Object Names to a List of Record Type Names.
     * Adds DEFAULT_RECORD_TYPES to all Object Names.
     * Also, removes duplicates from the List of Record Type Names.
     */
    private static Map<String, List<String>> initializeObjectToRecordType() {
        Map<String, List<String>> objectToRecordTypeName = new Map<String, List<String>>();
        for(String objectName : DEFAULT_OBJECT_TO_RECORD_TYPES.keySet()) {
            Set<String> recordTypesToForObjectType = new Set<String>(DEFAULT_RECORD_TYPES);
            recordTypesToForObjectType.addAll(DEFAULT_OBJECT_TO_RECORD_TYPES.get(objectName));
            objectToRecordTypeName.put(objectName, new List<String>(recordTypesToForObjectType));
        }
        return objectToRecordTypeName;
    }
}