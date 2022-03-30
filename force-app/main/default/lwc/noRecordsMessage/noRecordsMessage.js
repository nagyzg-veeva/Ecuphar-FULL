import { LightningElement, api } from 'lwc';

export default class NoRecordsMessage extends LightningElement {

    @api listData;
    @api ctrl;
    msgNoRecords;

    get noResults() {
        return this.listData.length === 0;
    }

    async connectedCallback() {
        this.msgNoRecords = await this.ctrl.pageCtrl.getMessageWithDefault(
            'NO_RECORDS', 'Common', 'No Results'
        );
    }
}