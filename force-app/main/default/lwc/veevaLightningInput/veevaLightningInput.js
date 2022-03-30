import { LightningElement, api, track } from "lwc";
import VeevaConstant from "c/veevaConstant";

export default class VeevaLightningInput extends LightningElement {
    @api get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        
        this._ctrl = value; 

        this.retrieveValue();
    }

    async retrieveValue(){
        let result = await this.ctrl.value;
        this.display = result.displayValue || result.value;
        this.value = result.value;
    }

    get step() {
        if (this.ctrl.digits || this.ctrl.digits === 0){
            return (Math.pow(10,  (-1) * this.ctrl.digits).toFixed(this.ctrl.digits));
        }
        return 0.01;
    }
    @track display;
    @track value;

    handleChange(event) {
        event.preventDefault();
        window.clearTimeout(this.delayTimeout);
        this.value = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            this.ctrl.setFieldValue(this.value);
        }, VeevaConstant.DEBOUNCE_DELAY);
    }

    @api checkValidity() {
        let element = this.template.querySelector("lightning-input");
        if (element.checkValidity()) {
            this.ctrl.validate();
            element.setCustomValidity(this.ctrl.getError());
        }
        return element.reportValidity();
    }
}