import { LightningElement, api, track } from "lwc";

const OPEN_ICON = "utility:chevrondown";
const CLOSE_ICON = "utility:chevronright";
const OPEN_CLASS = "slds-section slds-is-open";
const CLOSE_CLASS = "slds-section slds-is-close";

export default class SectionTemplate extends LightningElement {
    @api ctrl;
    @api first;
    @track expanderIcon;
    @track sectionClass;
    @api recordUpdateFlag;
 
    @api get open() {
        return this._open;
    }

    set open(value) {
        this._open = value;
        this.expanderIcon = this._open ? OPEN_ICON : CLOSE_ICON;
        this.sectionClass = this._open ? OPEN_CLASS : CLOSE_CLASS;
    }

    toggleSection() {
        this.open = !this.open;
    }

    @api checkValidity() {
        let errors = [...this.template.querySelectorAll("c-veeva-row")].filter(item => item.checkValidity() === false);
        return !errors.length;
    }
}