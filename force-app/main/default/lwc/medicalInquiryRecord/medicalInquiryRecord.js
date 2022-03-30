import VeevaRecord from "c/veevaRecord";
import MedInqConstant from "c/medInqConstant";
import { DeliveryService } from './deliveryService.js';

export default class MedicalInquiryRecord extends VeevaRecord {

    _msgSvc;

    constructor(value, messageSvc) {
        super(value);
        this._msgSvc = messageSvc;
    }

    displayValue(field) {
        let result = '';
        let fldName = field && field.apiName;
        if (fldName === MedInqConstant.ZVOD_DISCLAIMER) {
            result = super.displayValue(MedInqConstant.DISCLAIMER);
            if (!result) {
                result = this._msgSvc.getMessageWithDefault('DISCLAIMER', 'MEDICAL_INQUIRY', '');
                this.setPromisedFieldValue(MedInqConstant.DISCLAIMER, result);
            }
        } else if (fldName !== MedInqConstant.GROUP_IDENTIFIER || this.id) {
            result = super.displayValue(field);
        }
        return result;
    }

    async setPromisedFieldValue(field, promise) {
        this.setFieldValue(field, await promise);
    }

    get delivery() {
        if (!this.deliveryOptions) {
            Object.assign(this, DeliveryService);
        }
        return this;
    }
}