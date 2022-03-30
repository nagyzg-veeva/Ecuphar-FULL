import { LightningElement, api, track } from 'lwc';

export default class VeevaFieldFormula extends LightningElement {
    @track value;
    calcOnSaveMsg;

    @api 
    get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        this._ctrl = value;
        this.retrieveDisplayValue();
    }

    async connectedCallback() {
        const msg = await this.ctrl.pageCtrl.getMessageWithDefault('FORMULA_PLACEHOLDER', 'Common', 'This field is calculated upon save');
        this.calcOnSaveMsg = msg;
    }

    async retrieveDisplayValue(){
        this.value = await this.ctrl.displayValue;
    }

    get isActionEdit(){
        return this.ctrl.pageCtrl.action === 'Edit';
    }
}