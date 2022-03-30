import { LightningElement, api, track, wire } from 'lwc';
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import TerritoryFeedbackService from 'c/territoryFeedbackService';
import getTerritoryFeedbackSettings from '@salesforce/apex/TerritoryFeedbackSettings.getTerritoryFeedbackSettings';
import TerritoryTableMetadata from 'c/territoryTableMetadata';
import FieldForceModelsPageCommandFactory from 'c/fieldForceModelsPageCommandFactory';
import VeevaMessageService from 'c/veevaMessageService';
import getVodInfo from '@salesforce/apex/SessionVod.getVodInfo';
import LANG from '@salesforce/i18n/lang';
import Id from '@salesforce/user/Id';
import { AsyncProcessRunningError } from 'c/territoryFeedbackErrors';

const PADDING_OFFSET = 26;

export default class FieldForceModelsPage extends LightningElement {
    @api fieldPlanId;
    @api selectedFieldForceId;
    @api nextScreenName;
    @api selectedTerritoryModelId;
    @api selectedAccountsFilter;
    @api forceDisplayFieldPlansPage;

    @track fieldPlan;
    @track childTerritories;
    @track activeFieldForceTableMetadata;
    @track error;
    sortDirection = 'asc';
    sortedBy = 'name';
    territoryReferenceMap;
    fieldForceCurrentParentMap;
    fieldForceReferenceMap;
    activeFieldForceId;
    availableActionsForActiveParent;
    territoryFeedbackSvc;
    confirmationCallback;
    isPanelOpen;
    messageService;
    fieldPlansMessage;
    moreInfoMessage;
    loading = true;

    renderedCallback() {
        this.updateBodyContainerHeight();
    }

    // Dynamically updates the CSS variable so that the table and info panel do not grow beyond the viewport. Instead, nested components will have their own scrollbar.
    updateBodyContainerHeight() {
        const bodyContainerOffsetAmount = PADDING_OFFSET + this.template.querySelector('.body-container')?.getBoundingClientRect().top;
        this.template.host.style.setProperty('--vertical-offset', `${bodyContainerOffsetAmount}px`);
    }

    async connectedCallback() {
        this.messageService = new VeevaMessageService();
        await this.messageService.loadVeevaMessageCategories(['Feedback', 'Common']);
        [this.fieldPlansMessage, this.moreInfoMessage] = await Promise.all([
            this.messageService.getMessageWithDefault('FIELD_PLANS', 'Feedback', 'Field Plans'),
            this.messageService.getMessageWithDefault('MORE_INFO', 'Common', 'More Info'),
        ]);
    }

    // CRM-234394 temporarily add auth params to every request, requiring us to retrieve sfSession and sfEndpoint on each page
    // Remove after ALN-25276 is resolved
    @wire(getTerritoryFeedbackSettings)
    getFieldPlanInfo({ error, data }) {
        this.processWiredMethodsThenFetch(error, data, 'territoryFeedbackSettings');
    }

    @wire(getVodInfo)
    processVodInfoResults({ error, data }) {
        this.processWiredMethodsThenFetch(error, data, 'vodInfo');
    }

    processWiredMethodsThenFetch(error, data, propertyName) {
        if (data) {
            this[propertyName] = data;
            if (this.territoryFeedbackSettings && this.vodInfo) {
                this.territoryFeedbackSvc = new TerritoryFeedbackService(
                    this.territoryFeedbackSettings.alignServer, 
                    this.territoryFeedbackSettings.alignVersion,
                    Id, 
                    LANG, 
                    this.vodInfo.sfSession, 
                    this.vodInfo.sfEndpoint
                );

                this.fetchFieldPlanInfo();
            }
        } else if (error) {
            this.error = error;
            this.fieldPlan = undefined;
        }
    }

