import { LightningElement, api, track } from "lwc";
import VeevaConstant from 'c/veevaConstant';

export default class MedInqDeliveryMethod extends LightningElement {
    @api item; // zvodDeliveryMethodController
    @api get method() {
        return this._method;
    }
    set method(value) {
        this._method = value;
        this.initialize();
    }
    @api isPrimaryMethod;
    @api isLast;
    @api newOption = false; //new address, email, fax or phone
    @track selected = {};
    @track options;
    @track textCtrl;
    @track checked;

    async initialize() {
        if (this.item && this.method) {
            this.selected = await this.item.selected(this.method.signal);
            if (this.item.actionView) {
                this.textCtrl = { label: this.method.label, displayValue: this.selected.label, editable: false, dataType: this.method.dataType };
            }
            else {
                this.initializeCheckbox();
                this.initializeOptions();
            }
        }
    }
    async initializeOptions() {
        let options = await this.item.options(this.method.signal);
        let newModeNotCloneNotCopy = this.item.isNewModeNotCloneNotCopy();

        let matchedOption = this.selected && options.find(x => x.value === this.selected.value);
        if (this.method && this.method.signal){
            if (this.method.signal === "eom"){
                matchedOption = this.selected && options.find(x => x.Address_Line_1_vod__c === this.selected.Address_Line_1_vod__c 
                                  && x.Address_Line_2_vod__c === this.selected.Address_Line_2_vod__c
                                  && x.City_vod__c === this.selected.City_vod__c);
                if (matchedOption){
                    this.selected.label = this.selected.value = matchedOption.value;
                }
            }
        }
        if (!newModeNotCloneNotCopy && this.selected && this.selected.value && !matchedOption && this.newOption && this.method.checkbox) {
            this.checked = true;
        }
        else {
            this.checked = false;
        }
        const none = await this.item.pageCtrl.getMessageWithDefault('NONE', 'Common', '--None--');
        options = [{ label: none, value: '' }, ...options];
        this.options = options;
    }

    initializeCheckbox() {
        if (this.method.checkbox && !this.method.checkbox.setFieldValue) {
            this.method.checkbox.setFieldValue = (checked) => {
                this.checked = checked;
                this.selected = {};
                this.item.toggleNewOption(this.method.signal);
            }
        }
    }

    get border() {
        return !this.isLast ? 'slds-form-element_readonly' : '';
    }

    get required() {
        return this.isPrimaryMethod && !this.checked;
    }

    handleChange(event) {
        let value = event.target.value;
        let obj = this.options.find(elem => elem.value === value);
        return this.item.handleChange(obj, this.method.signal);
    }

    @api checkValidity() {
        let errors = [...this.template.querySelectorAll("[data-validity]")].filter(item => item.checkValidity() === false);
        let success = !errors.length;
        let combobox = this.template.querySelector('lightning-combobox');
        if (combobox && !combobox.reportValidity()) {
            success = false;
        }
        return success;
    }

    get readOnly() {
        return this.checked || (this.isPrimaryMethod && this.item.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD));
    }

}