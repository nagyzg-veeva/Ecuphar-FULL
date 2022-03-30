public with sharing class LightningReadyVodController {
    public String VEEVA_CRM_LIGHTNING_READY_UPGRADE_TAB {get;set;}
    public String UNDERSTANDING_CRM_LIGHTNING_READY_UPGRADE_TITLE {get;set;}
    public String UNDERSTANDING_CRM_LIGHTNING_READY_UPGRADE_DETAIL {get;set;}
    public String RUN_REPORT {get; set;}
    public String RUN_CRM_LIGHTNING_READY_REPORT_CONFIRM {get;set;}
    public String DEPLOY_CRM_LIGHTNING_READY_UPGRADE_TITLE {get;set;}
    public String DEPLOY_CRM_LIGHTNING_READY_UPGRADE_DETAIL_EVAL {get;set;}
    public String DEPLOY_CRM_LIGHTNING_READY_UPGRADE_DETAIL {get;set;}
    public String DEPLOY {get;set;}
    public String DEPLOY_CRM_LIGHTNING_READY_UPGRADE_CONFIRM {get;set;}
    public String DEPLOY_CRM_LIGHTNING_READY_UPGRADE {get;set;}
    public String CLOSE {get;set;}
    public String CANCEL {get;set;}
    public String SYSTEM_ERROR {get;set;}
    public String ERROR_VEEVA_SUPPORT_TICKET {get;set;}

    public LightningReadyVodController() {
        VEEVA_CRM_LIGHTNING_READY_UPGRADE_TAB = VOD_VEEVA_MESSAGE.getMsgWithDefault('VEEVA_CRM_LIGHTNING_READY_UPGRADE_TAB', 'Common',  'Veeva CRM \'Lightning Ready\' Upgrade');
        UNDERSTANDING_CRM_LIGHTNING_READY_UPGRADE_TITLE = VOD_VEEVA_MESSAGE.getMsgWithDefault('UNDERSTANDING_CRM_LIGHTNING_READY_UPGRADE_TITLE', 'Common',  'Understanding the Veeva CRM \'Lightning Ready\' Upgrade');
        UNDERSTANDING_CRM_LIGHTNING_READY_UPGRADE_DETAIL = VOD_VEEVA_MESSAGE.getMsgWithDefault('UNDERSTANDING_CRM_LIGHTNING_READY_UPGRADE_DETAIL', 'Common',    'Review the changes that the Veeva CRM \'Lightning Ready\' upgrade will make to your org so that your Veeva CRM transactions are Lightning compatible. We\'ll email you the upgrade report. Only users with the System Administrator profile can run this report.');
        RUN_REPORT = VOD_VEEVA_MESSAGE.getMsgWithDefault('RUN_REPORT', 'Common',    'Run Report');
        RUN_CRM_LIGHTNING_READY_REPORT_CONFIRM = VOD_VEEVA_MESSAGE.getMsgWithDefault('RUN_CRM_LIGHTNING_READY_REPORT_CONFIRM', 'Common',    'Veeva CRM \'Lightning Ready\' upgrade report has been initiated for this org. We\'ll email you when the report is ready.');
        DEPLOY_CRM_LIGHTNING_READY_UPGRADE_TITLE = VOD_VEEVA_MESSAGE.getMsgWithDefault('DEPLOY_CRM_LIGHTNING_READY_UPGRADE_TITLE', 'Common',    'Deploy the Veeva CRM \'Lightning Ready\' Upgrade');
        DEPLOY_CRM_LIGHTNING_READY_UPGRADE_DETAIL_EVAL = VOD_VEEVA_MESSAGE.getMsgWithDefault('DEPLOY_CRM_LIGHTNING_READY_UPGRADE_DETAIL_EVAL', 'Common',
            'When you\'re ready to deploy the Veeva CRM \'Lightning Ready\' upgrade to your org, then click the button below. We\'ll email you when the deployment is done. This upgrade should only be deployed into Sandbox orgs; please do not migrate the changes from this upgrade to Production.');
        DEPLOY_CRM_LIGHTNING_READY_UPGRADE_DETAIL = VOD_VEEVA_MESSAGE.getMsgWithDefault('DEPLOY_CRM_LIGHTNING_READY_UPGRADE_DETAIL', 'Common',
            'When you\'re ready to deploy the Veeva CRM \'Lightning Ready\' upgrade to your org, then click the button below. We\'ll email you when the deployment is done.');
        DEPLOY = VOD_VEEVA_MESSAGE.getMsgWithDefault('DEPLOY', 'Common', 'Deploy');
        DEPLOY_CRM_LIGHTNING_READY_UPGRADE_CONFIRM = VOD_VEEVA_MESSAGE.getMsgWithDefault('DEPLOY_CRM_LIGHTNING_READY_UPGRADE_CONFIRM', 'Common',    'Are you sure that you want to deploy the Veeva CRM \'Lightning Ready\' upgrade to this org?');
        DEPLOY_CRM_LIGHTNING_READY_UPGRADE = VOD_VEEVA_MESSAGE.getMsgWithDefault('DEPLOY_CRM_LIGHTNING_READY_UPGRADE', 'Common',    'Deployment of the Veeva CRM \'Lightning Ready\' upgrade has been initiated for this org. We\'ll email you when the deployment is done.');
        CLOSE = VOD_VEEVA_MESSAGE.getMsgWithDefault('CLOSE', 'Common',  'Close');
        CANCEL = VOD_VEEVA_MESSAGE.getMsgWithDefault('CANCEL', 'Common', 'Cancel');
        SYSTEM_ERROR = VOD_VEEVA_MESSAGE.getMsgWithDefault('SYSTEM_ERROR', 'Common', 'A system error has occurred. Please try again.');
        ERROR_VEEVA_SUPPORT_TICKET = VOD_VEEVA_MESSAGE.getMsgWithDefault('ERROR_VEEVA_SUPPORT_TICKET', 'Common', 'Looks like something went wrong. Please log a ticket with Veeva Support.');

    }
    
    public Boolean getCanUpgrade() {
        Organization org = [SELECT Id, IsSandbox FROM Organization];
        if (org != null) {
            Id id = UserInfo.getProfileId();
            List<Profile> profile = [ Select Id, Name From Profile Where (UserType = 'Standard' AND PermissionsPrivacyDataAccess = true AND Id = :id) ];
            // Only System Admins should have the PermissionsPrivacyDataAccess permission
            if (profile != null && !profile.isEmpty()) {
                return true;
            }
        }
        return false;
    }

    public Integer getVodVersion() {
        VOD_EMBED_CONTROLLER embed = new VOD_EMBED_CONTROLLER();
        return embed.getVodVersion();
    }
    
    public String getVodUrl() {
        VOD_EMBED_CONTROLLER embed = new VOD_EMBED_CONTROLLER();
        return embed.getVodUrl();
    }
    
    public static String getSfSession() {
        return VOD_EMBED_CONTROLLER.getSfSession();
    }

    public static String getSfEndpoint() {
        return VOD_EMBED_CONTROLLER.getSfEndpoint();
    }

}