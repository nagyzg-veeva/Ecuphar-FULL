import { LightningElement, api, track, wire } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";
import CommandHandlerFactory from "c/commandHandlerFactory";
import MyInsightsLightningBridge from "c/myInsightsLightningBridge";
import { getRecordUi, getRecord } from 'lightning/uiRecordApi';
import VeevaPerfLogService from 'c/veevaPerfLogService';
import HTML_REPORT_NAME_FLD from '@salesforce/schema/HTML_Report_vod__c.Name';
import HTML_REPORT_VISIBILITY_CRITERIA_FLD from '@salesforce/schema/HTML_Report_vod__c.Visibility_Criteria_vod__c';

const HTML_REPORT_FIELDS = [HTML_REPORT_NAME_FLD];
const HTML_REPORT_OPTIONAL_FIELDS = [HTML_REPORT_VISIBILITY_CRITERIA_FLD];
export default class MyInsights extends LightningElement {
    @api htmlReportId;
    @api recordId;
    @api maxHeight;

    @track myInsightsContentPath;
    @track cdnAuthToken;

    pageCtrl;
    lightningBridge;
    uuid;
    htmlReport;
    objectRecordId;
    optionalObjectFields = [];
    awaitingObjectData = false;

    constructor() {
        super();
        this.pageCtrl = getPageController("HTML_Report_vod__c--MyInsights");
        this.pageCtrl.page = {
            requests: []
        };
        this.perfLog = new VeevaPerfLogService();
    }

    @wire(getRecord, { recordId: "$htmlReportId", fields: HTML_REPORT_FIELDS, optionalFields: HTML_REPORT_OPTIONAL_FIELDS })
    async wiredHtmlReport(htmlReport) {
        // When this.htmlReportId and htmlReport.data are populated this means that
        // the myInsights LWC was configured to use a specific HTML Report and the user
        // has access to this report. We will not show a Toast to the user since it is possible
        // that a page will contain a MyInsights LWC but should only be visible to the user
        // if the user has access to view the HTML Report. Since myInsights LWCs can be on any page (App, Record, Home)
        // the rational for not showing a Toast is that the Lightning App Builder does not allow an admin to configure
        // the visibility of a HTML Report based on a User's access to the HTML Report. So it may be desired that
        // different users will use the same Flexipage but will only see the myInsights LWC based on their access to the htmlReportId
        if (this.htmlReportId && htmlReport.data) {
            this.htmlReport = htmlReport.data;

            // getRecordUi does not provide data for a field if it's not included on the page layout. We can parse the visibility
            // criteria value and add it as an optionalField to query along with the rest of object record data.
            if (this.htmlReport.fields?.Visibility_Criteria_vod__c?.value) {
                this.optionalObjectFields.push(this.htmlReport.fields.Visibility_Criteria_vod__c.value);
            }

            // This will trigger the wiredObjectDetails method below when this.recordId is defined.
            this.objectRecordId = this.recordId;
            this.awaitingObjectData = (this.recordId !== undefined);
            
            await this.initializeMyInsights();
        } else {
            this.htmlReport = null;
        }
    }

    @wire(getRecordUi, { recordIds: "$objectRecordId", layoutTypes: "Full", modes: "View", optionalFields: "$optionalObjectFields" })
    async wiredObjectDetails({ error, data }) {
        if (data) {
            const result = JSON.parse(JSON.stringify(data));
            this.pageCtrl.record = result.records[this.objectRecordId];
            this.pageCtrl.objectInfo = result.objectInfos[this.pageCtrl.record.apiName];
            this.awaitingObjectData = false;
        } else if (error) {
            this.setError(error);
        }
    }

    get iframe() {
        return this.template.querySelector("iframe");
    }

    get iframeUrl() {
        if (!this.myInsightsContentPath || !this.cdnAuthToken) {
            return null;
        }
        return `${this.myInsightsContentPath}/index.html?${this.cdnAuthToken}`;
    }

    get loading() {
        // We will only show the loading spinner if we determine that we should show this LWC to the user
        // and if the iframeUrl has not been generated yet.ß
        return this.iframeUrl === null && this.showMyInsightsLWC;
    }

    get htmlReportValidAndLoaded() {
        // We will only show the myInsights content if we determine that we should show this LWC to the user
        // and if the iframeUrl has not been generated yet.ß
        return this.iframeUrl && this.showMyInsightsLWC;
    }

    get showMyInsightsLWC() {
        // We only show the myInsights LWC after we determine that the user has access to this.htmlReportId
        // this.htmlReport will be populated by our getRecord wire for htmlReportId if the user has access to the htmlReportId
        // Two reason for not having access to the HTML Report is due to a lack of read permission to HTML_Report_vod__c
        // or the user does not have to the specific HTML Report due to sharing rules.
        const baseShowReportCondition = this.htmlReportId && this.htmlReport;
        let showReport = baseShowReportCondition;

        // Customers can optionally configure record-level visibility for visualizations since information might not be available
        // to display for all records for which the LWC is configured. Visibility is controlled by the Visibility_Crtieria_vod__c
        // text field on HTML_Report_vod__c that references the Checkbox/Formula(Checkbox) field on the page object.
        // ex: HTML_Report_vod__c.Visibility_Criteria_vod__c = "Account.Show_KOL_Report_vod__c"
        const populatedPageCtrl = this.pageCtrl.record && this.pageCtrl.objectInfo;
        const visCriteriaField = this.htmlReport?.fields?.Visibility_Criteria_vod__c;
        if (baseShowReportCondition && this.objectRecordId && visCriteriaField && populatedPageCtrl) {
            const visCriteriaValue = visCriteriaField.value;
            showReport = this.parseVisibilityCriteria(visCriteriaValue);
        }

        return showReport && !this.awaitingObjectData;
    }

