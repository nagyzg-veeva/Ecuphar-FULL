import { LightningElement, track, api } from 'lwc';
export default class VeevaFieldLookup extends LightningElement {

    @api ctrl;
    @track searchTerm = '';

    get isMultiobject() {
        return this.ctrl 
            && this.ctrl.meta 
            && this.ctrl.meta.objectList;
    }

    handleSelection(evt) {
        this.stopSearch();
        this.ctrl.setFieldValue(evt.detail.id, evt.detail);

        const changedEvent = new CustomEvent("change");
        this.dispatchEvent(changedEvent);
    }

    handleClear() {
        this.ctrl.setFieldValue(null);
        const changedEvent = new CustomEvent("change");
        this.dispatchEvent(changedEvent);
    }

    startSearch(event) {
        this.searchTerm = event.detail.term;
    }

    stopSearch() {
        this.searchTerm = '';
    }

    @api checkValidity() {
        let element = this.template.querySelector("c-veeva-lookup");
        return !element || element.checkValidity();
    }
}