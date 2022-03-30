import { LightningElement, api, track } from 'lwc';

// TODO: discrepancy between this and Salesforce's search
export default class VeevaSearch extends LightningElement {
    @api ctrl;
    @api searchTerm;
    @track searchRecords;
    @track labelCancel;
    @track columns;
    @track resultTitle;
    @track label;
    @track nextPageUrl;
    @track enableInfiniteLoading;
    @track isLoadingMore;

    async connectedCallback() {
        this.enableInfiniteLoading = false;
        await Promise.all(
            [this.loadMessages(), this.setLabels(), this.setColumnsAndSearch()]
        );
    }

    async loadMessages() {
        this.labelCancel = await this.ctrl.pageCtrl.getMessageWithDefault(
            'CANCEL', 'Common', 'Cancel'
        );
    }

    async setLabels() {
        this.objectInfo = await this.ctrl.getTargetObjectInfo();
        this.resultTitle = this.objectInfo.labelPlural;
        this.label = this.objectInfo.label;
    }

    async setColumnsAndSearch() {
        this.columns = await this.ctrl.getColumns();
        await this.getSearchRecords();
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent("searchclose", { detail: { search: false, term: '' } }));
    }

    handleLookupSelection(event) {
        this.dispatchEvent(new CustomEvent("searchselection", { detail: event.detail }));
    }

    handleRowSelection(event) {
        this.dispatchEvent(new CustomEvent("searchselection", { detail: event.detail }));
    }

    startSearch(event) {
        event.stopPropagation();
        this.searchTerm = event.detail.term;
        this.getSearchRecords();
    }

    async getSearchRecords() {
        if (this.searchTerm) {
            this.nextPageUrl = null;
            let response = await this.ctrl.searchWithColumns(this.searchTerm);
            this.searchRecords = response.records
            this.nextPageUrl = response.nextPageUrl;
            this.enableInfiniteLoading = response.nextPageUrl ? true : false;
        }
    }

    async handleLoadMoreData() {
        if (this.nextPageUrl && !this.isLoadingMore) {
            this.isLoadingMore = true;
            const response = await this.ctrl.searchWithColumns(this.searchTerm, this.nextPageUrl);
            this.searchRecords = this.searchRecords.concat(response.records);
            this.nextPageUrl = response.nextPageUrl;
            this.enableInfiniteLoading = response.nextPageUrl ? true : false;
            this.isLoadingMore = false;
        }
    }

    get hideCheckbox() {
        return true;
    }
}