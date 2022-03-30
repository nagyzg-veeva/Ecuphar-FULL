import { LightningElement, api, track } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import TerritoryModelRecord from 'c/territoryModelRecord';
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';
import territoryFeedbackDatatableStyling from "@salesforce/resourceUrl/territoryFeedbackDatatableStyling";
import { loadStyle } from "lightning/platformResourceLoader";

const PADDING_OFFSET = 40;

export default class TerritoryModelsTable extends LightningElement {
    data;
    areVeevaMessagesLoaded;
    _sortDirection = 'asc';
    _sortedBy = 'name';

    @track columns;

    @api messageService;
    @api territoryTableMetadata;

    @api
    get childTerritories() {
        return this.data;
    }

    set childTerritories(childTerritories) {
        this.data = [...childTerritories];
        if (this.areVeevaMessagesLoaded) {
            this.formatData();
            this.sortData();
        }
    }

    @api
    get sortDirection() {
        return this._sortDirection;
    }

    set sortDirection(sortDirection) {
        this._sortDirection = sortDirection;
        this.sortData();
    }

    @api
    get sortedBy() {
        return this._sortedBy;
    }

    set sortedBy(sortedBy) {
        this._sortedBy = sortedBy;
        this.sortData();
    }

    @api
    getAvailableActionsForTerritory(territoryModel) {
        return this.getFormattedActionsForTerritory(territoryModel);
    }

    renderedCallback() {
        this.updateDataTableHeight();
    }

    // Dynamically updates the CSS variable so that the table does not grow beyond the viewport. Instead, the table will have its own scrollbar.
    updateDataTableHeight() {
        const tableTopOffsetAmount = PADDING_OFFSET + this.template.querySelector('.table-container')?.getBoundingClientRect().top;
        this.template.host.style.setProperty('--vertical-offset', `${tableTopOffsetAmount}px`);
    }

    async connectedCallback() {
        await this.loadVeevaMessagesForData();
        await this.initColumns();
        await loadStyle(this, territoryFeedbackDatatableStyling);
        this.dispatchUpdateActionsEvent();
    }

    async loadVeevaMessagesForData() {
        [this.noChangeMessage, this.meMessage, this.completeMessage, this.inProgressMessage, this.approveMessage, this.rejectMessage, this.returnToMessage,
         this.returnAllMessage, this.vacantMessage, this.territoryFeedbackMessage] 
            = await Promise.all([
                this.messageService.getMessageWithDefault('NO_CHANGE', 'Feedback', 'no change'),
                this.messageService.getMessageWithDefault('ME', 'Feedback', '{0} (me)'),
                this.messageService.getMessageWithDefault('COMPLETE', 'Common', 'Complete'),
                this.messageService.getMessageWithDefault('IN_PROGRESS', 'Feedback', 'In Progress'),
                this.messageService.getMessageWithDefault('APPROVE_PENDING_CHALLENGES', 'Feedback', 'Approve Pending Challenges'),
                this.messageService.getMessageWithDefault('REJECT_PENDING_CHALLENGES', 'Feedback', 'Reject Pending Challenges'),
                this.messageService.getMessageWithDefault('RETURN_TO_ROSTER_MEMBER', 'Feedback', 'Return to Roster Member'),
                this.messageService.getMessageWithDefault('RETURN_ALL_TO_ROSTER_MEMBERS', 'Feedback', 'Return all to Roster Members'),
                this.messageService.getMessageWithDefault('VACANT', 'Feedback', 'vacant'),
                this.messageService.getMessageWithDefault('FEEDBACK_MENU_ITEM', 'Feedback', 'Territory Feedback')
            ]);
    }

