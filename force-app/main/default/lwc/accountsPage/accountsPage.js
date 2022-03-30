import { LightningElement, api, track, wire } from 'lwc';
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import TerritoryFeedbackService from 'c/territoryFeedbackService';
import getTerritoryFeedbackSettings from '@salesforce/apex/TerritoryFeedbackSettings.getTerritoryFeedbackSettings';
import VeevaMessageService from 'c/veevaMessageService';
import { loadStyle } from "lightning/platformResourceLoader";
import territoryFeedbackDatatableStyling from "@salesforce/resourceUrl/territoryFeedbackDatatableStyling";
import AccountsPageCommandFactory from 'c/accountsPageCommandFactory';
import { COLUMN_PREFIXES } from 'c/accountRecord';
import AccountsTableDetailsRecord from 'c/accountsTableDetailsRecord';
import getVodInfo from '@salesforce/apex/SessionVod.getVodInfo';
import LANG from '@salesforce/i18n/lang';
import Id from '@salesforce/user/Id';

const NON_ALPHANUMERICS_REGEX = /[^\p{L}\p{M}\p{N}]/gu;

const PADDING_OFFSET = 32;
const ACCOUNTS_BATCH_SIZE = 30;

const CHANNEL_CLASS = 'channel';
const FIRST_CHANNEL_IN_GROUP = 'first-channel-in-group';
const PRODUCT_CLASS = 'product'; 
const LAST_PRODUCT_IN_GROUP = 'last-product-in-group';
const GOAL_CLASS = 'goal';
const NAME_FIELD = 'name';

const STRING = 'STRING';
const BOOLEAN = 'BOOLEAN';
const DATE = 'DATE';
const DATETIME = 'DATETIME';
const NUMBER =  'NUMBER';
const GOAL = 'GOAL';

const ALIGN_TO_TABLE_TYPE_MAP = new Map([
    [STRING, 'styled-text'],
    [BOOLEAN, 'styled-text'],
    [DATE, 'styled-date-time'],
    [DATETIME, 'styled-date-time'],
    [NUMBER, 'styled-number'],
    [GOAL, 'goal']
]);

export default class AccountsPage extends LightningElement {
    @api selectedTerritoryModelId;
    @api selectedAccountsFilter;
    @api nextScreenName;
    @api forceDisplayFieldPlansPage;

    @track tableMetadata;
    @track selectedRows = [];
    @track error;

    _data = [];
    messageService;
    veevaMessagesLoaded = false;
    fieldNameToAlignTypeMap = new Map();
    sortedBy = NAME_FIELD;
    sortDirection = 'asc';
    columns;
    searchableFieldNames = [NAME_FIELD];
    isPanelOpen;
    loading = true;
    isTableLoading = true;
    currentRenderInterval;
    currentRenderIndex;
    searchQuery = '';

    get pageHeaderTitle() {
        if (!this.tableMetadata) {
            return null
        } else {
            const rosterMemberName = this.tableMetadata.rosterMembers.length ? this.tableMetadata.rosterMembers[0].name : `<${this.vacantMessage}>`;
            return `${rosterMemberName} (${this.tableMetadata.name})`;
        }
    }

    get pageHeaderSubtitle() {
        switch(this.selectedAccountsFilter) {
            case TerritoryFeedbackConstants.TARGETS:
                return this.targetsMessage;
            case TerritoryFeedbackConstants.ALL_CHALLENGES:
                return this.allChallengesMessage;
            case TerritoryFeedbackConstants.PENDING_CHALLENGES:
                return this.pendingChallengesMessage;
            case TerritoryFeedbackConstants.BUSINESS_ACCOUNTS:
                return this.businessAccountsMessage;
            case TerritoryFeedbackConstants.PERSON_ACCOUNTS:
                return this.personAccountsMessage;
        }
    }

    get hasClientSideFilter() {
        return this.selectedAccountsFilter === TerritoryFeedbackConstants.BUSINESS_ACCOUNTS || this.selectedAccountsFilter === TerritoryFeedbackConstants.PERSON_ACCOUNTS;
    }

    get sidePanelClass() {
        return this.isPanelOpen ? 'slds-p-left_medium' : 'slds-hide';
    }

    get accountsTableSize() {
        return this.isPanelOpen ? '9' : '12';
    }

