import { LightningElement, api } from "lwc";
import VeevaToastEvent from "c/veevaToastEvent";

// default lightning-input has its label on the right
export default class VeevaFieldCheckbox extends LightningElement {
    @api value;

    @api get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        this._ctrl = value;
        this.value = this.ctrl.rawValue;
    }

    get checked() {
        return this.value || this.ctrl.rawValue;
    }

    handleChange(event) {
        this.ctrl.setFieldValue(event.target.checked ? true : false);

        const changedEvent = new CustomEvent("change");
        this.dispatchEvent(changedEvent);
    }

    setError(error) {
        this.dispatchEvent(VeevaToastEvent.error(error));
    }
}