    async initColumns() {
        const [territoryMessage, rosterMemberMessage, statusMessage, geoChangesMessage, totalChallengesMessage, pendingApprovalMessage,
               personAccountsMessage, businessAccountsMessage, targetsMessage] 
            = await Promise.all([
                this.messageService.getMessageWithDefault('TERRITORY', 'Feedback', 'Territory'),
                this.messageService.getMessageWithDefault('ROSTER_MEMBER', 'Feedback', 'Roster Member'),
                this.messageService.getMessageWithDefault('STATUS', 'Common', 'Status'),
                this.messageService.getMessageWithDefault('GEO_CHANGES', 'Feedback', 'Geo Changes'),
                this.messageService.getMessageWithDefault('TOTAL_CHALLENGES', 'Feedback', 'Total Challenges'),
                this.messageService.getMessageWithDefault('PENDING_APPROVAL', 'Feedback', 'Pending Approval'),
                this.messageService.getMessageWithDefault('PERSON_ACCOUNTS', 'Common', 'Person Accounts'),
                this.messageService.getMessageWithDefault('BUSINESS_ACCOUNTS', 'Common', 'Business Accounts'),
                this.messageService.getMessageWithDefault('TARGETS', 'Feedback', 'Targets')
            ]);

        this.columns = [
            { type: 'action', hideDefaultActions: true, typeAttributes: { rowActions: { fieldName: 'availableActions' }, menuAlignment: 'auto' },
                cellAttributes: { class: { fieldName: 'moreActionsMenuClass' } } },

            { type: 'button-with-styling', label: territoryMessage, fieldName: 'name', sortable: true, hideDefaultActions: true,
                typeAttributes: { clickHandler: { fieldName: 'navigationHandler' } , id: { fieldName: 'id' }, disabled: { fieldName: 'isRepLevelTerritoryModel' } } },

            { type: 'text', hideDefaultActions: true, label: rosterMemberMessage, fieldName: 'rosterMembersDisplay', sortable: true },

            { type: 'text-with-icon-variant', label: statusMessage, fieldName: 'statusDisplay', hideDefaultActions: true, 
                typeAttributes: { iconName: { fieldName: 'statusIconName' }, iconVariant: 'success', iconClass: 'slds-p-left_x-small' }, sortable: true },

            // These columns are buttons, but condtionally styled to look like normal text when not actionable
            { type: 'geo-changes-button', label: geoChangesMessage, hideDefaultActions: true, 
                typeAttributes: { clickHandler: { fieldName: 'geoChangeHandler' } , id: { fieldName: 'id' }, disabled: { fieldName: 'geoChangeDisabled' }, 
                    numGeosAdded: { fieldName: 'numGeoAdded' }, numGeosDropped: { fieldName: 'numGeoDropped' }, noChangeLabel: this.noChangeMessage } },

            { type: 'button-with-styling', label: totalChallengesMessage, fieldName: 'numChallenges', sortable: true, hideDefaultActions: true,
                typeAttributes: { clickHandler: { fieldName: 'totalChallengesHandler' } , id: { fieldName: 'id' }, disabled: { fieldName: 'disableTotalChallenges' }, isNumeric: true } }, 

            { type: 'button-with-styling', label: pendingApprovalMessage, fieldName: 'numPendingChallenges', sortable: true, hideDefaultActions: true,
                typeAttributes: { clickHandler: { fieldName: 'pendingChallengesHandler' } , id: { fieldName: 'id' }, disabled: { fieldName: 'disablePendingChallenges' }, isNumeric: true } },

            { type: 'button-with-styling', label: targetsMessage, fieldName: 'numTargets', sortable: true, hideDefaultActions: true,
                typeAttributes: { clickHandler: { fieldName: 'targetsHandler' } , id: { fieldName: 'id' }, disabled: { fieldName: 'hasNoTargets' }, isNumeric: true } },

            { type: 'button-with-styling', label: personAccountsMessage, fieldName: 'numPersonAccounts', sortable: true, hideDefaultActions: true,
                typeAttributes: { clickHandler: { fieldName: 'personAccountsHandler' } , id: { fieldName: 'id' }, disabled: { fieldName: 'hasNoPersonAccounts' }, isNumeric: true } },

            { type: 'button-with-styling', label: businessAccountsMessage, fieldName: 'numBusinessAccounts', sortable: true, hideDefaultActions: true,
                typeAttributes: { clickHandler: { fieldName: 'businessAccountsHandler' } , id: { fieldName: 'id' }, disabled: { fieldName: 'hasNoBusinessAccounts' }, isNumeric: true } }
        ];

        // this.data property might have been set before Veeva Messages loaded, so we need to format and sort the data
        this.formatData();
        this.sortData();
        this.areVeevaMessagesLoaded = true;
    }

    // Used to let parent know that this is done rendering, so parent can call this.getAvailableActionsForTerritory on the parent territory model
    dispatchUpdateActionsEvent() {
        this.dispatchEvent(new CustomEvent('updateactions'));
    }

