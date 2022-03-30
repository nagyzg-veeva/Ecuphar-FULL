import { LightningElement, api } from 'lwc';

export default class VeevaSidePanel extends LightningElement {
    @api closeEventName = "close";
    @api composed = false;
    @api side = "right"; // Either "left" or "right"

    handleClose() {
        this.dispatchEvent(new CustomEvent(this.closeEventName, { bubbles: true, composed: this.composed }));
    }

    get panelClass() {
        return `slds-panel slds-size_full slds-panel_docked slds-is-open slds-panel_docked-${this.side}`;
    }
}