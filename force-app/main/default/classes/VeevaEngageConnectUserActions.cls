public without sharing class VeevaEngageConnectUserActions {

    public static void passUsersToConnectServer(Set<ID> groupChange, Set<ID> otherChange) {
        if (System.isFuture() || System.isBatch()) {
            passUsersToConnectServerNow(groupChange, otherChange);
        } else {
            passUsersToConnectServerFuture(groupChange, otherChange);
        }
    }

    @future(callout=true)
    public static void passUsersToConnectServerFuture(Set<ID> groupChange, Set<ID> otherChange) {
        passUsersToConnectServerNow(groupChange, otherChange);
    }

    public static void passUsersToConnectServerNow(Set<ID> groupChange, Set<ID> otherChange) {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String connectHost = settings.Engage_Connect_Server_vod__c;
        String url = connectHost + '/admin/sf/v1/org/users';
        String sfSession = VOD_EMBED_CONTROLLER.getSfSession();

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('sfSession', sfSession);
        req.setEndpoint(url);

        List<User> users = [Select ID, FirstName, LastName, Email, IsActive, Title, MobilePhone,
                            Engage_Connect_Group_Request_vod__c, Country_Code_vod__c, User_Type_vod__c
                            , Engage_Connect_Group_Status_vod__c
                            FROM User WHERE ID in :groupChange or ID in :otherChange];
        req.setBody(createBodyForConnectRequest(users));

        HttpResponse response = http.send(req);
        if (response.getStatusCode() == 403) {
            // Don't update the status field -- org is not a Connect customer
        }
        else if (response.getStatusCode() == 204) {
            setEngageConnectGroupProvisioningStatus(users, groupChange, 'Request_Sent_vod');
        }
        else {
            setEngageConnectGroupProvisioningStatus(users, groupChange, 'Request_Failed_vod');
        }
    }

    private static void setEngageConnectGroupProvisioningStatus(List<User> users, Set<ID> forIds, String status) {
        System.debug('In VeevaEngageConnectUserActions::');
        for(User user: users) {
            if (forIds.contains(user.ID)) {
	            user.Engage_Connect_Group_Status_vod__c = status;
            }
        }
        update users;
    }

    private static String createBodyForConnectRequest(List<User> users) {
        JSONGenerator json = JSON.createGenerator(true);

        json.writeStartArray();

        //write user id and remote meeting group ids to data field
        for (User user : users) {
            json.writeStartObject();
            json.writeObjectField('userID', user.ID);
            json.writeObjectField('firstName', user.FirstName != null? user.FirstName : '');
            json.writeObjectField('lastName', user.LastName);
            json.writeObjectField('email', user.Email);
            json.writeObjectField('isActive', user.IsActive);
            json.writeObjectField('title', user.Title != null? user.Title : '');
            json.writeObjectField('mobilePhone', user.MobilePhone != null? user.MobilePhone : '');
            json.writeObjectField('countryCode','');
            json.writeObjectField('group', user.Engage_Connect_Group_Request_vod__c != null? user.Engage_Connect_Group_Request_vod__c : '');
            json.writeObjectField('countryCodeVodC', user.Country_Code_vod__c != null? user.Country_Code_vod__c: '');
            json.writeObjectField('userTypeVodC', user.User_Type_vod__c != null? user.User_Type_vod__c: '');
            json.writeEndObject();
        }
        json.writeEndArray();

        //get JSON string
        return json.getAsString();
    }
}