    get sortBy() {
        const reverse = (this.sortDirection === 'asc') ? 1 : -1;
    
        return (a, b) => {
            a = this.primer(a);
            b = this.primer(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    get primer() {
        const fieldType = this.fieldNameToAlignTypeMap.get(this.sortedBy);
        if (fieldType === NUMBER || fieldType === GOAL) {
            return val => parseFloatWithDefault(val[this.sortedBy]);
        } else {
            return val => parseStringWithDefault(val[this.sortedBy]);
        }
    }

    get fieldPlanInfoPanel() {
        return this.template.querySelector('c-field-plan-info-panel');
    }

    get selectedAccountIds() {
        return this.selectedRows.map(row => row.id);
    }

    get territoryFeedbackService() {
        return this.territoryFeedbackSvc;
    }

    get hidePageContent() {
        return this.loading || this.error;
    }

    get errorHandler() {
        return this.template.querySelector('c-territory-feedback-error-handler');
    }

    // Works around fact that the lightning-datatable loading spinner doesn't render properly when the datatable is empty.
    // When table is empty, a majority of the loading spinner is truncated.
    get showTableSpinner() {
        return this.isTableLoading && this.data.length > 0;
    }

    get allAccounts() {
        return this.tableMetadata?.accounts;
    }

    get data() {
        return this._data;
    }

    // Once all of the data is loaded, it's faster to re-render the entire table than to
    // batch re-load the table, e.g. when sorting on a new column.
    set data(data) {
        if (data.length !== this._data.length) {
            this.loadDataInBatches(data);
        } else {
            this._data = [...data];
        }
    }

    // Loads data in batches of ACCOUNTS_BATCH_SIZE to allow the user to view and interact with a partially-rendered table,
    // rather than forcing the user to wait for the entire table to render.
    loadDataInBatches(dataToLoad) {
        // "Interrupts" any currently-running render
        clearInterval(this.currentRenderInterval);
        this.isTableLoading = true;
        this._data = [];
        this.currentRenderIndex = 0;
        this.currentRenderInterval = setInterval(() => {
            this._data = this._data.concat(dataToLoad.slice(this.currentRenderIndex, this.currentRenderIndex + ACCOUNTS_BATCH_SIZE));
            this.currentRenderIndex += ACCOUNTS_BATCH_SIZE;

            // Stop once all data is loaded
            if (this.currentRenderIndex >= dataToLoad.length) {
                this.isTableLoading = false;
                clearInterval(this.currentRenderInterval);
            }
        }, 0);
    }

    renderedCallback() {
        this.updateTablePanelContainerHeight();
    }

    // Dynamically updates the CSS variable so that the table and info panel do not grow beyond the viewport. Instead, nested components will have their own scrollbar.
    updateTablePanelContainerHeight() {
        const tableTopOffsetAmount = PADDING_OFFSET + this.template.querySelector('.table-panel-container')?.getBoundingClientRect().top;
        this.template.host.style.setProperty('--vertical-offset', `${tableTopOffsetAmount}px`);
    }

    async connectedCallback() {
        await this.loadStyles();
    }

    // Load CSS static resource, then adjust background color of product columns to be a semi-transparent version of the brandLightActive color
    async loadStyles() {
        await loadStyle(this, territoryFeedbackDatatableStyling);
        const transparentBrandLightActive = getComputedStyle(this.template.host).getPropertyValue('--lwc-brandLightActive').replace('1)', '0.5)');
        this.template.host.style.setProperty('--transparent-brand-light-active', transparentBrandLightActive);
    }

    // CRM-234394 temporarily add auth query params to every request
    // Remove after ALN-25276 is resolved
    @wire(getTerritoryFeedbackSettings)
    getTerritoryModelDetails({ error, data }) {
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
                this.loadTable();
            }
        } else if (error) {
            this.handleError(error);
        }
    }

    async loadTable() {
        await this.instantiateMessageService();
        try {
            if (this.hasClientSideFilter) {
                this.tableMetadata = new AccountsTableDetailsRecord(await this.territoryFeedbackService.getTerritoryModelDetails(this.selectedTerritoryModelId));
                this.tableMetadata.accounts = this.filterAccounts(this.tableMetadata.accounts, this.selectedAccountsFilter);
            } else {
                this.tableMetadata = new AccountsTableDetailsRecord(
                    await this.territoryFeedbackService.getTerritoryModelDetails(this.selectedTerritoryModelId, this.selectedAccountsFilter));
            }

            this.initColumns();

            await this.tableMetadata.formatTableData(this.messageService);

            this.loading = false;
            this.data = this.tableMetadata.accounts;
        } catch (serviceError) {
            this.handleError(serviceError);
        }
    }

    async instantiateMessageService() {
        this.messageService = new VeevaMessageService();
        await this.messageService.loadVeevaMessageCategories(['Feedback', 'View', 'Account', 'Common']);
        [this.allChallengesMessage, this.targetsMessage, this.pendingChallengesMessage, this.fieldPlansMessage, this.vacantMessage, this.searchMessage,
            this.personAccountsMessage, this.businessAccountsMessage, this.challengeMessage, this.accountNameMessage, this.statusMessage,
            this.reasonsMessage, this.acceptMessage, this.rejectMessage, this.segmentMessage]
            = await Promise.all([
                this.messageService.getMessageWithDefault('ALL_CHALLENGES', 'Feedback', 'All Challenges'),
                this.messageService.getMessageWithDefault('TARGETS', 'Feedback', 'Targets'),
                this.messageService.getMessageWithDefault('PENDING_CHALLENGES', 'Feedback', 'Pending Challenges'),
                this.messageService.getMessageWithDefault('FIELD_PLANS', 'Feedback', 'Field Plans'),
                this.messageService.getMessageWithDefault('VACANT', 'Feedback', 'vacant'),
                this.messageService.getMessageWithDefault('SEARCH', 'Common', 'Search'),
                this.messageService.getMessageWithDefault('PERSON_ACCOUNTS', 'Common', 'Person Accounts'),
                this.messageService.getMessageWithDefault('BUSINESS_ACCOUNTS', 'Common', 'Business Accounts'),
                this.messageService.getMessageWithDefault('CHALLENGE_TYPE', 'Feedback', 'Challenge Type'),
                this.messageService.getMessageWithDefault('ACCOUNT_NAME', 'Account', 'Account Name'),
                this.messageService.getMessageWithDefault('STATUS', 'Common', 'Status'),
                this.messageService.getMessageWithDefault('REASONS', 'Feedback', 'Reason(s)'),
                this.messageService.getMessageWithDefault('SIGNATURE_ACCEPT', 'Common', 'Accept'),
                this.messageService.getMessageWithDefault('REJECT', 'Common', 'Reject'),
                this.messageService.getMessageWithDefault('SEGMENT', 'Feedback', 'Segment: {0}')
            ]);
        this.veevaMessagesLoaded = true;
    }

    filterAccounts(accounts, accountsFilter) {
        const shouldFilterForPersonAccounts = accountsFilter === TerritoryFeedbackConstants.PERSON_ACCOUNTS;
        return accounts.filter(account => account.person === shouldFilterForPersonAccounts);
    }

    // Initialize the 5 static columns, then conditionally generate the other 4 column types
    initColumns() {
        this.columns = [
            { type: 'text-with-icon-variant', label: this.accountNameMessage, fieldName: NAME_FIELD, sortable: true, initialWidth: 175,
                typeAttributes: { iconName: { fieldName: 'iconName' }, leftAlignIcon: true, iconClass: { fieldName: 'iconClass' } }, hideDefaultActions: true},
            { type: 'text', label: this.challengeMessage, fieldName: 'challengeTypeDisplay', sortable: true, initialWidth: 130, hideDefaultActions: true },
            { type: 'text', label: this.statusMessage, fieldName: 'challengeStatusDisplay', sortable: true, hideDefaultActions: true },
            { type: 'text', label: this.reasonsMessage, fieldName: 'reasonsDisplay', sortable: true, hideDefaultActions: true },
        ];

        // Only add the "More Actions" menus when the manager has review/edit access
        if (this.tableMetadata.canReview) {
            this.columns.unshift({ type: 'action', typeAttributes: { rowActions: { fieldName: 'availableActions' }, menuAlignment: 'auto' },
                hideDefaultActions: true, cellAttributes: { class: { fieldName: 'moreActionsMenuClass' } } });
        }

        if (this.tableMetadata.cyclePresent) {
            this.addGoalColumns(this.tableMetadata.goalMetadata);
        }

        if (this.tableMetadata.accountDetailMetadata) {
            this.addAccountAndAddressColumns(this.tableMetadata.accountDetailMetadata);
        }

        if (this.tableMetadata.productMetricMetadata.length) {
            this.addProductMetricColumns(this.tableMetadata.productMetricMetadata);
        }

        if (this.tableMetadata.cyclePresent) {
            this.addSegmentColumns(this.tableMetadata.segmentMetadata);
        }
    }

    // Adds a stand-alone column for each channel, and then an additonal column for each (channel, product) pair
    addGoalColumns(channels) {
        channels.forEach((channel, channelIndex) => {
            this.addColumn(channel.channelLabel, `${COLUMN_PREFIXES.GOAL}${channelIndex}`, GOAL, this.getClassesForChannel(channelIndex, true));

            channel.products.forEach((product, productIndex) => {
                const cssClasses = this.getClassesForProduct(productIndex, channel.products.length);

                this.addColumn(`${channel.channelLabel}\n(${product.productLabel})`,
                               `${COLUMN_PREFIXES.GOAL}${channelIndex}_${productIndex}`,
                               GOAL,
                               cssClasses);
            });
        });
    }

    addAccountAndAddressColumns(accountDetails) {
        accountDetails.forEach((accountDetail, detailIndex) => {
            const accountFieldName = `${COLUMN_PREFIXES.DETAIL}${detailIndex}`;
            this.addColumn(accountDetail.label, accountFieldName, accountDetail.type, null);
            if (accountDetail.type === STRING) {
                this.searchableFieldNames.push(accountFieldName);
            }
        });
    }

    // Adds a single column for each (metric, product) pair
    addProductMetricColumns(productMetrics) {
        productMetrics.forEach((productMetric, productMetricIndex) => {
            const dataType = productMetric.productMetricLabel.type;

            productMetric.productLabels.forEach((productLabel, productLabelIndex) => {
                this.addColumn(`${productMetric.productMetricLabel.label}\n(${productLabel})`,
                               `${COLUMN_PREFIXES.METRIC}${productMetricIndex}_${productLabelIndex}`,
                               dataType,
                               null);
            });
        });
    }

    // Very similar to goals columns, just with differing fieldNames
    addSegmentColumns(channels) {
        channels.forEach((channel, channelIndex) => {
            const channelSegment = this.segmentMessage.replace('{0}', channel.channelLabel);
            this.addColumn(channelSegment, `${COLUMN_PREFIXES.SEGMENT}${channelIndex}`, STRING, this.getClassesForChannel(channelIndex, false));

            channel.products.forEach((product, productIndex) => {
                this.addColumn(`${channelSegment}\n(${product.productLabel})`,
                               `${COLUMN_PREFIXES.SEGMENT}${channelIndex}_${productIndex}`,
                               STRING,
                               this.getClassesForProduct(productIndex, channel.products.length));
            });
        });
    }

    addColumn(columnLabel, fieldName, fieldType, cellClasses) {
        this.fieldNameToAlignTypeMap.set(fieldName, fieldType);

        this.columns.push({
            type: ALIGN_TO_TABLE_TYPE_MAP.get(fieldType),
            label: columnLabel,
            fieldName: fieldName,
            sortable: true,
            cellAttributes: { class: cellClasses },
            typeAttributes: this.getTypeAttributes(fieldType, fieldName),
            hideDefaultActions: true
        });
    }

    getClassesForChannel(channelIndex, isGoal) {
        let channelClass = CHANNEL_CLASS;
        if (channelIndex === 0) {
            channelClass = channelClass.concat(' ', FIRST_CHANNEL_IN_GROUP);
        }
        if (isGoal) {
            channelClass = channelClass.concat(' ', GOAL_CLASS);
        }
        
        return channelClass;
    }

    getClassesForProduct(productIndex, numProducts) {
        return (productIndex === (numProducts - 1)) ? `${PRODUCT_CLASS} ${LAST_PRODUCT_IN_GROUP}` : PRODUCT_CLASS;
    }

    getTypeAttributes(alignType, fieldName) {
        const typeAttributes = {};

        if (alignType === DATE) {
            typeAttributes.isDateTime = false;
        } else if (alignType === DATETIME) {
            typeAttributes.isDateTime = true;
        } else if (fieldName.startsWith(COLUMN_PREFIXES.GOAL)) {
            typeAttributes.difference = { fieldName: `${fieldName}_difference` };
            typeAttributes.differenceIsPositive = { fieldName: `${fieldName}_differenceIsPositive` };
            typeAttributes.isNull = { fieldName: `${fieldName}_isNull` };
        }

        return typeAttributes;
    }

    sortData(event) {
        ({sortDirection: this.sortDirection, fieldName: this.sortedBy} = event.detail);
        this.data = this.data.sort(this.sortBy);
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.filter(account => account.hasChallenge);
    }

    handleRowAction(event) {
        const row = event.detail.row;
        const action = event.detail.action.name;

        this.executeChallengesCommand(action, [row]);
    }

    handleApproveChallenges() {
        this.executeChallengesCommand(AccountsPageCommandFactory.APPROVE, this.selectedRows.filter(account => account.shouldAllowApprove));
    }

    handleRejectChallenges() {
        this.executeChallengesCommand(AccountsPageCommandFactory.REJECT, this.selectedRows.filter(account => account.shouldAllowReject));
    }

    handleFieldPlanNavigation() {
        this.forceDisplayFieldPlansPage = true;
        this.goToNextScreen(TerritoryFeedbackConstants.FIELD_PLANS);
    }

    handleTerritoriesNavigation() {
        this.goToNextScreen(TerritoryFeedbackConstants.TERRITORIES);
    }

    goToNextScreen(screenName) {
        this.nextScreenName = screenName;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleInfoEvent() {
        if (!this.isPanelOpen) {
            this.showInfoPanel();
        } else {
            this.closeInfoPanel();
        }
    }

    handlePanelCloseEvent() {
        this.closeInfoPanel();
    }

    showInfoPanel() {
        if (this.fieldPlanInfoPanel) {
            this.fieldPlanInfoPanel.populateInfoPanel({
                header: this.tableMetadata.name,
                startDate: this.tableMetadata.startDate,
                endDate: this.tableMetadata.endDate,
                dueDate: this.tableMetadata.dueDate,
                instructions: this.tableMetadata.instructions,
                geoAdded: this.tableMetadata.geoAdded,
                geoDropped: this.tableMetadata.geoDropped
            });
    
            this.isPanelOpen = true;
        }
    }

    closeInfoPanel() {
        this.isPanelOpen = false;
    }

    async executeChallengesCommand(commandName, accounts) {
        try {
            await AccountsPageCommandFactory.getInstance(this, commandName, accounts)?.execute();
        } catch (error) {
            this.handleError(error);
        }
    }

    async updateChallengeStatusDisplay(updatedAccountRows, updatedChallengeStatus, updatedTargetChallengeStatus) {
        for (const account of updatedAccountRows) {
            account.challengeStatus = updatedChallengeStatus ?? account.challengeStatus;
            account.targetChallengeStatus = updatedTargetChallengeStatus ?? account.targetChallengeStatus;
            await account.format(this.messageService, this.tableMetadata.canReview);
        }
    }

    // LWCs don't always track changes to properties of "complex" objects stored in arrays,
    //   so re-assigning the array is necessary to force a refresh of the view/component
    refreshTable() {
        this.data = [...this.data];
    }

    unselectRows() {
        this.selectedRows = [];
    }

    handleError(error) {
        logError(error);
        this.loading = false;
        this.errorHandler?.renderError(error);
        this.error = error;
    }

    handleSearch(event) {        
        this.searchQuery = event.target.value;
        if (this.searchQuery) {
            this.executeSearch(this.searchQuery);
        } else {
            this.data = this.allAccounts.sort(this.sortBy);
        }
    }

    executeSearch(query) {
        const searchTokens = this.tokenizeQuery(query);
        this.data = this.searchAccounts(searchTokens).sort(this.sortBy);
    }

    // Replaces non-alphanumeric characters (determined by Unicode properties) with spaces, then filters out any empty strings created by the split function
    tokenizeQuery(queryString) {
        return queryString.toLowerCase().replace(NON_ALPHANUMERICS_REGEX, ' ').split(' ').filter(token => token.length > 0);
    }

    // Returns every row that contains all of the elements in searchTokens - these tokens do not need to appear in the same field
    searchAccounts(searchTokens) {
        return this.allAccounts.filter(row => {
            return searchTokens.every(token => {
                return this.searchableFieldNames.some(field => row[field]?.toLowerCase().includes(token));
            });
        });
    }
}

function parseFloatWithDefault(float) {
    const parsedFloat = parseFloat(float);
    return parsedFloat ? parsedFloat : 0;
}

function parseStringWithDefault(string) {
    return string?.toUpperCase() ?? '';
}

function logError(error) {
    console.error(error);
}