    async fetchFieldPlanInfo() {
        try {
            const asyncProcessRunning = await this.territoryFeedbackService.getAsynchronousProcessFlag();
            if (!asyncProcessRunning) {
                this.fieldPlan = await this.territoryFeedbackService.getFieldPlanInfo(this.fieldPlanId);
                this.sortFieldForceTabs();
                this.populateReferenceMaps();
                this.updateParentOfActiveFieldForce(this.parentTerritoryIdOfActiveFieldForce);
                this.loading = false;
            } else {
                throw new AsyncProcessRunningError('An asynchronous process is running against this user\'s data.');
            }
        } catch (serviceError) {
            this.error = serviceError;
            this.handleError(serviceError);
        }
    }

    sortFieldForceTabs() {
        this.fieldPlan.fieldForceModels.sort((fieldForceA, fieldForceB) => fieldForceA.name.localeCompare(fieldForceB.name));
    }

    populateReferenceMaps() {
        this.territoryReferenceMap = this.fieldPlan.createReferenceMapOfTerritories();
        this.fieldForceReferenceMap = this.fieldPlan.createReferenceMapOfFieldForces();

        // Upon first page load, instantiate objects that keep track of the active field force, 
        //     the table metadata associated with the active field force,
        //     and a map of all field forces' current parent territories
        if (!this.fieldForceCurrentParentMap) {
            // Sets active field force to previous active field force when user navigates back from AccountsPage -> FieldForceModelsPage
            this.activeFieldForceId = this.selectedFieldForceId ?? this.fieldPlan.fieldForceModels[0].id;

            this.activeFieldForceTableMetadata = new TerritoryTableMetadata();
            this.activeFieldForceTableMetadata.fieldPlanHasCycle = this.fieldPlan.hasCycle;
            this.setParentTerritoryOfEachFieldForce();
        }
    }
    
    setParentTerritoryOfEachFieldForce() {
        this.fieldForceCurrentParentMap = new Map();
        this.fieldPlan.fieldForceModels.forEach(fieldForce =>{
            let parentId;

            if (fieldForce.id === this.selectedFieldForceId) {
                // If user navigated from AccountsPage -> FieldForceModelsPage, then set this fieldForce's parent to the parent of the territoryModel they navigated from
                const accountsScreenTerritory = this.territoryReferenceMap.get(this.selectedTerritoryModelId);
                parentId = accountsScreenTerritory.parentTerritoryModel?.id;
            } else {
                // If a field force has multiple top-level territories, then set parent as 'null', which indicates that we should display all top-level territories.
                // Otherwise, when only 1 top-level territory, set that as the default parent since the user will have no other choice for navigation.
                parentId = fieldForce.hasMultipleParentTerritoryModels ? null : fieldForce.territoryModels[0]?.id;
            }

            this.fieldForceCurrentParentMap.set(fieldForce.id, parentId)
        });
    }

    updateParentOfActiveFieldForce(newParentTerritoryId) {
        const newParent = this.territoryReferenceMap.get(newParentTerritoryId);
        this.fieldForceCurrentParentMap.set(this.activeFieldForceId, newParent?.id);
        this.updateAvailableActionsForActiveParent();
        this.childTerritories = newParent ? newParent.childTerritoryModels : this.fieldForceReferenceMap.get(this.activeFieldForceId).territoryModels;
        this.updateActiveFieldForceTableMetadata(newParent);
    }

    updateAvailableActionsForActiveParent() {
        if (this.activeParentTerritory) {
            this.availableActionsForActiveParent = this.territoryModelsTable?.getAvailableActionsForTerritory(this.activeParentTerritory) ?? [];
        } else {
            this.availableActionsForActiveParent = [];
        }
    }

    updateActiveFieldForceTableMetadata(parentTerritory) {
        const activeFieldForce = this.fieldForceReferenceMap.get(this.activeFieldForceId);
        const grandparentTerritory = parentTerritory?.parentTerritoryModel; 

        this.activeFieldForceTableMetadata.parentTerritoryName = parentTerritory?.name;
        this.activeFieldForceTableMetadata.allowNavigationUp = 
            this.shouldAllowNavigationUp(grandparentTerritory, parentTerritory, activeFieldForce);
    }

