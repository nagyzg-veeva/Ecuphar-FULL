import VeevaBaseController from 'c/veevaBaseController';
import MedInqConstant from 'c/medInqConstant';
import { MethodLayout } from './methodLayout.js';
import { getAddressText } from "c/addressVod";
import template from './zvodDeliveryMethodController.html';

const METHOD_TO_SIGNAL = { "Mail_vod": "eom", "Urgent_Mail_vod": "eom", "Email_vod": "eoe", "Phone_vod": "eop", "Fax_vod": "eof" };
const SIGNALS = ["eom", "eoe", "eop", "eof"];

export default class ZvodDeliveryMethodController extends VeevaBaseController {

    initTemplate() {
        this.template = template;
        return this;
    }

    async getMethods(value) {
        let deliveryMethod = value || this.data.rawValue(MedInqConstant.DELIVERY_METHOD);
        let primary = await this.primaryMethod(deliveryMethod);
        let optionalMethods = await this.optionalMethods();
        let result = { primaryMethod: primary, optionalMethods: optionalMethods };
        optionalMethods.forEach(x => { x.render = !primary || x.signal !== primary.signal; });
        if (primary) {
            primary.primaryOnly = !optionalMethods.filter(x => x.render).length;
        }
        return result;
    }

    clearAllValues() {
        this.data.delivery.clear(Object.values(MedInqConstant.NEW_FIELDS).flat());
    }

    async primaryMethod(method) {
        if (method) {
            let signal = METHOD_TO_SIGNAL[method];
            return this.methodLayout.describeMethod(signal, true);
        }
        return null;
    }

    async optionalMethods() {
        if (!this._optionalMethods) {
            let signals = SIGNALS.filter(x => this.meta.options.includes(x));
            this._optionalMethods = await Promise.all(signals.map(signal =>
                this.methodLayout.describeMethod(signal)));
        }
        return this._optionalMethods;
    }

    get methodLayout() {
        if (!this.describeMethod) {
            Object.assign(this, MethodLayout);
        }
        return this;
    }

    isNewModeNotCloneNotCopy(){
        return this.pageCtrl.isNew && !this.pageCtrl.isClone && !this.data.isMPICopy;
    }

    async selected(method) {
        return this.data.delivery.selectedDelivery(method, await this.statePicklists(), await this.countryPicklists());
    }

    async options(method) {
        let result = await this.data.delivery.deliveryOptions(method);
        if (method === 'eom') {
            let state = await this.statePicklists();
            let country = await this.countryPicklists();

            result.forEach(option => {
                option.label = getAddressText(option, state, country);
                option.value = option.label;
                option.Address_Line_1_vod__c = option.Name;
                delete option.Name;
                option.Address_Line_2_vod__c = option.Address_line_2_vod__c;
                delete option.Address_line_2_vod__c;
            });
        }
        else {
            result = result.map(option => ({ 'label': option, 'value': option }));
        }
        return result;
    }

    handleChange(values, method) {
        this.data.delivery.stampMethodFields(values, method);
    }

    toggleNewOption(method) {
        this.data.delivery.clear(MedInqConstant.NEW_FIELDS[MedInqConstant.SIGNALS_MAP[method]]);
    }

    async statePicklists() {
        if (!this._statePicklists) {
            this._statePicklists = await this.pageCtrl.uiApi.getPicklistValues(this.recordTypeId, MedInqConstant.MEDICAL_INQUERY, MedInqConstant.STATE);
        }
        return this._statePicklists;
    }

    async countryPicklists() {
        if (!this._countryPicklists) {
            this._countryPicklists = await this.pageCtrl.uiApi.getPicklistValues(this.recordTypeId, MedInqConstant.MEDICAL_INQUERY, MedInqConstant.COUNTRY);
        }
        return this._countryPicklists;
    }
}