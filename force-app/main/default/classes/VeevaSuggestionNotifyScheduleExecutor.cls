public class VeevaSuggestionNotifyScheduleExecutor implements VeevaSuggestionNotifySchedule.IScheduleExecutor {
    
    public void execute(SchedulableContext ctx) {
        //Callout method must be declared as 'static' with annotated 'future' when triggered by schedule job.
        VeevaSuggestionNotifyScheduleExecutor.executeInternal(ctx.getTriggerId());
    }
    
    @future(callout=true)
    static void executeInternal(String jobId) {
        String orgId = [SELECT Id FROM Organization LIMIT 1].Id;
        CronTrigger ct = [SELECT Id, PreviousFireTime FROM CronTrigger WHERE Id = :jobId];
        
        
        String domainUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c;
        if(domainUrl == null || ''.equals(domainUrl)){
            //Constructor NoDataFoundException(message) is not defined.
            NoDataFoundException ndfe = new NoDataFoundException();
			ndfe.setMessage('Domain URL for wechat crm service has not been configured');
    		throw ndfe;
        }
        
        VeevaSuggestionNotifyScheduleExecutor.processData(orgId, domainUrl, ct.PreviousFireTime, getLastCompletedTime());
    }
    
    public static DateTime getLastCompletedTime(){
        String executorClassName = 'VeevaSuggestionNotifyScheduleExecutor';
        String executorClassId = [SELECT Id FROM ApexClass WHERE Name= :executorClassName LIMIT 1].Id;
        List<AsyncApexJob> hisList = [SELECT Id, CreatedDate FROM AsyncApexJob WHERE ApexClassId= :executorClassId AND Status='Completed' ORDER BY CreatedDate DESC LIMIT 1];
        if(hisList == null || hisList.size() == 0){
        	return null;
        }else{
            return hisList[0].CreatedDate;
        }
    }
    
    public static void processData(String orgId, String domainUrl, DateTime runTime, DateTime lastRunTime) {
        List<VeevaWechatSuggestionSummary.UserSuggestionSummary> users = fetchAuthUsers(domainUrl, orgId);
        
        if(users != null && !users.isEmpty()){
            new VeevaWechatSuggestionSummary().getNewlyCreatedSuggestions(users, runTime, lastRunTime);
            
            users = filterOutNoSuggestionUsers(users);
            if(users != null && !users.isEmpty()){
            	notifyRemoteWithSuggestionSummary(domainUrl, users, orgId);
            }
        }
    }
    
    private static List<VeevaWechatSuggestionSummary.UserSuggestionSummary> filterOutNoSuggestionUsers(List<VeevaWechatSuggestionSummary.UserSuggestionSummary> users){
        List<VeevaWechatSuggestionSummary.UserSuggestionSummary> result = new List<VeevaWechatSuggestionSummary.UserSuggestionSummary>();
        for(VeevaWechatSuggestionSummary.UserSuggestionSummary user : users){
            if(user.hasSuggestion == true){
                result.add(user);
            }
        }
        return result;
    }
    
    public static List<VeevaWechatSuggestionSummary.UserSuggestionSummary> fetchAuthUsers(String domainUrl, String orgId){
        String ts = String.valueOf(datetime.now().getTime());
        String token = generateToken(ts, orgId);
        String url = domainUrl + '/crm-service/api/wechatcrm/user/authUsers?' + 'orgId=' + orgId + '&ts=' + ts;
        
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('token', token);
        request.setEndpoint(url);
        
        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() != 200){
            throw new CalloutException('Fetch auth users failed. Response code: ' + response.getStatusCode() + '; Response body: ' + response.getBody());
        }
        
        return parseUser(response.getBody());
    }
    
    public static List<VeevaWechatSuggestionSummary.UserSuggestionSummary> parseUser(String jsonStr){
        List<VeevaWechatSuggestionSummary.UserSuggestionSummary> result = new List<VeevaWechatSuggestionSummary.UserSuggestionSummary>();
        JSONParser parser = JSON.createParser(jsonStr);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        VeevaWechatSuggestionSummary.UserSuggestionSummary user = 
                            (VeevaWechatSuggestionSummary.UserSuggestionSummary)parser.readValueAs(VeevaWechatSuggestionSummary.UserSuggestionSummary.class);
                        result.add(user);
                        parser.skipChildren();
                    }
                }
            }
        }
        
        return result;
    }
    
    public static String generateToken(String ts, String orgId){
        String salt = orgId+ts;
        String secret = orgId.substring(1,orgId.length()-1);
        Blob hmacData = Crypto.generateMac('HmacSHA256', Blob.valueOf(salt), Blob.valueOf(secret));
        return EncodingUtil.base64Encode(hmacData);
    }
    
    public static void notifyRemoteWithSuggestionSummary(String domainUrl, List<VeevaWechatSuggestionSummary.UserSuggestionSummary> users, String orgId){
        String ts = String.valueOf(datetime.now().getTime());
        String token = generateToken(ts, orgId);
        String url = domainUrl + '/crm-service/api/wechatcrm/suggestion-notification?' + 'orgId=' + orgId + '&ts=' + ts;
        
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('token', token);
        request.setTimeout(30000); 
        request.setBody(JSON.serialize(users));
        request.setEndpoint(url);
        
        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() != 200 || 'failed'.equals(response.getBody())){
            throw new CalloutException('Remote server return unsuccessful reponse. Response code: ' + response.getStatusCode() + '; Response body: ' + response.getBody());
        }
    }
}