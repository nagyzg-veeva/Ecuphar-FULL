public class Reassignment_File_Controller {
    String baseUrl = '';
    String orgId = '';
    String userId = '';
    static final Integer MAX_FILE_SIZE_10M = 10485760;
    // messages
    public String uploadUserFileMessage {get; set;}
    public String startRessaignMessage {get; set;}
    public String cancelMessage {get; set;}
    public String templateInstructionMessage {get; set;}
    public String templateDownloadMessage {get; set;}
    public String onlySupport10MMessage {get; set;}
    public String uploadErrorReminderMessage {get; set;}
    public String confirmBeforeCancelMessage {get; set;}

    public Boolean afterUpload {get; set;}
    public Blob csvFileBody {get; set;}
    public String csvFileName {get; set;}
    public Integer csvFileSize {get; set;}
    public String csvFileSizeStr {get; set;}
    public Boolean fileSizeTooBig {get; set;}
    public Boolean uploadFailed {get; set;}

	public Reassignment_File_Controller() {
		String domainUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c;
		if (domainUrl == null || ''.equals(domainUrl)) {
			baseUrl = '';
		} else {
			baseUrl = WeChat_Settings_vod__c.getInstance().DOMAIN_URL_vod__c +
					'/qyaw-service/external/v1/qyaw/reassignment';
		}
		orgId = UserInfo.getOrganizationId();
		userId = UserInfo.getUserId();

		initializeMessages();
		afterUpload = false;
		uploadFailed = false;
		fileSizeTooBig = false;
	}

	public void upload() {
		uploadFailed = false;
		fileSizeTooBig = false;
		// Only when the file size is larger than 10M, we could get Apexpages error message
		List<Apexpages.Message> errorMessages = ApexPages.getMessages();
        if (errorMessages.size()>0){
            csvFileBody = null;
            csvFileName = '';
            csvFileSize = 0;
            csvFileSizeStr = '';
        }
		try {
			if (csvFileBody == null) {
			// Only when we actually add file then we call the upload, and if we add file but the file size is larger than 10M,
			// then salesforce will give an error that the file size should not be larger than 10M, and makes the file body to be null.
				fileSizeTooBig = true;
				afterUpload = false;
				return;
			} else {
				if (csvFileBody.size() > MAX_FILE_SIZE_10M) {
					fileSizeTooBig = true;
					afterUpload = false;
					return;
				} else {
					afterUpload = true;
					fileSizeTooBig = false;
					csvFileSizeStr = fileSizeToString(csvFileSize);
				}
			}
		} catch (Exception e) {
			fileSizeTooBig = true;
		}
	}

	public PageReference reassign() {
		uploadFailed = !doReassignment();
		if (uploadFailed) {
			return null;
		}
		PageReference pageRef = new PageReference('/apex/WeCom_External_User_Reassignment');
		String tab = ApexPages.currentPage().getParameters().get('sfdc.tabName');
		pageRef.getParameters().put('sfdc.tabName', tab);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public PageReference cancel() {
		PageReference pageRef = new PageReference('/apex/WeCom_External_User_Reassignment');
		String tab = ApexPages.currentPage().getParameters().get('sfdc.tabName');
		pageRef.getParameters().put('sfdc.tabName', tab);
		pageRef.setRedirect(true);
		return pageRef;
	}

	private void initializeMessages() {
		List<String> keys = new List<String>();
		keys.add('WeChat;;UPLOAD_EXUSER_REASSIGNMENT_FILE');
		keys.add('WeChat;;EXUSER_TEMPLATE_DOWNLOAD_INSTRUCTION');
		keys.add('WeChat;;TEMPLATE_DOWNLOAD');
		keys.add('WeChat;;ONLY_SUPPORT_10M');
		keys.add('WeChat;;START_REASSIGNMENT');
		keys.add('WeChat;;START_REASSIGNMENT');
		keys.add('WeChat;;UPLOAD_ERROR_REMINDER');
		keys.add('Common;;CANCEL');
		keys.add('WeChat;;REASSIGNMENT_CANCEL_CONFIRMATION');
		Map<String, String> veevaMessages = VOD_VEEVA_MESSAGE.getVeevaMessages(keys);
		uploadUserFileMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;UPLOAD_EXUSER_REASSIGNMENT_FILE'), '上传最新分配文件');
		templateInstructionMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;UPLOAD_EXUSER_REASSIGNMENT_FILE'),
						'请下载外部联系人分配文件模板，按照模板调整后导入');
		templateDownloadMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;TEMPLATE_DOWNLOAD'), '下载模板');
		onlySupport10MMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;ONLY_SUPPORT_10M'), '只支持10M以内的文件');
		startRessaignMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;START_REASSIGNMENT'), '开始分配');
		uploadErrorReminderMessage =
				getVeevaMessageWithDefault(veevaMessages.get('WeChat;;UPLOAD_ERROR_REMINDER'), '上传过程出错，请重新上传文件后重试');
		cancelMessage = getVeevaMessageWithDefault(veevaMessages.get('Common;;CANCEL'), '取消');
		confirmBeforeCancelMessage = getVeevaMessageWithDefault(veevaMessages.get('WeChat;;REASSIGNMENT_CANCEL_CONFIRMATION'),'确认取消？');
	}

	private String getVeevaMessageWithDefault(String msg, String defaultMsg) {
		if (msg == null || ''.equals(msg)) {
			return defaultMsg;
		} else {
			return msg;
		}
	}

	private String fileSizeToString(Long value) {
		if (Value < 1024)
			return string.valueOf(Value) + ' Bytes';
		else if (Value >= 1024 && Value < (1024 * 1024)) {
			Decimal kb = Decimal.valueOf(Value);
			kb = kb.divide(1024, 2);
			return string.valueOf(kb) + ' KB';
		} else if (Value >= (1024 * 1024) && Value < (1024 * 1024 * 1024)) {
			Decimal mb = Decimal.valueOf(Value);
			mb = mb.divide((1024 * 1024), 2);
			return string.valueOf(mb) + ' MB';
		}
		return '';
	}

	public String getSelectedReportDownloadUrl() {
		String ts = String.valueOf(datetime.now().getTime());
		String token = VeevaWechatServiceUtil.generateToken(ts, orgId);
		String url = baseUrl + '/template?orgId=' + orgId + '&ts=' + ts + '&token=' + token + '&userId=' + userId;

		return url;
	}

	private Boolean doReassignment() {
		if (''.equals(baseUrl)) {
			return false;
		}
		String url = baseUrl + '?orgId=' + orgId + '&userId=' + userId;

		Map < String, String > headers = new Map < String, String > ();
		String ts = String.valueOf(datetime.now().getTime());
		String token = VeevaWechatServiceUtil.generateToken(ts, orgId);
		headers.put('Content-Type', 'application/json; charset=UTF-8');
		headers.put('token', token);
		headers.put('ts', ts);

		String responseBody = VEEVA_WEC_WEB_SERVICE_UTIL.post(url, headers, csvFileBody);
		if (responseBody.indexOf('StatusCode') > -1) {
			return false;
		}
		return true;
	}
}