    parseVisibilityCriteria(visCriteriaValue) {
        // We will parse information from the value of the Visibility_Criteria_vod__c field to determine which
        // field we will key on for the target object. Any misconfiguration of the value in this field will result
        // in the report being shown on the page.
        let showReport = true;
        
        if (visCriteriaValue && visCriteriaValue.trim().length > 0) {
            let visCriteriaParts = visCriteriaValue.split('.');
            if (visCriteriaParts.length == 2) {
                const pageObjectName = this.pageCtrl.record.apiName.toLowerCase();
                const pageObjectRecordFields = this.getLowerCaseFieldToValues(this.pageCtrl.record.fields);
                const pageObjectInfoFields = this.getLowerCaseFieldToValues(this.pageCtrl.objectInfo.fields);
                const criteriaObjectName = visCriteriaParts[0].toLowerCase();
                const criteriaFieldName = visCriteriaParts[1].toLowerCase();

                if (criteriaObjectName === pageObjectName
                    && pageObjectRecordFields[criteriaFieldName]
                    && pageObjectInfoFields[criteriaFieldName]) {
                    const showReportFieldValue = pageObjectRecordFields[criteriaFieldName].value;
                    const showReportFieldDataType = pageObjectInfoFields[criteriaFieldName].dataType;
                    showReport = (showReportFieldDataType !== "Boolean" || showReportFieldValue);
                }
            }
        }

        return showReport;
    }

    /**
     * Takes the fields in record and creates a set of lower case fields.
     * This will allow us to perform case insensitive field checks.
     * @returns {Set} returns a set of lower case fields from record
     */
     getLowerCaseFieldToValues(record) {
        const lowerCaseFieldsToValues = {};
        if (record) {
            Object.entries(record)
                .forEach(([field, fieldValue]) => {
                    const lowerCaseField = field.toLowerCase();
                    lowerCaseFieldsToValues[lowerCaseField] = fieldValue;
                });
        }
        return lowerCaseFieldsToValues;
    }

    async initializeMyInsights() {
        const loadCdnInformation = {
            start: +new Date()
        };
        const [orgId, baseCdnDomainUrl] = await Promise.all([
            this.pageCtrl.getOrgId(),
            this.pageCtrl.getBaseCdnDomainUrl()
        ]);

        this.updateMyInsightsContentPath(orgId, baseCdnDomainUrl);
        this.updateCdnAuthToken(orgId);

        this.uuid = this.generateUUID();
        // Update MyInsightsController's htmlReportId
        this.pageCtrl.htmlReportId = this.htmlReportId;
        this.pageCtrl.htmlReportUUID = this.uuid;
        this.initializeLightningBridge(baseCdnDomainUrl);
        this.logCdnInformationTime(loadCdnInformation);
    }

    /**
     * We will log how long it took to gather information to begin loading the HTML Report from the CDN.
     * This will be important as we want to know how getBaseCdnDomainUrl() and getCdnAuthToken()
     * impact the time it takes to start loading the HTML Report.
     *
     * The time it takes for the iframe to load is a metric that we are less interested in since
     * this should be provided by the CDN. Also since each HTML Report may differ largely in the
     * requests it makes we will not report those as part of the MyInsights LWC page performance. 
     */
    logCdnInformationTime(loadCdnInformation) {
        // We will report how long it takes to load the HTML_Report_vod__c--MyInsights for a specific objectApiName
        // It is possible for this.pageCtrl.objectApiName to be null when we are looking at a non-Record page,
        // however this is handled by VeevaPerfLogService
        this.perfLog.logPagePerformance("HTML_Report_vod__c--MyInsights", this.pageCtrl.objectApiName, loadCdnInformation);
    }

    initializeLightningBridge(baseCdnDomainUrl) {
        const veevaUserInterfaceAPI = getPageController("userInterfaceSvc");
        const veevaSessionService = getPageController("sessionSvc");
        const veevaDataService = getPageController("dataSvc");
        const commandHandlers = CommandHandlerFactory.commandHandlers(veevaUserInterfaceAPI, veevaSessionService, veevaDataService, this.pageCtrl);
        this.lightningBridge = new MyInsightsLightningBridge(baseCdnDomainUrl, this.htmlReportId, this.uuid, commandHandlers);
    }

    async updateCdnAuthToken(orgId) {
        const path = `/${orgId}/${this.htmlReportId}/`;
        this.cdnAuthToken = await this.pageCtrl.getCdnAuthToken(path);
    }

    updateMyInsightsContentPath(orgId, baseCdnDomainUrl) {
        const reportPath = `/${orgId}/${this.htmlReportId}`;
        const contentUrl = new URL(baseCdnDomainUrl);
        contentUrl.pathname = reportPath;
        this.myInsightsContentPath = contentUrl.toString();
    }

    generateUUID() {
        // Our iframe will already receive an HTML Report Id so this UUID will just ensure that in the slight
        // chance another MyInsights LWC is on the screen with the same HTML Report Id we only respond to the one
        // we generated a UUID for.
        // References https://www.w3resource.com/javascript-exercises/javascript-math-exercise-23.php
        let dateTime = new Date().getTime();
        const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, character => {
            const randomHexValue = (dateTime + Math.random() * 16) % 16 | 0;
            dateTime = Math.floor(dateTime / 16);
            return (character === 'x' ? randomHexValue : (randomHexValue & 0x3 | 0x8)).toString(16);
        });
        return uuid;
    }
}