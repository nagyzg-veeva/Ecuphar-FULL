public class VOD_VEEVA_MESSAGE {

    public VOD_VEEVA_MESSAGE(ApexPages.StandardController controller) {
    }

    private static final String DELIMETER = ';;';

    public String methodName {get; set;}

    public Account currAccount{
      get;
      set {currAccount=detailedAccount(value);}
    }

    private Account detailedAccount(Account value) {
      Account detailedAccount = [SELECT ID, IsPersonAccount, PDRP_Opt_Out_Date_vod__c, PDRP_Opt_Out_vod__c FROM Account WHERE Id=:value.Id];
      return detailedAccount;
    }

    public static Map<String, String> getOptOutVewMessages() {
        String userLang = UserInfo.getLanguage();
        List<Message_vod__c> messages = new List<Message_vod__c>();
        Map<String, String> localOptOutVewMessages = new Map<String, String>();
        try {
          messages = [SELECT Name, Text_vod__c FROM Message_vod__c WHERE Language_vod__c= :userLang AND Category_vod__c='Analytics' AND Name IN ('OptOut','View')];
        } catch (System.QueryException ignored) {
        }

        for (Message_vod__c message : messages) {
            localOptOutVewMessages.put(message.Name, message.Text_vod__c);
        }

        return localOptOutVewMessages;
    }

    public static Map<String, String> getVeevaMessages(List<String> keys) {
        String userLang = UserInfo.getLanguage();

        List<String> whereClauses = new List<String>();
        for (String key : keys) {
            String[] splitKey = key.split(DELIMETER, 2);

            String pCategory = splitKey[0];
            String pKey = splitKey[1];

            // We want "(Name = :pKey AND Language_vod__c = :userLang AND Category_vod__c = :pCategory
            //           AND Active_vod__c = true)
            String whereClause = '(Name=' + '\''+ pKey + '\''
                                 + ' AND Language_vod__c=' + '\'' + userLang + '\''
                                 + ' AND Category_vod__c=' + '\''+ pCategory + '\''
                                  + ' AND Active_vod__c=true)';

            whereClauses.add(whereClause);
        }


        List<Message_vod__c> messages = new List<Message_vod__c>();
        try {
            messages = Database.query('SELECT Category_vod__c, Name, Text_vod__c '
                    + ' FROM Message_vod__c WHERE ' + String.join(whereClauses, ' OR '));
        } catch (System.QueryException ignored) {
        }

        Map<String, String> veevaMessages = new Map<String, String>();
        for (Message_vod__c message : messages) {
            String pCategory = message.Category_vod__c;

            veevaMessages.put(message.Category_vod__c + DELIMETER + message.Name, message.Text_vod__c);
        }

        return veevaMessages;
    }


    public static String getMsgWithDefault(String pKey, String pCategory, String defaultMessage) {
        String errorMessage = getMsg(pKey, pCategory);

        // Return the default if we can't find the message.
        if (String.isEmpty(errorMessage)) {
            return defaultMessage;
        }

        return errorMessage;
    }

    private static String getMsg(String pKey, String pCategory) {

        String userLang = UserInfo.getLanguage();
        Message_vod__c msg = null;
        try {
            msg = [Select Text_vod__c From Message_vod__c
            WHERE NAME = :pKey
            AND Language_vod__c = :userLang
            AND Category_vod__c = :pCategory
            AND Active_vod__c = true LIMIT 1];
        } catch (System.QueryException e) {
        }


        if (msg == null) {
            try {
                msg = [Select Text_vod__c From Message_vod__c
                WHERE NAME = :pKey
                AND Language_vod__c = 'en_US'
                AND Category_vod__c = :pCategory
                AND Active_vod__c = true LIMIT 1];
            }  catch (System.QueryException e) {
            }

        }
        String value ='';
        if (msg != null) {
            value = msg.Text_vod__c;
        }
        return value;

    }

    public static String getWeChatSettingsMsg(String settingName) {
        String message = '';
        WeChat_Settings_vod__c settings = WeChat_Settings_vod__c.getInstance();
        if (settings != null) {
            String settingValue = (String) settings.get(settingName);
            if (String.isNotBlank(settingValue)) {
                String[] messagePointer = settingValue.split(DELIMETER);
                if (messagePointer.size() == 2) {
                    message = getMsg(messagePointer[0], messagePointer[1]);
                }
                if (String.isBlank(message)) {
                    message = settingValue;
                }
            }
        }
        return message;
    }

}