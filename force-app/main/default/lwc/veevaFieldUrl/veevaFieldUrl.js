import { LightningElement, api, track } from 'lwc';

export default class VeevaFieldUrl extends LightningElement {
    @track url;

    @api
    get ctrl(){
       return this._ctrl;
    }

    set ctrl(value){
        this._ctrl = value;
        if (this._ctrl) {
            this.url = this._ctrl.displayValue;
        }
    }
}