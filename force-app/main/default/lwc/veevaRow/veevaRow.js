import { LightningElement, api } from "lwc";

export default class VeevaRow extends LightningElement {
    @api pageCtrl;
    @api record;
    @api row;
    @api lastRow;
    @api recordUpdateFlag;

    get sldsItem() {
        let value = "slds-form-element slds-form-element_horizontal";
        if (this.row.layoutItems.length === 1) {
            value += " slds-form-element_1-col";
        }
        if (this.pageCtrl.page.action === 'View') {
            value += ' slds-m-around_none';
            if (!this.lastRow) {
                value += ' slds-form-element_readonly'; // no bottom border
            }
        }
        return value;
    }

    @api checkValidity() {
        const checkRecord = this.record || this.pageCtrl.record;
        if (checkRecord.Deleted) {
            return true;
        }
        let errors = [...this.template.querySelectorAll("c-veeva-item")].filter(item => item.checkValidity() === false);
        return !errors.length;
    }
}