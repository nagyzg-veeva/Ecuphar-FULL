@RestResource(urlMapping='/VeevaWechatAgenda/*')
global with sharing class VeevaWechatAgenda {

    @HttpPost
    global static List<Agenda> getAgendas(){
        RestRequest req = RestContext.request;
        String beginDateString = req.params.get('beginDate');
        String endDateString = req.params.get('endDate');
        Date beginDate = Date.valueOf(beginDateString);
        Date endDate = Date.valueOf(endDateString);

        //result list
        List<Agenda> agendas = new List<Agenda>();
        //query territories
        System.debug('******WeChatAgendaRequest*****'+req.requestBody.toString());
        Map<String,List<String>> territoryMap = (Map<String,List<String>>)Json.deserialize(req.requestBody.toString(), Map<String,List<String>>.class);

        //call list
        Agenda callAgenda = new PersonalEngageMeetingAgenda();
        List<Agenda> callAgendas = callAgenda.execute(beginDate,endDate,territoryMap);
        //group call list
        Agenda groupCallAgenda = new GroupEngageMeetingAgenda();
        List<Agenda> groupCallAgendas = groupCallAgenda.execute(beginDate,endDate,territoryMap);

        agendas.addAll(callAgendas);
        agendas.addAll(groupCallAgendas);
        return agendas;
    }


    global virtual class Agenda {
        global List<String> showColumns = new List<String>();
        global String url;
        global String icon;
        global String color;
        global Date utcDate;
        global DateTime utcDateTime;
        global String isAllDay;
        global String recordTypeName;
        global String ownerId;

        global String status;
        global Boolean ifShow = true;
        global String territoryId;
        global String territoryName;

        // Will be used TOT Agenda for later, special for showing managers agenda
        public List<String> territoryIds = new List<String>();
        public List<String> territoryNames = new List<String>();

        private String datetimeColumn = 'Call_Datetime_vod__c';
        private String dateColumn = 'Call_Date_vod__c';
        private List<String> columns;

        /* *
         * Override in subclass if there is a Wechat Setting to support dynamic columns
         * Return the relative Wechat Settings value, which will use ;; to split each column names
         * If no special setting, logic will only fetch Account_vod__r.Name field
         */
        protected virtual String getWechatColumnSetting(){
            return '';
        }
        protected List<String> getColumns(){
            return columns;
        }
        protected void setColumns(){
            String wechatSettingValue = getWechatColumnSetting();

           if(wechatSettingValue == null || ''.equals(wechatSettingValue)){
                // Only get account name
                this.columns = new List<String>();
                this.columns.add('Account_vod__r.Name');
            }else{
                this.columns = wechatSettingValue.split('\\;\\;') ;
            }
        }
        private void initTerritories(Map<String,List<String>> territoryMap){
            territoryIds = territoryMap.get('ID');
            territoryNames = territoryMap.get('NAME');
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
                    column = column.replace('toLabel(', '').replace(')', '');
                    fieldObject = event.get(column);
                }
                if(fieldObject != null){
                    fieldValue = String.valueOf(fieldObject);
                }
                agenda.showColumns.add(fieldValue);
            }
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
            Object datetimeValue = event.get(datetimeColumn);
            Object dateValue = event.get(dateColumn);

            Date eventDate =  null;
            DateTime eventDateTime = null;
                
            if(datetimeValue!=null && datetimeValue instanceof DateTime){
                agenda.isAllDay = 'false';
                eventDateTime = (DateTime)datetimeValue;
                eventDate = Date.newInstance(eventDateTime.year(), eventDateTime.month(),eventDateTime.day());
            } else {
                agenda.isAllDay = 'true';
                eventDate = (Date)dateValue;
                eventDateTime = Datetime.newInstance(eventDate.year(), eventDate.month(),eventDate.day());
            }

            agenda.utcDate = eventDate;
            agenda.utcDateTime = eventDateTime;
        }
        
        private List<Agenda> getAgendas(String eventUrl,List<String> urlParameters,
                                        String statusColumn,String eventIcon,
                                        List<sObject > events){
            List<Agenda> agendas = new List<Agenda>();

            for(sObject event:events){
                Agenda agenda = new Agenda();
                
                prepareAgendaColumn(event,agenda);
                prepareAgendaDate(event,agenda);                
                agenda.url = String.format(eventUrl,prepareAgendaUrl(event,urlParameters));
                agenda.ownerId = (String)event.get('OwnerId');
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
                return 'status-grey';
            }else if(status.equals('Planned_vod')){
                DateTime thisTime = System.now();
                if(callDateTime>=thisTime){
                    return 'status-grey';
                }else{
                    return 'status-red';
                }
            }else if(status.equals('Saved_vod')){
                return 'status-green';
            }else if(status.equals('Submitted_vod')){
                return 'status-blue';
            }else{
                return 'status-grey';
            }
        }

        global virtual List<Agenda> execute(Date beginDate,Date endDate,Map<String,List<String>> territoryMap){
            setColumns();
            initTerritories(territoryMap);
            
            String callIcon = null;
            String callUrl = 'view/call/detail?callId={0}&recordTypeId={1}';
            String attendeeType = 'Person_Account_vod';

            String soql = ' SELECT {0},Id, RecordTypeId,Account_vod__r.RecordType.Name, OwnerId, Status_vod__c,{1}'
                + ' FROM Call2_vod__c  WHERE  Attendee_Type_vod__c= :attendeeType'
                + ' AND ( {1} >= :beginDate AND {1} <=:endDate)'
                + ' AND Parent_Call_vod__c = null '
                + ' AND Territory_vod__c in :territoryNames '
                + ' ORDER BY {1}';

            List<String> parameters = new List<String>();
            parameters.add(String.join(columns, ','));
            parameters.add(datetimeColumn);
            soql = String.format(soql, parameters);
            List<sObject > events = Database.query(soql);

            return getAgendas(callUrl,new String[]{'Id','RecordTypeId'},'Status_vod__c',callIcon,events);
        }
    }

    // Engage Meeting - Personal
    global class PersonalEngageMeetingAgenda extends Agenda{
        protected override String getWechatColumnSetting(){
            return WeChat_Settings_vod__c.getInstance().CALL_AGENDA_FIELDS_vod__c;
        }

        global override List<Agenda> execute(Date beginDate,Date endDate,Map<String,List<String>> territoryMap){
            super.setColumns();
            super.initTerritories(territoryMap);

            String callIcon = null;
            String callUrl = 'view/call/detail?callId={0}&recordTypeId={1}';
            String attendeeType = 'Person_Account_vod';
            String meetingRecordType = 'Call_vod';

            String soql = 'SELECT {0},Id, RecordTypeId,Account_vod__r.RecordType.Name, OwnerId, Status_vod__c,Call_Datetime_vod__c,Call_Date_vod__c'
                + ' FROM Call2_vod__c WHERE Is_Parent_Call_vod__c = 1 AND Attendee_Type_vod__c= :attendeeType'
                + ' AND Remote_Meeting_vod__r.RecordType.Name=:meetingRecordType'
                + ' AND ( Call_Date_vod__c >= :beginDate AND Call_Date_vod__c <=:endDate)'
                + ' AND Territory_vod__c in :territoryNames '
                + ' ORDER BY Call_Date_vod__c,Call_Datetime_vod__c';

            List<String> parameters = new List<String>();
            parameters.add(String.join(columns, ','));
            soql = String.format(soql, parameters);
            List<sObject > events = Database.query(soql);

            return super.getAgendas(callUrl,new String[]{'Id','RecordTypeId'},'Status_vod__c',callIcon,events);
        }
    }

    // Engage Meeting - Group
    global class GroupEngageMeetingAgenda extends Agenda{
        protected override String getWechatColumnSetting(){
            return WeChat_Settings_vod__c.getInstance().GROUP_CALL_AGENDA_FIELDS_vod__c;
        }

        global override List<Agenda> execute(Date beginDate,Date endDate,Map<String,List<String>> territoryMap){
            super.setColumns();
            super.initTerritories(territoryMap);

            String callIcon = null;
            String callUrl = 'view/call/detail?callId={0}&recordTypeId={1}';
            String attendeeType = 'Group_Account_vod';
            String meetingRecordType = 'Call_vod';
            
            String soql = 'SELECT {0},Id,RecordTypeId,Account_vod__r.RecordType.Name,OwnerId,Status_vod__c,Call_Datetime_vod__c,Call_Date_vod__c'
                + ' FROM Call2_vod__c WHERE Is_Parent_Call_vod__c = 1 AND Attendee_Type_vod__c=:attendeeType'
                + ' AND Remote_Meeting_vod__r.RecordType.Name=:meetingRecordType'
                + ' AND ( Call_Date_vod__c >= :beginDate AND Call_Date_vod__c <=:endDate)'
                + ' AND Territory_vod__c in :territoryNames '
                + ' ORDER BY Call_Date_vod__c,Call_Datetime_vod__c';
                
            List<String> parameters = new List<String>();
            parameters.add(String.join(columns, ','));
            soql = String.format(soql, parameters);
            List<sObject > events = Database.query(soql);
            
            return super.getAgendas(callUrl,new String[]{'Id','RecordTypeId'},'Status_vod__c',callIcon,events);
        }
    }
}