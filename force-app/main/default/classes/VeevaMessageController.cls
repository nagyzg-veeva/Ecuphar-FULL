public without sharing class VeevaMessageController {

    @TestVisible private static String DEFAULT_LANGUAGE = 'en_US';

    @AuraEnabled (cacheable = true)
    public static String getMsgWithDefault(String key, String category, String defaultMessage) {
        Message_vod__c message = getMsg(key, category, UserInfo.getLanguage());
        if (message == null) {
            message = getMsg(key, category, DEFAULT_LANGUAGE);
        }
        if (message == null) {
            return defaultMessage;
        }
        return message.Text_vod__c;
    }

    @AuraEnabled (cacheable = true)
     public static Map<String, String> getVeevaMessages(List<String> categories) {
        Set<String> uniqueCats = new Set<String>(categories);
        Set<String> languages = new Set<String>{DEFAULT_LANGUAGE, UserInfo.getLanguage()};
        return getMsgMap(uniqueCats, languages);
    }

    private static Map<String, String> getMsgMap(Set<String> categories, Set<String> languages) {
        Map<String, String> msgMap = new Map<String, String>();

        Set<String> catsToQuery = new Set<String>();
        Map<String, String> msgToSettingVal = new Map<String, String>();
        Map<String, String> msgToSettingMsg = new Map<String, String>();
        populateMsgCollections(categories, catsToQuery, msgToSettingVal, msgToSettingMsg);

        try {
            for (Message_vod__c message : [
                SELECT Name, Category_vod__c, Text_vod__c, Language_vod__c
                FROM Message_vod__c
                WHERE Category_vod__c IN :catsToQuery
                AND Language_vod__c IN :languages
                AND Active_vod__c = true
            ]) {
                String msgKey = message.Category_vod__c + ';;' + message.Name;
                if (!msgMap.containsKey(msgKey) || message.Language_vod__c != DEFAULT_LANGUAGE) {
                    String value = message.Text_vod__c != null ? message.Text_vod__c : '';
                    msgMap.put(msgKey, value);
                }
            }

            msgMap.putAll(msgToSettingVal);
            overwriteWithSettingMsgs(msgMap, msgToSettingMsg);
        } catch (System.QueryException e) {
            System.debug('Could not get message map: ' + e);
        }

        return msgMap;
    }

    private static void populateMsgCollections(Set<String> srcCats, Set<String> catsToQuery, Map<String, String> msgToSettingVal, Map<String, String> msgToSettingMsg) {
        catsToQuery.addAll(srcCats);
        Veeva_Settings_vod__c settings = VeevaSettings.getVeevaSettings();
        for (String cat : srcCats) {
            if (LEGACY_MESSAGE_MAP.containsKey(cat)) {
                for (String msgKey : LEGACY_MESSAGE_MAP.get(cat).keySet()) {
                    String settingsFld = LEGACY_MESSAGE_MAP.get(cat).get(msgKey);
                    String settingVal = String.valueOf(settings.get(settingsFld));
                    if (String.isNotBlank(settingVal)) {
                        List<String> settingKeyAndCat = settingVal.split(';;');
                        String catAndKey = cat + ';;' + msgKey;
                        if (settingKeyAndCat.size() == 2) {
                            catsToQuery.add(settingKeyAndCat[1]);
                            String settingCatAndKey = settingKeyAndCat[1] + ';;' + settingKeyAndCat[0];
                            if (settingCatAndKey != catAndKey) {
                                msgToSettingMsg.put(catAndKey, settingCatAndKey);
                            }
                        } else {
                            msgToSettingVal.put(catAndKey, settingVal);
                        }
                    }
                }
            }
        }
    }

    private static void overwriteWithSettingMsgs(Map<String, String> msgMap, Map<String, String> msgToSettingMsg) {
        for (String origMsgKey : msgToSettingMsg.keySet()) {
            String settingMsgKey = msgToSettingMsg.get(origMsgKey);
            if (settingMsgKey != null) {
                String settingMsgVal = msgMap.containsKey(settingMsgKey) ? msgMap.get(settingMsgKey) : '';
                msgMap.put(origMsgKey, settingMsgVal);
            }
        }
    }

    private static Message_vod__c getMsg(String key, String category, String language) {
        List<String> keyAndCategory = getMessageParams(key, category);
        String msgKey = keyAndCategory[0];
        String msgCat = keyAndCategory[1];
        
        try {
            return [Select Text_vod__c From Message_vod__c
                WHERE NAME = :msgKey
                AND Language_vod__c = :language
                AND Category_vod__c = :msgCat
                AND Active_vod__c = true LIMIT 1];
        }
        catch (System.QueryException e) {
            return null;
        }
    }

    private static List<String> getMessageParams(String key, String category) {
        String keyAndCategory = key + ';;' + category;

        if (LEGACY_MESSAGE_MAP.containsKey(category) && LEGACY_MESSAGE_MAP.get(category).containsKey(key)) {
            String settingsFld = LEGACY_MESSAGE_MAP.get(category).get(key);
            Veeva_Settings_vod__c settings = VeevaSettings.getVeevaSettings();
            if (settings != null) {
                String keyAndCatSetting = (String)settings.get(settingsFld);
                if (String.isNotBlank(keyAndCatSetting)) {
                    List<String> keyCatArr = keyAndCatSetting.split(';;');
                    if (keyCatArr.size() == 2) {
                        keyAndCategory = keyAndCatSetting;
                    }
                }
            }
        }

        return keyAndCategory.split(';;');
    }

    //this map is here for supporting old Veeva Message/Veeva Setting functionality
    //because this is functionality that is still used by customers 
    //DO NOT EXTEND/ADD TO THIS MAP
    private static Map<String, Map<String, String>> LEGACY_MESSAGE_MAP = new Map<String, Map<String, String>>{
        'Account' => new Map<String, String>{
            'ENABLE_PARENT_WIZARD_OPT_ACCT_TYPES' => 'ENABLE_PARENT_WIZARD_OPT_ACCT_TYPES_vod__c',
            'NEW_ACCOUNT_TYPES_DISABLE_LICENSE_INFO' => 'NEW_ACC_TYPES_DISABLE_LICENSE_INFO_vod__c'
        },
        'Analytics' => new Map<String, String>{
            'DISABLE_ALL_MARKETS_IN_ANALYTICS' => 'DISABLE_ALL_MARKETS_IN_ANALYTICS_vod__c',
            'ENABLE_BRICK_VINSIGHTS' => 'ENABLE_BRICK_VINSIGHTS_vod__c',
            'ENABLE_CHILD_ACCOUNTS_IN_ANALYTICS' => 'ENABLE_CHILD_ACCOUNTS_IN_ANALYTICS_vod__c',
            'ENABLE_VINSIGHTS_FILTERS_CONFIG' => 'ENABLE_VINSIGHTS_FILTERS_CONFIG_vod__c',
            'MultiselectLimitEnforced' => 'MultiselectLimitEnforced_vod__c'
        },
        'CALENDAR' => new Map<String, String>{
            'ENABLE_NEW_CALENDAR_ONLINE' => 'ENABLE_NEW_CALENDAR_ONLINE_vod__c',
            'Enable_Group_Call_Attendee_Display' => 'Enable_Group_Call_Attendee_Display_vod__c'
        },
        'CONTRACTS' => new Map<String, String>{
            'DISCLAIMER' => 'CONTRACT_DISCLAIMER_vod__c'
        },
        'CallReport' => new Map<String, String>{
            'CALL_SUBMISSION_MONTHLY_WINDOW' => 'CALL_SUBMISSION_MONTHLY_WINDOW_vod__c',
            'DISABLE_SIGN_BUTTON' => 'DISABLE_SIGN_BUTTON_vod__c',
            'DISCLAIMER' => 'DISCLAIMER_vod__c',
            'DISCLAIMER_DETAIL_ONLY' => 'DISCLAIMER_DETAIL_ONLY_vod__c',
            'DISCLAIMER_FONT_SIZE' => 'DISCLAIMER_FONT_SIZE_vod__c',
            'EDetail' => 'EDetail_vod__c',
            'ENABLE_DUAL_LICENSE_CHECK' => 'ENABLE_DUAL_LICENSE_CHECK_vod__c',
            'ENABLE_EXPIRATION_FILTER' => 'ENABLE_EXPIRATION_FILTER_vod__c',
            'ENABLE_SAMPLE_CARD_LICENSE_CHECK' => 'ENABLE_SAMPLE_CARD_LICENSE_CHECK_vod__c',
            'MAXIMUM_SAMPLES' => 'MAXIMUM_SAMPLES_vod__c',
            'MAX_ATTACH_SIZE' => 'MAX_ATTACH_SIZE_vod__c',
            'MAX_CALL_AGE' => 'MAX_CALL_AGE_vod__c',
            'PaperDetail' => 'PaperDetail_vod__c',
            'SAMPLE_CARD_REG_EXPRESS' => 'SAMPLE_CARD_REG_EXPRESS_vod__c',
            'SAMPLE_SEND_CARD_REG_EXPRESS' => 'SAMPLE_SEND_CARD_REG_EXPRESS_vod__c'
        },
        'Callplan' => new Map<String, String>{
            'Enable_Copy_To_Call_Cycle_Button' => 'Enable_Copy_To_Call_Cycle_Button_vod__c'
        },
        'Common' => new Map<String, String>{
            'ACCOUNT_RECORD_TYPE_ICON_MAP' => 'ACCOUNT_RECORD_TYPE_ICON_MAP_vod__c',
            'ALLOWED_CALL_RECORD_TYPES' => 'ALLOWED_CALL_RECORD_TYPES_vod__c',
            'CACHE_TIMEOUT' => 'CACHE_TIMEOUT_vod__c',
            'DEFAULT_CALL_RECORD_TYPE' => 'DEFAULT_CALL_RECORD_TYPE_vod__c'
        },
        'MEDICAL_INQUIRY' => new Map<String, String>{
            'DISCLAIMER' => 'DISCLAIMER_MI_vod__c',
            'RECEIPT_TEMPLATE' => 'RECEIPT_TEMPLATE_vod__c'
        },
        'MOBILE' => new Map<String, String>{
            'MOBILE_DESCRIBES' => 'MOBILE_DESCRIBES_vod__c'
        },
        'MOBILE_CALL_CUSTOM_FIELD' => new Map<String, String>{
            'DEFAULT' => 'DEFAULT_vod__c'
        },
        'MOBILE_CONFIG' => new Map<String, String>{
            'AUTO_SYNC' => 'AUTO_SYNC_vod__c',
            'TIMEOUT' => 'TIMEOUT_vod__c'
        },
        'MyAccounts' => new Map<String, String>{
            'DISABLE_ALL_ACCOUNTS' => 'DISABLE_ALL_ACCOUNTS_vod__c',
            'DISABLE_MASS_UPDATE' => 'DISABLE_MASS_UPDATE_vod__c',
            'DISABLE_RM_QUERY' => 'DISABLE_RM_QUERY_vod__c',
            'MAX_ACCT_THRESHOLD' => 'MAX_ACCT_THRESHOLD_vod__c',
            'NEW_ACCOUNT_WIZARD' => 'NEW_ACCOUNT_WIZARD_vod__c'
        },
        'ORDER_MANAGEMENT' => new Map<String, String>{
            'COMPANY_FIELDS_FOR_PRINT' => 'COMPANY_FIELDS_FOR_PRINT_vod__c',
            'Disable_Rebate_Mixing_vod__c' => 'Disable_Rebate_Mixing_vod__c',
            'Enable_Simple_Rebate_Addition_vod__c' => 'Enable_Simple_Rebate_Addition_vod__c',
            'Kit_Components_Fixed' => 'Kit_Components_Fixed_vod__c'
        },
        'ProductPlan' => new Map<String, String>{
            'ENABLE_TACTIC_LIST' => 'ENABLE_TACTIC_LIST_vod__c'
        },
        'REFRESH_HTML' => new Map<String, String>{
            'HTML_LIST' => 'HTML_LIST_vod__c',
            'OBJECT_LIST' => 'OBJECT_LIST_vod__c'
        },
        'SAMPLES_MGMT' => new Map<String, String>{
            'DISABLE_SAMPLE_RECEIPT_DEFAULT' => 'DISABLE_SAMPLE_RECEIPT_DEFAULT_vod__c',
            'ENABLE_INVENTORY_WORKSHEET' => 'ENABLE_INVENTORY_WORKSHEET_vod__c',
            'ENABLE_MYSAMPLES_LOGIN' => 'ENABLE_MYSAMPLES_LOGIN_vod__c',
            'ENABLE_NEG_SAMPLE_INDICATOR' => 'ENABLE_NEG_SAMPLE_INDICATOR_vod__c',
            'ENABLE_RECEIPT_ACTIVATION' => 'ENABLE_RECEIPT_ACTIVATION_vod__c',
            'ENABLE_TABLET_MYSAMPLES' => 'ENABLE_TABLET_MYSAMPLES_vod__c',
            'ENABLE_TRANSFER_WORKSHEET' => 'ENABLE_TRANSFER_WORKSHEET_vod__c',
            'MAX_SAMPLE_LINES' => 'MAX_SAMPLE_LINES_vod__c',
            'MY_SAMPLES_LAYOUT_EDIT' => 'MY_SAMPLES_LAYOUT_EDIT_vod__c',
            'MY_SAMPLES_LAYOUT_VIEW' => 'MY_SAMPLES_LAYOUT_VIEW_vod__c'
        },
        'SampleReceipt' => new Map<String, String>{
            'HTML_TEMPLATE' => 'HTML_TEMPLATE_vod__c'
        }
    };
}