    handleRowAction(event) {
        const row = event.detail.row;
        const action = event.detail.action.name;
        const label = event.detail.action.label;
        this.dispatchCommandEvent(row, action, label);
    }

    navigationHandler(event) {
        const id = event.currentTarget.value;

        this.dispatchEvent(new CustomEvent('navigatetoterritory', {
            detail: {
                territoryId: id
            }
        }));
    }

    geoChangeHandler(event) {
        const id = event.currentTarget.value;

        this.dispatchEvent(new CustomEvent('viewgeochange', {
            detail: {
                territoryId: id
            }
        }));
    }

    totalChallengesHandler(event) {
        const id = event.currentTarget.value;
        this.dispatchAccountsScreenNavigationEvent(id, TerritoryFeedbackConstants.ALL_CHALLENGES);
    }

    pendingChallengesHandler(event) {
        const id = event.currentTarget.value;
        this.dispatchAccountsScreenNavigationEvent(id, TerritoryFeedbackConstants.PENDING_CHALLENGES);
    }

    personAccountsHandler(event) {
        const id = event.currentTarget.value;
        this.dispatchAccountsScreenNavigationEvent(id, TerritoryFeedbackConstants.PERSON_ACCOUNTS);
    }

    businessAccountsHandler(event) {
        const id = event.currentTarget.value;
        this.dispatchAccountsScreenNavigationEvent(id, TerritoryFeedbackConstants.BUSINESS_ACCOUNTS);
    }

    targetsHandler(event) {
        const id = event.currentTarget.value;
        this.dispatchAccountsScreenNavigationEvent(id, TerritoryFeedbackConstants.TARGETS);
    }

    dispatchAccountsScreenNavigationEvent(targetTerritoryId, filter) {
        this.dispatchEvent(new CustomEvent('navigatetoaccounts', {
            detail: {
                territoryId: targetTerritoryId,
                filter: filter
            }
        }));
    }

    handleNavigateUp() {
        this.dispatchEvent(new CustomEvent('navigatetoparent'));
    }

    dispatchCommandEvent(targetTerritoryModel, commandName, commandLabel) {
        this.dispatchEvent(new CustomEvent('command', {
            detail: {
                territoryModel: targetTerritoryModel,
                command: commandName,
                label: commandLabel
            }
        }));
    }

    onHandleSort(event) {
        this.dispatchEvent(new CustomEvent('updatesortparams', {
            detail: {
                sortDirection: event.detail.sortDirection,
                sortedBy: event.detail.fieldName
            }
        }));
    }

    formatData() {
        this.data.forEach(territory => {
            territory.rosterMembersDisplay = this.formatRosterMembers(territory);
            territory.statusDisplay = this.formatStatus(territory);
            territory.availableActions = this.getFormattedActionsForTerritory(territory);
            territory.disablePendingChallenges = this.shouldDisablePendingChallenges(territory);
            territory.disableTotalChallenges = this.shouldDisableTotalChallenges(territory);
            territory.navigationHandler = this.navigationHandler.bind(this);
            territory.geoChangeHandler = this.geoChangeHandler.bind(this);
            territory.totalChallengesHandler = this.totalChallengesHandler.bind(this);
            territory.pendingChallengesHandler = this.pendingChallengesHandler.bind(this);
            territory.targetsHandler = this.targetsHandler.bind(this);
            territory.personAccountsHandler = this.personAccountsHandler.bind(this);
            territory.businessAccountsHandler = this.businessAccountsHandler.bind(this);
        });
    }

    sortData() {
        if (this.sortDirection && this.sortedBy) {
            const primerFunc = isNumericField(this.sortedBy) ? parseIntWithDefault : (val) => val.toUpperCase();
            this.data = [...this.data.sort(sortBy(this.sortedBy, this.sortDirection === 'asc' ? 1 : -1, primerFunc))];
        }
    }

    formatRosterMembers(territoryModel) {
        if (territoryModel.rosterMembers.length) {
            return territoryModel.rosterMembers.map(rosterMember => {
                if (rosterMember.me) {
                    return this.meMessage.replace('{0}', rosterMember.name);
                } else {
                    return rosterMember.name;
                }
            }).join(', ');
        } else {
            return `<${this.vacantMessage}>`;
        }
    }

