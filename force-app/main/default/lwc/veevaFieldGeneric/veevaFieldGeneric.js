import { LightningElement, api } from "lwc";

export default class VeevaFieldGeneric extends LightningElement {
    @api ctrl;
    @api labelHidden;

    connectedCallback() {
        if (this.ctrl.actionView) {
            this.sldsText = 'slds-form-element__static';
        }
        else {
            this.sldsText = 'slds-form-element__static slds-p-top_xx-small';
        }
    }
}