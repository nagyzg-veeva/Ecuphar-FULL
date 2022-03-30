import { LightningElement, api, track } from "lwc";

export default class VeevaCombobox extends LightningElement {
    @api get ctrl() {
        return this._ctrl;
    }

    set ctrl(value) {
        this.selected = "";
        if (value) {
            const firstTime = !this._ctrl;
            this._ctrl = value;
            if (this._ctrl.track) {
                this._ctrl.track(this, "updateOptions");
            }
            this.setOptionsAndSelected(firstTime);
        }
    }

    get disabled() {
        return !this.ctrl.editable || !this.hasOptions;
    }

    get isDisplayable() {
        return this.options && !this.ctrl.readonly;
    }

    get hasOptions() {
        let hasOptions = this.options && this.options.length > 0;
        if (hasOptions) {
            hasOptions = this.options.length > 1 || this.options[0].value;
        }
        return hasOptions;
    }

    @api excludeNone;
    @track options;
    @track selected;
    @track label;

    async setOptionsAndSelected(firstTime) {
        this.label = undefined;
        let options = await this.ctrl.picklists;

        // set default value on New
        if (this.ctrl.pageCtrl.action === 'New' && !this.ctrl.selected && this.ctrl.selected !== "") {
            this.ctrl.setFieldValue(this.ctrl.defaultValue);
        }

        // get label for picklist value
        if (this.ctrl._metaOptions) {
            let values = this.ctrl._metaOptions.values;
            for (let i = 0; i < values.length; i++) {
                if (values[i].value === this.ctrl.selected && values[i].label) {
                    this.label = values[i].label;
                    break;
                }
            }
        }
        if (!this.label) {
            this.label = this.ctrl.selected;
        }

        // check if selected option is not in list of options
        if (this.ctrl.selected && this.label && !options.find(option => option.value === this.ctrl.selected)) {
            if (firstTime && this.ctrl.pageCtrl.action !== 'New') {
                // allow invalid option on initialization on View and Edit
                options = [{ label: this.label, value: this.ctrl.selected }, ...options];
            } else {
                // remove invalid option on New or existing picklist
                this.ctrl.setFieldValue('');
                this.label = '';
            }
        }

        const none = await this.ctrl.pageCtrl.getMessageWithDefault('NONE', 'Common', '--None--');
        if (this.ctrl.required && options.length === 1) {
            // default to only available option when there is one option and field is required
            this.ctrl.setFieldValue(options[0].value);
        } else if (!this.excludeNone) {
            // add --None-- option
            options = [{ label: none, value: '' }, ...options];
            if (!this.ctrl.selected && this.ctrl.selected !== '') {
                // use --None-- option for null or undefined values
                this.ctrl.setFieldValue('');
            }
        }

        this.selected = this.ctrl.selected;
        this.options = options;
    }

    updateOptions(value, source) {
        this.ctrl.controllingValue = value;
        this.setOptionsAndSelected(false);
        source = source || "ControllingFieldChanged";
        const changedEvent = new CustomEvent("change", { detail: source });
        this.dispatchEvent(changedEvent);
    }

    handleChange(event) {
        this.ctrl.setFieldValue(event.target.value);
        this.selected = event.target.value;
    }

    @api checkValidity() {
        let element = this.template.querySelector("lightning-combobox");
        if (!element) {
            return true;
        }
        if (element.checkValidity()) {
            this.ctrl.validate();
            element.setCustomValidity(this.ctrl.getError());
        }
        return element.reportValidity();
    }
}