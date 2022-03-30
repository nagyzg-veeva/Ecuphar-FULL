import { LightningElement, api, track } from "lwc";
import MedInqConstant from 'c/medInqConstant';

export default class MedInqDelivery extends LightningElement {
    @api ctrl;
    @track methods = { optionalMethods: [] };

    @api 
    get recordUpdateFlag(){
        return this._recordUpdateFlag;
    }

    set recordUpdateFlag(value){
        this._recordUpdateFlag = value;
        this.ctrl.getMethods().then((methods) => {
            this.methods = { optionalMethods: [] };
            this.methods = methods;
        });
    }

    async connectedCallback() {
        this.ctrl.pageCtrl.track(MedInqConstant.DELIVERY_METHOD, this, "deliveryMethodChanged");
        this.ctrl.pageCtrl.track(MedInqConstant.ACCOUNT, this, "accountChanged");
        this.methods = await this.ctrl.getMethods();
    }

    async deliveryMethodChanged(value) {
        await this.resetMethods(value);
    }

    async accountChanged() {
        await this.resetMethods();
    }

    async resetMethods(value) {
        //clear this.methods first, to trigger the tracked methods.optionalMethods
        this.methods = { optionalMethods: [] };
        this.methods = await this.ctrl.getMethods(value);
        this.ctrl.clearAllValues();
    }

    @api checkValidity() {
        let errors = [...this.template.querySelectorAll("c-med-inq-delivery-method")].filter(item => item.checkValidity() === false);
        return !errors.length;
    }
}