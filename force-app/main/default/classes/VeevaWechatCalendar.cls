@RestResource(urlMapping='/VeevaWechatCalendar/*')
global with sharing class VeevaWechatCalendar {
    @HttpPost
    global static List<Agenda> getCalendars(){
        RestRequest req = RestContext.request;
        String beginDateString = req.params.get('beginDate');
        String endDateString = req.params.get('endDate');
        String userId = req.params.get('userId');
        Date beginDate = Date.valueOf(beginDateString);
        Date endDate = Date.valueOf(endDateString);
        
        //result list
        List<Agenda> agendas = new List<Agenda>();
        
        if (!validateUser(userId)) {
            return agendas;
        }
        
        //call list
        Agenda callAgenda = new CallAgenda();
        List<Agenda> callAgendas = callAgenda.execute(beginDate,endDate,userId);
        
        //tot list
        Agenda totAgenda = new TOTAgenda();
        List<Agenda> totAgendas = totAgenda.execute(beginDate,endDate,userId);

        agendas.addAll(callAgendas);
        agendas.addAll(totAgendas);

        //medical event list
        Boolean scheduleMedicalEventEnabled = Veeva_Settings_vod__c.getInstance().ENABLE_SCHEDULE_MEDICAL_EVENT_vod__c;
        if (scheduleMedicalEventEnabled) {
            Agenda meAgenda = new MedicalEventAgenda();
            List<Agenda> meAgendas = meAgenda.execute(beginDate, endDate, userId);
            agendas.addAll(meAgendas);
        }

        return agendas;
    }
    
    private static boolean validateUser(String userId){
        if(String.isEmpty(userId)){
            return false;
        }
         
        String currentUserId = UserInfo.getUserId();
        if(currentUserId.equalsIgnoreCase(userId)) {
            return true;
        }
        
        TerritoryManagement territoryManagement = TerritoryManagementFactory.getInstance();

        Set<Id> paramUserTerritories = territoryManagement.getUserTerritories(userId);
        Set<Id> currentUserTerritories = territoryManagement.getUserTerritories(currentUserId);
        Set<Id> currentUserTerritoriesCopySet = new Set<Id>(currentUserTerritories);
        
        currentUserTerritories.retainAll(paramUserTerritories);
        if (currentUserTerritories.size() > 0) {
            return true;
        }
        
        Set<Id> userParentTerritories = territoryManagement.getParentIdsByTerritorySet(paramUserTerritories);
        currentUserTerritoriesCopySet.retainAll(userParentTerritories);
        
        return currentUserTerritoriesCopySet.size() > 0;
    }
    
    global virtual class Agenda {
        global List<String> showColumns = new List<String>();
        global String id;
        global String url;
        global String icon;
        global String color;
        global Date utcDate;
        global DateTime utcDateTime;
        global DateTime endUtcDateTime;
        global String isAllDay;
        global String recordTypeName;
        global String ownerId;
        global String title;
        global String subtitle;
        global String totTime;
        global String totStartTime;
        global String totTimeLabel;
        global String totHoursOff;

        global String status;
        global Boolean ifShow = true;
        global String territoryId;
        global String territoryName;
        global String objectName;

        private String datetimeColumn;
        private String dateColumn;
        private List<String> columns;
        private List<String> recordTypeNames;        

        /* *
         * Override in subclass if there is a Wechat Setting to support dynamic columns
         * Return the relative Wechat Settings value, which will use ;; to split each column names and will use || to get datetime column name
         * If no special setting, logic will only return empty string
         */
        protected virtual String getWechatColumnSetting(){
            return '';
        }
        protected List<String> getColumns(){
            return columns;
        }
        
        protected void setColumns(){
            String wechatSettingValue = getWechatColumnSetting();
            
            List<String> settings = wechatSettingValue.split('\\|\\|') ;
            String columnValue = settings.get(0);
            if (settings.size() > 1) {
                this.datetimeColumn = settings.get(1);
            } else {
                this.datetimeColumn = null;
            }
            this.columns = columnValue.split('\\;\\;') ;
        }

        private List<String> getPrefix(String column){
            List<String> columns = column.split('\\.');
            if(columns.size() <=1){
                 columns = null;
            }
            return columns;
        }

        private void prepareAgendaColumn(sObject event,Agenda agenda){
            for(String column:columns){
                Object fieldObject = null;
                String fieldValue = '';
                
                List<String> prefixes = getPrefix(column);
                if(prefixes != null){
                    if(event.getSObject(prefixes[0]) != null){
                        fieldObject = event.getSObject(prefixes[0]).get(prefixes[1]);
                    }else{
                        if(prefixes[0].equals('Account_vod__r')){
                            agenda.ifShow = false;
                        }
                    }
                }else{
                    String alias = getAliasIfHave(column);
                    if (alias != null) {
                        column = alias; 
                    }else {
                        column = column.replace('toLabel(', '').replace(')', '');
                    }
                    fieldObject = event.get(column);
                }
                if(fieldObject != null){
                    fieldValue = String.valueOf(fieldObject);
                }
                agenda.showColumns.add(fieldValue);
            }
        }
        
        private String getAliasIfHave(String columnName) {
            String alias = null;
            if (columnName != null) {
                String[] partsBySpace = columnName.split(' ');
                if (partsBySpace.size() > 1) {
                    alias = partsBySpace[1];
                }
            }
            return alias;
        }
        
        private List<String> prepareAgendaUrl(sObject event,List<String> urlParameters){
            List<String> urlValues = new List<String>();
                
            for(String column:urlParameters){
                Object fieldObject = null;
                String fieldValue = '';
                List<String> prefixes = getPrefix(column);
                if(prefixes != null){
                    if(event.getSObject(prefixes[0]) != null){
                        fieldObject = event.getSObject(prefixes[0]).get(prefixes[1]);
                    }
                }else if(column == 'orgId'){
                    fieldObject = UserInfo.getOrganizationId();
                }else{
                    fieldObject = event.get(column);
                }
                         
                if(fieldObject != null){
                    fieldValue = String.valueOf(fieldObject);
                }
                urlValues.add(fieldValue);
            }
                
            return urlValues;        
        }
        
        private void prepareAgendaDate(sObject event,Agenda agenda){
            if (datetimeColumn != null) {
                Object datetimeValue = event.get(datetimeColumn);
                Date eventDate =  null;
                DateTime eventDateTime = null;
            
                if(datetimeValue instanceof Date){
                    agenda.isAllDay = 'true';
                    eventDate = (Date)datetimeValue;
                    eventDateTime = Datetime.newInstance(eventDate.year(), eventDate.month(),eventDate.day());
                }else if(datetimeValue instanceof DateTime){
                    agenda.isAllDay = 'false';
                    eventDateTime = (DateTime)datetimeValue;
                    eventDate = Date.newInstance(eventDateTime.year(), eventDateTime.month(),eventDateTime.day());
                }

                agenda.utcDate = eventDate;
                agenda.utcDateTime = eventDateTime;
            }
        }
        
        private List<Agenda> getAgendas(String eventUrl,List<String> urlParameters,
                                        String statusColumn,String eventIcon,
                                        List<sObject > events, String objectName){
            List<Agenda> agendas = new List<Agenda>();

            for(sObject event:events){
                Agenda agenda = new Agenda();
                
                prepareAgendaColumn(event,agenda);
                prepareAgendaDate(event,agenda);
                agenda.id = (String)event.get('Id');
                agenda.url = String.format(eventUrl,prepareAgendaUrl(event,urlParameters));
                agenda.ownerId = (String)event.get('OwnerId');
                agenda.objectName = objectName;
                if(statusColumn!=null && !statusColumn.equals('')){
                    agenda.status = (String)event.get(statusColumn);
                }
                // Set icon
                agenda.icon = eventIcon;
                if(eventIcon == null){
                    if(event.getSObject('Account_vod__r') != null
                            && event.getSObject('Account_vod__r').getSObject('RecordType') != null){
                        agenda.recordTypeName = (String)event.getSObject('Account_vod__r').getSObject('RecordType').get('Name');
                    }
                }else if(eventIcon.contains('ui-icon-call')){
                    Integer duration = Integer.valueOf(event.get('Duration_vod__c'));
                    if(duration != null && duration > 30){
                        agenda.endUtcDateTime = agenda.utcDateTime.addMinutes(duration);
                    }else{
                        agenda.endUtcDateTime = agenda.utcDateTime.addMinutes(30);
                    }

                    if(event.getSObject('RecordType') != null
                        && event.getSObject('RecordType').get('CallRecordTypeLabel') != null){
                        agenda.recordTypeName = (String) event.getSObject('RecordType').get('CallRecordTypeLabel');
                    }
                }else if(eventIcon.contains('ui-icon-tot')){
                    agenda.totTime = (String)event.get('Time_vod__c');
                    agenda.totStartTime = (String)event.get('Start_Time_vod__c');                    
                    agenda.totTimeLabel = (String)event.get('TimeLabel');                  
                    agenda.totHoursOff = (String)event.get('Hours_off_vod__c');                  
                }else if(eventIcon.contains('ui-icon-me')){
                    if(event.get('Start_Time_vod__c') != null && event.get('End_Time_vod__c') != null) {
                        agenda.utcDateTime = (DateTime)event.get('Start_Time_vod__c');
                        agenda.endUtcDateTime = (DateTime)event.get('End_Time_vod__c');
                    }else if(event.get('Start_Date_vod__c') != null && event.get('End_Date_vod__c') != null) {
                        agenda.utcDateTime = (Date)event.get('Start_Date_vod__c');
                        agenda.endUtcDateTime = (Date)event.get('End_Date_vod__c');
                    }
                    sObject meRecordType = event.getSObject('RecordType');
                    if(meRecordType != null) {                       
                        agenda.recordTypeName = (String) meRecordType.get('Name');
                    }
                }
                //set color
                if(agenda.status != null && agenda.ifShow == true){
                    agenda.color = getColor(agenda.status,agenda.utcDateTime);
                }

                agendas.add(agenda);
            }
            
            return agendas;
        }
        
        protected String getColor(String status, DateTime callDateTime) {
            if(status == null){
                return 'status-other-grey';
            }else if(status.equals('Planned_vod')){
                DateTime thisTime = System.now();
                if(callDateTime>=thisTime){
                    return 'status-four-mediumgreen';
                }else{
                    return 'status-three-pink';
                }
            }else if(status.equals('Saved_vod')){
                DateTime thisTime = System.now();
                if(callDateTime>=thisTime){
                    return 'status-five-darkgreen';
                }else{
                    return 'status-one-red';
                }
            }else if(status.equals('Submitted_vod')){
                return 'status-two-green';
            }else{
                return 'status-other-grey';
            }
        }

        private virtual List<Agenda> execute(Date beginDate,Date endDate,String userId){
            setColumns();
            
            String callIcon = null;
            String callUrl = 'view/Call2_vod__c/detail?callId={0}&recordTypeId={1}';
            String ownerId = userId;
            String objectName = 'Call2_vod__c';

            String soql = ' SELECT {0},Id, RecordTypeId, Account_vod__r.RecordType.Name, OwnerId, Status_vod__c,{1}'
                + ' FROM Call2_vod__c  WHERE  ownerId= :ownerId'
                + ' AND ( {1} >= :beginDate AND {1} <=:endDate)'
                + ' AND Parent_Call_vod__c = null '
                + ' ORDER BY {1}';

            List<String> parameters = new List<String>();
            parameters.add(String.join(columns, ','));
            parameters.add(datetimeColumn);
            soql = String.format(soql, parameters);
            List<sObject > events = Database.query(soql);

            return getAgendas(callUrl,new String[]{'Id','RecordTypeId'},'Status_vod__c',callIcon,events,objectName);
        }
    }

    // Call Calendar
    private class CallAgenda extends Agenda{
        protected override String getWechatColumnSetting(){
            return 'Account_vod__r.Formatted_Name_vod__c;;Call_Datetime_vod__c;;Duration_vod__c;;Account_vod__r.Account_Identifier_vod__c||Call_Datetime_vod__c';
        }

        private override List<Agenda> execute(Date beginDate,Date endDate,String userId){
            super.setColumns();

            String callIcon = 'ui-icon-call';
            String callUrl = 'view/Call2_vod__c/{0}';
            String attendeeType = 'Person_Account_vod';
            String meetingRecordType = 'Call_vod';
            String objectName = 'Call2_vod__c';
            String ownerId = userId;
            Boolean isPersonAccount = true;
            
            List<String> recordTypes = new List<String>();
            
            String professionalRecordTypeNames = WeChat_Settings_vod__c.getInstance().PROFESSIONAL_RECORD_TYPES_vod__c;
            if(String.isNotBlank(professionalRecordTypeNames)) {
                List<String> professionalRecordTypes = professionalRecordTypeNames.split(';;');
                recordTypes.addAll(professionalRecordTypes);
            }
            
            String hospitalRecordTypeNames = WeChat_Settings_vod__c.getInstance().HOSPITAL_RECORD_TYPES_vod__c;
            if(String.isNotBlank(hospitalRecordTypeNames)) {
                List<String> hospitalRecordTypes = hospitalRecordTypeNames.split(';;');
                recordTypes.addAll(hospitalRecordTypes);
            }

            String soql = 'SELECT {0},Id, RecordTypeId, OwnerId, Status_vod__c,Call_Date_vod__c,toLabel(RecordType.Name) CallRecordTypeLabel'
                + ' FROM Call2_vod__c WHERE Status_vod__c != null'
                + ' AND (Call_Date_vod__c >= :beginDate AND Call_Date_vod__c <=:endDate)'
                + ' AND OwnerId = :ownerId'
                + ' AND Parent_Call_vod__c = null'
                + ' AND Account_vod__r.RecordType.DeveloperName in :recordTypes'
                + ' ORDER BY Call_Date_vod__c,Call_Datetime_vod__c';

            List<String> parameters = new List<String>();
            parameters.add(String.join(columns, ','));
            soql = String.format(soql, parameters);
            List<sObject > events = Database.query(soql);

            return super.getAgendas(callUrl,new String[]{'Id'},'Status_vod__c',callIcon,events,objectName);
        }
    }
    
    // Time Off Territory Agenda
    private class TOTAgenda extends Agenda{
        protected override String getWechatColumnSetting(){
            return 'toLabel(Reason_vod__c);;Time_vod__c;;toLabel(Time_vod__c) TimeLabel;;Start_Time_vod__c;;Hours_off_vod__c||Date_vod__c';
        }
        
        private override List<Agenda> execute(Date beginDate,Date endDate,String userId){
            super.setColumns();

            String callIcon = 'ui-icon-tot';
            String callUrl = 'view/Time_Off_Territory_vod__c/{0}';
            String ownerId = userId;
            String objectName = 'Time_Off_Territory_vod__c';
            
            String soql = 'SELECT {0}, Id, OwnerId, Status_vod__c, Date_vod__c'
                + ' FROM Time_Off_Territory_vod__c WHERE '
                + ' (Date_vod__c >= :beginDate AND Date_vod__c <=:endDate)'
                + ' AND OwnerId = :ownerId'
                + ' ORDER BY Date_vod__c ';

            List<String> parameters = new List<String>();
            parameters.add(String.join(columns, ','));
            soql = String.format(soql, parameters);
            List<sObject > events = Database.query(soql);

            return super.getAgendas(callUrl,new String[]{'Id'},'Status_vod__c',callIcon,events,objectName);
        }
    }

    // Medical Event Agenda
    private class MedicalEventAgenda extends Agenda{
        protected override String getWechatColumnSetting(){
            return 'Name;;EM_Event_vod__c';
        }
        
        private override List<Agenda> execute(Date beginDate,Date endDate,String userId){
            super.setColumns();

            String meIcon = 'ui-icon-me';
            String meUrl = 'view/Medical_Event_vod__c/{0}';
            String ownerId = userId;
            String objectName = 'Medical_Event_vod__c';
            String statusList = 'Rejected_vod';
            
            String soql = 'SELECT {0}, Id, toLabel(RecordType.Name), OwnerId, Status_vod__c, Start_Date_vod__c, Start_Time_vod__c, End_Date_vod__c, End_Time_vod__c'
                + ' FROM Medical_Event_vod__c WHERE '
                + ' ((Start_Time_vod__c <= :endDate AND End_Time_vod__c >= :beginDate) OR (Start_Date_vod__c <= :endDate AND End_Date_vod__c >= :beginDate))'
                + ' AND OwnerId = :ownerId'
                + ' AND Status_vod__c not in (:statusList) '
                + ' ORDER BY Start_Time_vod__c, Start_Date_vod__c';

            List<String> parameters = new List<String>();
            parameters.add(String.join(columns, ','));
            soql = String.format(soql, parameters);
            List<sObject > events = Database.query(soql);

            return super.getAgendas(meUrl, new String[]{'Id'}, 'Status_vod__c', meIcon, events, objectName);
        }
    }
}