    formatStatus(territoryModel) {
        return territoryModel.isRepLevelTerritoryModel ? this.getRepLevelTerritoryStatus(territoryModel) : this.getManagerLevelTerritoryStatus(territoryModel);
    }

    getRepLevelTerritoryStatus(territoryModel) {
        if (territoryModel.feedbackComplete) {
            return this.completeMessage;
        } else if (territoryModel.feedback) {
            return this.territoryFeedbackMessage;
        } else {
            return territoryModel.lifecycleState;
        }
    }

    getManagerLevelTerritoryStatus(territoryModel) {
        return territoryModel.feedbackComplete ? this.completeMessage : this.inProgressMessage;
    }

    getFormattedActionsForTerritory(territoryModel) {
        const availableActions = [];
        availableActions.push(...(territoryModel.isRepLevelTerritoryModel ? this.getRepLevelLifecycleStateActions(territoryModel) : this.getManagerLevelLifecycleStateActions(territoryModel)));
        return availableActions.sort(sortMoreActions);
    }

    getRepLevelLifecycleStateActions(territoryModel) {
        const availableActions = territoryModel.availableLifecycleActions.map(lifecycleStateAction => {
            if (lifecycleStateAction.name === TerritoryModelRecord.FEEDBACK_STATE) {
                return {
                    label: this.returnToMessage,
                    name: 'return_to_roster_member',
                    displayIndex: 5
                };
            } else {
                return {
                    label: lifecycleStateAction.label,
                    name: lifecycleStateAction.name,
                    displayIndex: 3
                };
            }
        });

        if (territoryModel.canReviewPendingChallenges) {
            availableActions.push({ label: this.approveMessage, name: 'approve_pending_challenges', displayIndex: 1 });
            availableActions.push({ label: this.rejectMessage, name: 'reject_pending_challenges', displayIndex: 2 });
        }

        return availableActions;
    }

    getManagerLevelLifecycleStateActions(territoryModel) {
        const availableActionsMap = new Map();
        territoryModel.repLevelChildTerritories.forEach(childTerritoryModel => {
            childTerritoryModel.availableLifecycleActions.forEach(lifecycleAction => {
                availableActionsMap.set(lifecycleAction.name, lifecycleAction.label);
            });
        });

        const lifecycleActions = [];
        availableActionsMap.forEach((actionLabel, actionName) => {
            if (actionName === TerritoryModelRecord.FEEDBACK_STATE) {
                lifecycleActions.push({
                    label: this.returnAllMessage,
                    name: 'return_all_to_roster_members',
                    displayIndex: 6
                });
            } else {
                lifecycleActions.push({
                    label: actionLabel,
                    name: actionName,
                    displayIndex: 4
                });
            }
        });

        if (territoryModel.canReviewPendingChallenges) {
            lifecycleActions.push({ label: this.approveMessage, name: 'approve_pending_challenges', displayIndex: 1 });
            lifecycleActions.push({ label: this.rejectMessage, name: 'reject_pending_challenges', displayIndex: 2 });
        }

        return lifecycleActions;
    }

    shouldDisablePendingChallenges(territoryModel) {
        return territoryModel.isManagerLevelTerritoryModel || !territoryModel.numPendingChallenges;
    }

    shouldDisableTotalChallenges(territoryModel) {
        return territoryModel.isManagerLevelTerritoryModel || !territoryModel.numChallenges;
    }
}

function sortBy(field, reverse, primer) {
    const key = (primer ? x => primer(x[field]) : x => x[field]);

    return (a, b) => {
        a = key(a);
        b = key(b);
        return reverse * ((a > b) - (b > a));
    };
}

function isNumericField(fieldName) {
    return fieldName !== 'name' && fieldName !== 'rosterMembersDisplay' && fieldName !== 'statusDisplay';
}

function parseIntWithDefault(int) {
    const parsedInt = parseInt(int);
    return parsedInt ? parsedInt : 0;
}

// Sorts using displayIndex first. If those are equal, then sorts alphabetically.
function sortMoreActions(firstAction, secondAction) {
    const indexComparison = firstAction.displayIndex - secondAction.displayIndex;
    return indexComparison ? indexComparison : firstAction.label.localeCompare(secondAction.label, LOCALE);
}