import { api, wire, track, LightningElement } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import EmEventConstant from 'c/emEventConstant';
import getMsgWithDefault from "@salesforce/apex/VeevaMessageController.getMsgWithDefault";

export default class EmDetailTabPage extends LightningElement {
    @api objectApiName;
    @api recordId;

    @track relatedLists = [];

    @wire(getMsgWithDefault, { key: 'PAGE_LAYOUT_TITLE', category: 'Common', defaultMessage: 'Details' })
    detailLabel;

    get hasRelatedLists() {
        return this.relatedLists.length > 0;
    }

    connectedCallback() {
        registerListener(EmEventConstant.POPULATE_RELATED_LIST_TABS, this.populateTabs, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    populateTabs(payload) {
        this.relatedLists = payload.relatedLists;
        this.pageCtrl = payload.pageCtrl;
    }

    handleActive(event) {
        const relatedList = event.target.querySelector('c-veeva-related-list-table');
        if (relatedList) {
            relatedList.resetRecords();
        }
    }
}