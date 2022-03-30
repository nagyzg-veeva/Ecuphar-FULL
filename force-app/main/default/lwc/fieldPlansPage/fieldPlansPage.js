import { LightningElement, wire, track, api } from 'lwc';
import getTerritoryFeedbackSettings from '@salesforce/apex/TerritoryFeedbackSettings.getTerritoryFeedbackSettings';
import getVodInfo from '@salesforce/apex/SessionVod.getVodInfo';
import TerritoryFeedbackService from 'c/territoryFeedbackService';
import LANG from '@salesforce/i18n/lang';
import Id from '@salesforce/user/Id';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import VeevaMessageService from 'c/veevaMessageService';
import { loadStyle } from 'lightning/platformResourceLoader';
import fieldPlansStyling from '@salesforce/resourceUrl/fieldPlansStyling';
import { NotManagerError, NoFieldPlansError, AsyncProcessRunningError } from 'c/territoryFeedbackErrors';

export default class FieldPlansPage extends LightningElement {
    @api fieldPlanId;
    @api forceDisplayFieldPlansPage;

    @track isManager;
    @track fieldPlans;
    @track messageService;

    error;
    territoryFeedbackSvc;
    territoryFeedbackSettings;
    vodInfo;
    loading = true;

    // Veeva Messages
    fieldPlansHeader;
    dueLabel;
    cycleLabel;

    async connectedCallback() {
        loadStyle(this, fieldPlansStyling);

        this.messageService = new VeevaMessageService();
        await this.messageService.loadVeevaMessageCategories(['Feedback', 'TABLET']);
        await this.loadVeevaMessages();
    }

    async loadVeevaMessages() {
        [this.fieldPlansHeader, this.dueLabel, this.cycleLabel] = await Promise.all([
            this.messageService.getMessageWithDefault('FIELD_PLANS', 'Feedback', 'Field Plans'),
            this.messageService.getMessageWithDefault('DUE', 'Feedback', 'Due'),
            this.messageService.getMessageWithDefault('CYCLE', 'TABLET', 'Cycle')
        ]);
    }

    @wire(getTerritoryFeedbackSettings)
    processTerritoryFeedbackSettingsResults({ error, data }) {
        this.processWiredMethodsThenLogin(error, data, 'territoryFeedbackSettings');
    }

    @wire(getVodInfo)
    processVodInfoResults({ error, data }) {
        this.processWiredMethodsThenLogin(error, data, 'vodInfo');
    }

    processWiredMethodsThenLogin(error, data, propertyName) {
        if (data) {
            this[propertyName] = data;
            if (this.territoryFeedbackSettings && this.vodInfo) {
                this.loginToTerritoryFeedback();
            }
        } else if (error) {
            this.loading = false;
            this.error = error;
            logError(error);
        }
    }

    async loginToTerritoryFeedback() {
        this.territoryFeedbackSvc = this.instantiateTerritoryService();

        try {
            const loginData = await this.territoryFeedbackSvc.login();
            this.isManager = loginData.isManager;
            if (this.isManager) {
                await this.loadFieldPlans();
            } else {
                throw new NotManagerError('Current user is not a manager.');
            }
        } catch (error) {
            this.handleError(error);
        }
    }

    async loadFieldPlans() {
        /* 
        * For MVP, a flag will be returned by Align to indicate whether an async process
        * is running against any one of the user's assigned territories.
        */
        const fieldPlansResponse = await this.territoryFeedbackSvc.getFieldPlans();
        if (!fieldPlansResponse.asynchronousProcessRunning) {
            // If only one fieldPlan, then we want to direct user straight to the Territories screen instead of rendering the Field Plan
            if (fieldPlansResponse.fieldPlans.length === 1 && !this.forceDisplayFieldPlansPage) {
                this.navigateToFieldForceModelsPage(fieldPlansResponse.fieldPlans[0].id);
            } else if (!fieldPlansResponse.fieldPlans.length) {
                throw new NoFieldPlansError('Current user has no plans available for feedback.');
            } else {
                this.fieldPlans = fieldPlansResponse.fieldPlans;
                this.loading = false;
            }
        } else {
            throw new AsyncProcessRunningError('An asynchronous process is running against this user\'s data.');
        }
    }

    handleError(error) {
        logError(error);
        this.loading = false;
        this.errorHandler?.renderError(error);
        this.error = error;
    }

    // CRM-234394 temporarily add auth params to constructor so that they can be sent with every request
    // Remove after ALN-25276 is resolved
    instantiateTerritoryService() {
        return new TerritoryFeedbackService(
            this.territoryFeedbackSettings.alignServer, 
            this.territoryFeedbackSettings.alignVersion,
            Id, 
            LANG, 
            this.vodInfo.sfSession, 
            this.vodInfo.sfEndpoint);
    }

    handleTerritoryNavigation(event) {
        this.navigateToFieldForceModelsPage(event.target.value);
    }

    navigateToFieldForceModelsPage(selectedFieldPlanId) {
        this.fieldPlanId = selectedFieldPlanId;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    get hidePageContent() {
        return this.error || this.loading;
    }

    get errorHandler() {
        return this.template.querySelector('c-territory-feedback-error-handler');
    }
}

function logError(error) {
    console.error(error);
}