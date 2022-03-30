import { LightningElement, api } from 'lwc';

export default class VeevaButtonCancel extends LightningElement {
    @api meta;
    @api disableButton;

    handleCancel() {
        this.dispatchEvent(
            new CustomEvent("close", { bubbles: true, composed: true })
        );
    }
}