public class WeChat_Reassignment_Controller {
    integer totalRecs = 0;
    integer limitSize = 20;
    integer offsetSize = 0;
    String baseUrl = '';
    String orgId = '';
    String userId = '';
    // messages
    public String reassignmentRecordsMessage {get; set;}
    public String importFileMessage {get; set;}
    public String onlineAlertMessage {get; set;}
    public String ongoingReassignmentMessage {get; set;}
    public String startTimeMessage {get; set;}
    public String finishTimeMessage {get; set;}
    public String userMessage {get; set;}
    public String statusMessage {get; set;}
    public String totalMessage {get; set;}
    public String successFailMessage {get; set;}
    public String errorSummaryMessage {get; set;}
    public String downloadDetailsMessage {get; set;}
    public String previousMessage {get; set;}
    public String nextMessage {get; set;}

    public Boolean displayAlert {get; set;}
    public String currentSelectedDeniedId  {get; set;}
    public String currentSelectedExceptionId  {get; set;}
    public Boolean hasPrevious {get; set;}
    public Boolean hasNext {get; set;}
    private List < ReassignmentList > reassignmentResultList = new List < ReassignmentList > ();
    public List < ReassignmentList > getReassignmentResultList() {
        return reassignmentResultList;
    }

	public WeChat_Reassignment_Controller() {
		String domainUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c;
		if (domainUrl == null || ''.equals(domainUrl)) {
			baseUrl = '';
		} else {
			baseUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c +
					'/qyaw-service/external/v1/qyaw/reassignment';
		}
		orgId = UserInfo.getOrganizationId();
		userId = UserInfo.getUserId();
		getReassignmentList();
		displayAlert = !getUploadAllowance();
		initializeMessages();
		hasPrevious = false;
		hasNext = false;
		if (limitSize < totalRecs) {
			hasNext = true;
		}
	}

	public PageReference processReassignment() {
		if (displayAlert) {
			return null;
		}
		PageReference pageRef = new PageReference('/apex/WeCom_Reassignment_File');
		String tab = ApexPages.currentPage().getParameters().get('sfdc.tabName');
		pageRef.getParameters().put('sfdc.tabName', tab);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public void previous() {
		offsetSize = offsetSize - limitSize;
		if (offsetSize <= 0) {
			hasPrevious = false;
		} else {
			hasPrevious = true;
		}
		if ((offsetSize + limitSize) > totalRecs) {
			hasNext = false;
		} else {
			hasNext = true;
		}
		getReassignmentList();
	}

	public void next() {
		offsetSize = offsetSize + limitSize;
		if ((offsetSize + limitSize) >= totalRecs) {
			hasNext = false;
		} else {
			hasNext = true;
		}
		if (offsetSize == 0) {
			hasPrevious = false;
		} else {
			hasPrevious = true;
		}
		getReassignmentList();
	}

	private void initializeMessages() {
		List<String> keys = new List<String>();
		keys.add('WeChat;;REASSIGNMENT_RECORDS');
		keys.add('WeChat;;IMPORT_EXUSER_REASSIGNMENT_FILE');
		keys.add('WeChat;;ONLINE_ALERT');
		keys.add('WeChat;;ONGOING_REASSIGNMENT_JOB_ALERT');
		keys.add('WeChat;;REASSIGNMENT_START_TIME');
		keys.add('WeChat;;REASSIGNMENT_FINISH_TIME');
		keys.add('WeChat;;REASSIGNMENT_USER');
		keys.add('WeChat;;REASSIGNMENT_USER');
		keys.add('WeChat;;REASSIGNMENT_STATUS');
		keys.add('WeChat;;REASSIGNMENT_TOTAL');
		keys.add('WeChat;;REASSIGNMENT_SUCCESS_FAIL');
		keys.add('WeChat;;REASSIGNMENT_ERROR_SUMMARY');
		keys.add('WeChat;;DOWNLOAD_DETAILS');
		keys.add('View;;PREVIOUS');
		keys.add('View;;NEXT');
		Map<String, String> veevaMessages = VOD_VEEVA_MESSAGE.getVeevaMessages(keys);
		reassignmentRecordsMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_RECORDS'), '分配记录');
		importFileMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;IMPORT_EXUSER_REASSIGNMENT_FILE'), '导入最新分配文件');
		onlineAlertMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;ONLINE_ALERT'), '提示信息');
		ongoingReassignmentMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;ONGOING_REASSIGNMENT_JOB_ALERT'),
						'有任务正在进行中，请耐心等待');
		startTimeMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_START_TIME'), '开始时间');
		finishTimeMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_FINISH_TIME'), '结束时间');
		userMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_USER'), '用户');
		statusMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_STATUS'), '状态');
		totalMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_TOTAL'), '分配总数');
		successFailMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_SUCCESS_FAIL'), '分配成功/拒绝');
		errorSummaryMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_ERROR_SUMMARY'), '异常情况汇总');
		downloadDetailsMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;DOWNLOAD_DETAILS'), '下载详情');
		previousMessage = getVeevaMessageWithDefault(veevaMessages.get('View;;PREVIOUS'), '上一页');
		nextMessage = getVeevaMessageWithDefault(veevaMessages.get('View;;NEXT'), '下一页');

	}