    // User should be able to navigate up when the current parent has its own parent,
    //   or when there are multiple top-level territories underneath the active field force
    shouldAllowNavigationUp(grandparentTerritory, parentTerritory, activeFieldForce) {
        return grandparentTerritory || (parentTerritory && activeFieldForce.hasMultipleParentTerritoryModels);
    }

    handleFieldPlanNavigation() {
        this.forceDisplayFieldPlansPage = true;
        this.goToNextScreen(TerritoryFeedbackConstants.FIELD_PLANS);
    }

    handleAccountsNavigationEvent(event) {
        const {territoryId, filter} = event.detail;
        this.navigateToAccountsScreen(territoryId, filter);
    }

    navigateToAccountsScreen(selectedTerritoryModelId, selectedAccountsFilter) {
        this.selectedFieldForceId = this.activeFieldForceId;
        this.selectedTerritoryModelId = selectedTerritoryModelId;
        this.selectedAccountsFilter = selectedAccountsFilter;
        this.goToNextScreen(TerritoryFeedbackConstants.ACCOUNTS);
    }

    goToNextScreen(screenName) {
        this.nextScreenName = screenName;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleGeoChangeEvent(event) {
        const targetTerritoryId = event.detail.territoryId;
        this.showGeoChangePanel(targetTerritoryId);
    }

    handleInfoEvent() {
        if (this.isPanelOpen && !this.fieldPlanInfoPanel.isGeoChangePanel) {
            this.closePanel();
        } else {
            this.showInfoPanel();
        }
    }

    handlePanelCloseEvent() {
        this.closePanel();
    }

    handleFieldForceTabChange(event) {
        this.closePanel();
        this.activeFieldForceId = event.target.value;
        this.updateParentOfActiveFieldForce(this.parentTerritoryIdOfActiveFieldForce);
    }

    handleChildNavigationEvent(event) {
        this.closePanel();
        this.updateParentOfActiveFieldForce(event.detail.territoryId);
    }

    handleParentNavigationEvent() {
        this.closePanel();
        this.updateParentOfActiveFieldForce(this.activeParentTerritory.parentTerritoryModel?.id);
    }

    handleParentMoreActionsEvent(event) {
        const command = event.detail.value;
        const label = this.getLabelForAction(command);
        this.executeCommand(command, this.activeParentTerritory, label);
    }

    getLabelForAction(name) {
        return this.availableActionsForActiveParent.find(action => action.name === name).label;
    }

    handleCommand(event) {
        const {territoryModel, command, label} = event.detail;
        this.executeCommand(command, territoryModel, label);
    }

    async executeCommand(command, targetTerritory, label) {
        try {
            await FieldForceModelsPageCommandFactory.getInstance(this, targetTerritory, command, label)?.execute();
        } catch (error) {
            this.handleError(error);
        }
    }

    async handleConfirmCommand(event) {
        const selectedButton = event.detail.selectedButton;
        if (this.confirmationCallback) {
            try {
                await this.confirmationCallback(selectedButton);
            } catch (error) {
                this.clearModal();
                this.handleError(error);
            }
        }
    }

    handleCancelCommand() {
        this.clearModal();
    }

    handleUpdateSortParamsEvent(event) {
        ({sortDirection: this.sortDirection, sortedBy: this.sortedBy} = event.detail);
    }
    
    updatePendingChallenges(territoryId) {
        const targetTerritory = this.territoryReferenceMap.get(territoryId);
        targetTerritory.clearPendingChallenges();
    }

    updateTerritoryModels(updatedTerritoryIds, updatedStatus, updatedLifecycleActions, isFeedbackComplete, isFeedback, canReview) {
        updatedTerritoryIds.forEach(territoryId => {
            const territory = this.territoryReferenceMap.get(territoryId);
            territory.lifecycleState = updatedStatus;
            territory.availableLifecycleActions = updatedLifecycleActions;
            territory.canReview = canReview;
            if (territory.isRepLevelTerritoryModel) {
                territory.feedbackComplete = isFeedbackComplete;
                territory.feedback = isFeedback;
            }
        });
        this.updateAvailableActionsForActiveParent();
    }

    // LWCs don't always track changes to properties of "complex" objects stored in arrays,
    //   so re-assigning the array is necessary to force a refresh of the view/component
    refreshTable() {
        this.childTerritories = [...this.childTerritories];
    }

    showModal(modalConfig, confirmationCallback) {
        this.territoryFeedbackModal?.showModal(modalConfig);
        this.confirmationCallback = confirmationCallback;
    }

    clearModal() {
        this.territoryFeedbackModal?.clearModal();
        this.confirmationCallback = null;
    }

    showLoadingSpinner() {
        this.loading = true;
    }

    hideLoadingSpinner() {
        this.loading = false;
    }

    showGeoChangePanel(targetTerritoryId) {
        const targetTerritory = this.territoryReferenceMap.get(targetTerritoryId);

        this.fieldPlanInfoPanel?.populateGeoChangePanel({
            header: targetTerritory.name,
            ...targetTerritory.geoAddedAndDropped
        });

        this.isPanelOpen = true;
    }

    showInfoPanel() {
        this.fieldPlanInfoPanel?.populateInfoPanel({
            header: this.activeParentTerritory?.name,
            startDate: this.fieldPlan.cycleStartDate,
            endDate: this.fieldPlan.cycleEndDate,
            dueDate: this.fieldPlan.dueDate,
            instructions: this.fieldPlan.instructions,
            ...this.geosForActiveParent
        });

        this.isPanelOpen = true;
    }

    closePanel() {
        this.isPanelOpen = false;
    }

    handleError(error) {
        logError(error);
        this.loading = false;
        this.errorHandler?.renderError(error);
        this.error = error;
    }

    get errorHandler() {
        return this.template.querySelector('c-territory-feedback-error-handler');
    }

    get hidePageContent() {
        return this.hasErrorOccurred || this.loading;
    }

    get hasErrorOccurred() {
        return this.error;
    }

    get territoryFeedbackService() {
        return this.territoryFeedbackSvc;
    }

    get isSingleFieldForceModel() {
        return !this.loading && this.fieldPlan?.fieldForceModels.length === 1;
    }

    get territoryFeedbackModal() {
        return this.template.querySelector('c-territory-feedback-modal');
    }

    get fieldPlanInfoPanel() {
        return this.template.querySelector('c-field-plan-info-panel');
    }

    get territoryModelsTable() {
        return this.template.querySelector('c-territory-models-table');
    }

    get territoryTableSize() {
        return this.isPanelOpen ? '9' : '12';
    }

    get sidePanelClass() {
        // lightning-tabset adds additional padding below the table, so if the tabset renders (i.e. !this.isSingleFieldForceModel), 
        // then we need to add the same padding to the bottom of the info panel so that the table and panel align along the bottom
        const paddingClasses = this.isSingleFieldForceModel ? 'slds-p-left_medium' : 'slds-p-left_medium slds-p-bottom_small';
        return this.isPanelOpen ? paddingClasses : 'slds-hide';
    }

    get parentTerritoryIdOfActiveFieldForce() {
        return this.fieldForceCurrentParentMap.get(this.activeFieldForceId);
    }

    get activeParentTerritory() {
        return this.territoryReferenceMap.get(this.parentTerritoryIdOfActiveFieldForce);
    }

    // Returns geos for the active parent territory.
    // If no active parent (i.e. there are multiple top-level territories), then aggregate geos of all top-level territories.
    get geosForActiveParent() {
        if (this.activeParentTerritory) {
            return this.activeParentTerritory.geoAddedAndDropped;
        } else {
            const accumulatedGeoChanges = { geoAdded: [], geoDropped: [] };
            this.childTerritories.forEach(childTerritory => {
                const childTerrGeoChanges = childTerritory.geoAddedAndDropped;
                accumulatedGeoChanges.geoAdded.push(...childTerrGeoChanges.geoAdded);
                accumulatedGeoChanges.geoDropped.push(...childTerrGeoChanges.geoDropped);
            });
            return accumulatedGeoChanges;
        }
    }
}

function logError(error) {
    console.error(error);
}