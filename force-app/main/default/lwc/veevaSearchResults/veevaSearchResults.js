import { LightningElement, api, track } from 'lwc';

export default class VeevaSearchResults extends LightningElement {
    @api messageSvc;
    @api searchRecords;
    @api resultTitle;
    @api columns;
    @api enableInfiniteLoading;
    @api hideCheckbox;

    @track labelNoRecords;
    @track labelResult;
    @track labelResults;

    async connectedCallback() {
        await this.loadMessages();
    }

    async loadMessages() {
        const [noRecordsMsg, resultsMsg, resultMsg] = await Promise.all([
            this.messageSvc.getMessageWithDefault('NO_RECORDS', 'Common', 'No Results'),
            this.messageSvc.getMessageWithDefault('RESULTS', 'Common', '{0} Results'),
            this.messageSvc.getMessageWithDefault('RESULT', 'Common', 'Result')
        ]);

        this.labelNoRecords = noRecordsMsg;
        this.labelResults = resultsMsg;
        this.labelResult = resultMsg;
    }

    handleRowSelection(event) {
        event.stopPropagation();
        const row = event.detail.selectedRows[0];
        const selected = this.searchRecords.find(result => result.id === row.id) || {};
        this.dispatchEvent(new CustomEvent('rowselection', { detail: selected }));
    }

    handleLoadMore() {
        this.dispatchEvent(new CustomEvent('loadmoredata'));
    }

    get count() {
        return this.searchRecords && this.searchRecords.length;
    }

    get countsLabel() {
        let resultStr = this.labelResults;
        if (this.count === 1) {
            resultStr = `{0} ${this.labelResult}`;
        }
        const plusCharacter = this.enableInfiniteLoading ? '+' : '';
        return this.count && resultStr ? resultStr.replace('{0}', `${this.count}${plusCharacter}`) : '';
    }

    get noResults() {
        return this.count === 0;
    }
}