	private String getVeevaMessageWithDefault(String msg, String defaultMsg) {
		if (msg == null || ''.equals(msg)) {
			return defaultMsg;
		} else {
			return msg;
		}
	}

	private void getReassignmentList() {
		if (''.equals(baseUrl)) {
			return;
		}
		if (reassignmentResultList.size() > 0) {
			reassignmentResultList.clear();
		}

		String url = baseUrl + '?orgId=' + orgId + '&pageSize=' + limitSize + '&page=' + offsetSize;
		String responseBody = getAssigmentRequest(url);
		if (responseBody.indexOf('StatusCode') > -1) {
			return;
		}
		reassignmentResultList.addAll(parseReassignmentList(responseBody));
	}

	private List < ReassignmentList > parseReassignmentList(String jsonStr) {
		List < ReassignmentList > result = new List < ReassignmentList > ();

		JSONParser parser = JSON.createParser(jsonStr);
		while (parser.nextToken() != null) {
			if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getCurrentName() == 'count' &&
							parser.nextToken() != null) {
				totalRecs = Integer.valueOf(parser.getText());
			}
			if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
				while (parser.nextToken() != null) {
					if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
						ReassignmentList history =
								(ReassignmentList) parser.readValueAs(ReassignmentList.class);
						result.add(history);
						parser.skipChildren();
					}
				}
			}
		}
		return result;
	}

	public String getDeniedList() {
		if (''.equals(baseUrl)) {
			return '';
		}
		String url = getDownloadUrl('denied-list');
		return url;
	}

	public String getExceptionList() {
		if (''.equals(baseUrl)) {
			return '';
		}
		String url = getDownloadUrl('exception-list');
		return url;
	}

	private Boolean getUploadAllowance() {
		if (''.equals(baseUrl)) {
			return false;
		}
		String url = baseUrl + '/uploading-allowance?orgId=' + orgId;
		String responseBody = getAssigmentRequest(url);
		if (responseBody.indexOf('StatusCode') > -1) {
			return false;
		}
		Boolean result = false;
		JSONParser parser = JSON.createParser(responseBody);
		while (parser.nextToken() != null) {
			if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getCurrentName() == 'payload' &&
							parser.nextToken() != null) {
				result = Boolean.valueOf(parser.getText());
			}
		}
		return result;
	}

	private String getAssigmentRequest(String url) {
		Map < String, String > headers = new Map < String, String > ();
		String ts = String.valueOf(datetime.now().getTime());
		String token = VeevaWechatServiceUtil.generateToken(ts, orgId);
		headers.put('Content-Type', 'application/json; charset=UTF-8');
		headers.put('token', token);
		headers.put('ts', ts);
		return VEEVA_WEC_WEB_SERVICE_UTIL.get(url, headers);
	}

	private String getDownloadUrl(String type) {
		String ts = String.valueOf(datetime.now().getTime());
		String token = VeevaWechatServiceUtil.generateToken(ts, orgId);
		String url = '';
		switch on type {
			when 'denied-list' {
				url = baseUrl + '/' + currentSelectedDeniedId + '/denied-list?orgId=' + orgId + '&ts=' + ts +
						'&token=' + token + '&userId=' + userId;
			}
			when 'exception-list' {
				url = baseUrl + '/' + currentSelectedExceptionId + '/exception-list?orgId=' + orgId + '&ts=' + ts +
						'&token=' + token + '&userId=' + userId;
			}
		}
		return url;
	}

    public class ReassignmentList {
        public Long id {get; set;}
        public String formattedStartTime {get; set;}
        public String formattedEndTime {get; set;}
        public String operationUser {get; set;}
        public String status {get; set;}
        public Integer totalProcessed {get; set;}
        public String reassignedMessage {get; set;}
        public Boolean hasDeniedList {get; set;}
        public String exceptionMessage {get; set;}
        public Boolean hasExceptionList {get; set;}
    }

}