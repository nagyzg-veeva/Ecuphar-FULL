import { LightningElement, wire, api, track } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";
import { getObjectInfos, getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import IMPLICIT_FILTER_OBJECT from '@salesforce/schema/Implicit_Filter_vod__c';
import IMPLICIT_FILTER_CONDITION_OBJECT from '@salesforce/schema/Implicit_Filter_Condition_vod__c';
import searchAccounts from "@salesforce/apex/VeevaGlobalAccountSearchController.searchAccounts";
import VeevaToastEvent from "c/veevaToastEvent";
import GasRecordTypeIconConfig from "c/gasRecordTypeIconConfig";
import account_record_type_icons from '@salesforce/resourceUrl/account_record_type_icons';
import VeevaObjectInfo from 'c/veevaObjectInfo';
import VeevaRecord from 'c/veevaRecord';

const MAX_LIGHTNING_LAYOUT_ITEM_SIZE = 12;

export default class GlobalAccountSearch extends LightningElement {
    accountObjName;
    accountObjectInfo;
    accountPicklistValues;
    resultCount = 0;
    enableAddToTerritory = false;
    showAddTerritory = false;
    loading;
    searchCalled = false;
    gasRecTypeIconConfig;
    customRecTypesIconSetting;
    errorMessage = 'An error occurred when performing the search';
    noSearchResultsMessage = 'No matches found.';
    cannotCreateAccounts = false;
    disableNewAccount = true;
    showUserFilters = false;
    accountSearchString;
    addressSearchString;
    sortColumn;
    sortDirection;
    userFilters;
    userFiltersSize = 3;
    minColumnWidth=100;
    
    objectNames = [ACCOUNT_OBJECT, IMPLICIT_FILTER_OBJECT, IMPLICIT_FILTER_CONDITION_OBJECT];

    @track searchResultColumns = [];
    @track formattedSearchResults = [];
    @track accountTypeOptions = [];
    selectedAccountIds = [];    

    get gasNavigator() {
        return this.template.querySelector('c-gas-navigator');
    }

    get datatableSize() {
        return this.showUserFilters ? MAX_LIGHTNING_LAYOUT_ITEM_SIZE - this.userFiltersSize : MAX_LIGHTNING_LAYOUT_ITEM_SIZE;
    }

    get gasHeader() {
        return this.template.querySelector('c-gas-header');
    }

    get noSearchResults() {
        return !this.loading && this.formattedSearchResults?.length === 0;
    }

    async connectedCallback(){
        const veevaMessageService = getPageController('messageSvc');
        await this.loadVeevaMessages(veevaMessageService);
        this.gasRecTypeIconConfig = new GasRecordTypeIconConfig(this.customRecTypesIconSetting);
    }

    @wire(getObjectInfos, { objectApiNames: '$objectNames' })
    async wiredObjectInfo({ error, data }) {
        if (data) {
            const objectInfos = data.results;
            const accountObjectInfo = objectInfos[0].result;
            this.accountObjectInfo = new VeevaObjectInfo(accountObjectInfo);
            this.accountObjName = accountObjectInfo.label;
            this.cannotCreateAccounts = !accountObjectInfo.createable;
        } else if (error) {
            console.error(error);
            this.setError(error);
        }
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: ACCOUNT_OBJECT, recordTypeId: VeevaRecord.MASTER_RECORD_TYPE_ID })
    async wiredAccountPicklistValues({ error, data }) {
        if (error) {
            this.setError(this.errorMessage);
        } else if (data) {
            this.accountPicklistValues = data;
        }
    }

    async handleSearchEvent(event){
        event.stopPropagation();
        this.accountSearchString = event.detail.accountSearchText;
        this.addressSearchString = event.detail.addressSearchText;
        this.accountTypeFilter = event.detail.accountType;
        this.userFilters = event.detail.userFilters;
        //Reset sort in each new search
        const sortInfo = {};
        this.sortColumn = null;
        this.sortDirection = null;
        await this.performSearch(sortInfo);
        this.disableNewAccount = false;
    }

    async performSearch(sortInfo){
        this.loading = true;
        this.searchCalled = true;
        try { 
            const result = await searchAccounts({searchText: this.accountSearchString, locationSearchText: this.addressSearchString, accountType: this.accountTypeFilter, userFilters: this.userFilters, sortConditions: sortInfo });
            this.setSearchResultHeaders(result.fields);
            this.formatSearchResults(result.records);
        } catch (e){
            this.setError(e);
            this.loading = false;
        }
        this.loading = false;
    }

    setSearchResultHeaders(resultMetadata){
        const colHeaders = [];
        if (resultMetadata && resultMetadata.length > 0){
            resultMetadata.forEach(columnInfo => {
                const column = { label : columnInfo.label, fieldName : columnInfo.fieldName, sortable: 'true'  };
                if (column.fieldName === 'Account.Name'){
                    column.type = 'account-name-display';
                    column.typeAttributes = {
                        id: { fieldName: 'Account.Id' },
                        isButton: { fieldName: 'insideTerritory' },
                        recordTypeIconUrl : {fieldName : 'recTypeIconUrl' } , 
                        recordTypeName : {fieldName : 'recTypeName' },
                        clickHandler: this.navigateToAccountHandler.bind(this)
                    };
                    column.cellAttributes = { iconName: { fieldName: 'accountIcon' }, iconPosition: 'left', iconAlternativeText: 'Account' };
                }
                colHeaders.push(column);
            });
        }
        this.searchResultColumns = colHeaders;
    }

    formatSearchResults(resultSet){
        if (resultSet && resultSet.length > 0){
            this.resultCount = resultSet.length;
            resultSet.forEach(record => {
                record.recTypeName = record['Account.RecordTypeId.Name'];
                record.recTypeIconUrl = this.getRecordTypeIconUrl(record);
            });
            this.formattedSearchResults = resultSet;
        } else {
            this.resultCount = 0;
            this.formattedSearchResults = [];
        }
    }

    createNewAccount() {
        this.gasNavigator.navigateToNewAccountWizard();
        this.disableNewAccount = true;
    }
    
    handleApplyUserFilters(event) {
        const userFilters = event.detail.userFilters?.map(userFilter => ({
            objectApiName: userFilter.objectApiName,
            fieldApiName: userFilter.fieldApiName,
            selectedOptions: userFilter.selectedOptions.map(selectedOption => selectedOption.name)
        }));
        this.gasHeader.handleSearchWithUserFilters(userFilters);
    }

    toggleUserFilters() {
        this.showUserFilters = !this.showUserFilters;
    }

    async loadVeevaMessages(veevaMessageService){
        [this.errorMessage, this.customRecTypesIconSetting, this.noSearchResultsMessage] = await Promise.all([
            veevaMessageService.getMessageWithDefault('GAS_SEARCH_ERROR', 'Global Account Search', this.errorMessage),
            veevaMessageService.getMessageWithDefault('ACCOUNT_RECORD_TYPE_ICON_MAP', 'Common', ''),
            veevaMessageService.getMessageWithDefault('NO_MATCH_FOUND', 'Common', this.noSearchResultsMessage)
        ]);
    }

    async setError(e){
        const errMsg = (e.body && e.body.message) ? e.body.message : this.errorMessage;
        const error = { message: errMsg};
        this.dispatchEvent(VeevaToastEvent.error(error, "sticky"));
    }

    navigateToAccountHandler(event) {
        const accountId = event.currentTarget.title;
        this.gasNavigator.navigateToViewAccount(accountId);
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        const selectedAccountIdSet = new Set(this.selectedAccountIds);
        this.selectedAccountIds = selectedRows
            .filter(row => !row.insideTerritory)
            .filter(row => !selectedAccountIdSet.has(row['Account.Id']))
            .map(row => row['Account.Id']);

        this.enableAddToTerritory = this.selectedAccountIds.length > 0;
    }

    handleAccountAddedToTerritory(event) {
        const accountId = event.detail.accountId;
        const accountInSearchResults = this.formattedSearchResults?.find(searchResult => searchResult['Account.Id'] === accountId);
        if (accountInSearchResults) {
            accountInSearchResults.insideTerritory = true;
            accountInSearchResults.recTypeIconUrl = this.getRecordTypeIconUrl(accountInSearchResults);
            // Forces the lightning-datatable to recognize that the data has been updated
            this.formattedSearchResults = [...this.formattedSearchResults]
        }
    }

    getRecordTypeIconUrl(record) {
        return account_record_type_icons + this.gasRecTypeIconConfig.getIconUrlForRecordType(record['Account.RecordTypeId.Name'], record['Account.IsPersonAccount'], record.insideTerritory);
    }

    addTerritory() {
        this.showAddTerritory = true;
        this.accountIdToAddToTerritory = this.selectedAccountIds[0];
    }

    closeAddTerritory() {
        this.showAddTerritory = false;
    }

    showToast(event) {
        const { message, variant } = event.detail;
        if (variant === 'success') {
            this.dispatchEvent(VeevaToastEvent.successMessage(message));
        } else {
            this.dispatchEvent(VeevaToastEvent.error({
                message: message
            }));
        }
    }

    searchModified() {
        this.disableNewAccount = true;
    }

    performSort(event) {
        this.sortColumn = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        const sortInfo = {'sortColumn': this.sortColumn, 'sortDirection': this.sortDirection};
        this.performSearch(sortInfo);
    }
}