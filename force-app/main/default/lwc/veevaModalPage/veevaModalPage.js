import { LightningElement, api } from 'lwc';

export default class VeevaModalPage extends LightningElement {
    @api pageCtrl;
    @api page;
    @api disableButton;

    @api checkValidity() {
        let errors = [...this.template.querySelectorAll("c-veeva-section")].filter(item => item.checkValidity() === false);
        return !errors.length;
    }

    get waiting() {
        return !this.page.layout || this.page.requests.length;
    }

}