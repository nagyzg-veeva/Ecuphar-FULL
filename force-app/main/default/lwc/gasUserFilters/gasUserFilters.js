import { api, LightningElement, track } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import DEFAULT_ACCOUNT_USER_FILTERS from './defaultUserFilters'

export default class GasUserFilters extends LightningElement {

    _accountObjectInfo;
    _accountPicklistValues;

    applyLabel;
    clearFilterLabel;
    filtersLabel;

    @track filters = [];

    /**
     * @type {VeevaObjectInfo}
     */
    @api get accountObjectInfo() {
        return this._accountObjectInfo;
    }

    set accountObjectInfo(value) {
        this._accountObjectInfo = value;
        this.updateFilters();
    }

    /**
     * Result from getPicklistValuesByRecordType for Account object
     */
    @api get accountPicklistValues() {
        return this._accountPicklistValues;
    }

    set accountPicklistValues(value) {
        this._accountPicklistValues = value;
        this.updateFilters();
    }

    async connectedCallback() {
        const veevaMessageService = getPageController('messageSvc');
        await this.loadVeevaMessages(veevaMessageService);
    }

    async loadVeevaMessages(veevaMessageService) {
        [this.applyLabel, this.clearFilterLabel, this.filtersLabel] = await Promise.all([
            veevaMessageService.getMessageWithDefault('APPLY', 'Common', 'Apply'),
            veevaMessageService.getMessageWithDefault('CLEAR_FILTER', 'Common', 'Clear'),
            veevaMessageService.getMessageWithDefault('GAS_FILTERS', 'Global Account Search', 'Filters')
        ]);
    }

    updateFilters() {
        this.filters = this.getUserAccessibleFiltersWithAppropriateLabel();
        this.updateFilterOptions();
    }

    getUserAccessibleFiltersWithAppropriateLabel() {
        const userAccessibleFilters = [];
        if (this.accountObjectInfo) {
            // We will check Account Filter Items that the user has FLS access
            const userAccessibleAccountFilters = DEFAULT_ACCOUNT_USER_FILTERS
                .filter(filterItem => filterItem.objectApiName === ACCOUNT_OBJECT.objectApiName && this.accountObjectInfo.fields[filterItem.fieldApiName])
                .map(filterItem => {
                    const appropriateLabel = this.accountObjectInfo.fields[filterItem.fieldApiName].label;
                    return {
                        ...filterItem,
                        label: appropriateLabel
                    };
                });
            userAccessibleFilters.push(...userAccessibleAccountFilters);
        }
        return userAccessibleFilters;
    }

    updateFilterOptions() {
        if (this.accountPicklistValues && this.filters) {
            // We will populate any Account Filter Items options from Picklist Field Values
            this.filters
                .filter(filterItem => filterItem.objectApiName === ACCOUNT_OBJECT.objectApiName && this.accountPicklistValues.picklistFieldValues[filterItem.fieldApiName])
                .forEach(filterItem => {
                    const fieldPicklistValues = this.accountPicklistValues.picklistFieldValues[filterItem.fieldApiName]
                    filterItem.options = fieldPicklistValues.values;
                });
        }
    }

    handleAddFilterItemSelected(event) {
        const filterKey = event.target.dataset.key;
        const filter = this.filters.find(filter => filter.key === filterKey);
        const selectedOption = event.detail;
        filter.selectedOptions.push(selectedOption);
    }

    handleRemoveFilterItemSelected(event) {
        const filterKey = event.target.dataset.key;
        const filter = this.filters.find(filter => filter.key === filterKey);
        const index = event.detail.index;
        filter.selectedOptions.splice(index, 1);
    }

    clearFilters() {
        this.filters.forEach(filter => {
            filter.selectedOptions.splice(0, filter.selectedOptions.length);
        });
    }

    applyFilters() {
        this.dispatchEvent(new CustomEvent('apply', {
            detail: {
                userFilters: this.filters
            }
        }));
    }
}