import { LightningElement, api, track } from "lwc";

//TODO #of visible lines is set to default 4 as it is not available in layout
export default class VeevaMultiPicklist extends LightningElement {
    @api get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        this.selected = "";
        this._ctrl = value;
        this.initialize();
        this._ctrl.track(this, "updateOptions");
    }

    @track options;
    @track selected;

    @track labelSelected;
    @track labelAvailable;

    async connectedCallback() {
        this.labelSelected = await this.ctrl.pageCtrl.getMessageWithDefault(
            "SELECTED_ITEMS",
            "Common",
            "Selected"
        );
        this.labelAvailable = await this.ctrl.pageCtrl.getMessageWithDefault(
            "AVAILABLE",
            "Common",
            "Available"
        );
    }

    get values() {
        return this.selected ? this.selected.split(';') : [];
    }

    get disabled() {
        return !this.ctrl.editable || !this.hasOptions;
    }

    get isDisplayable() {
        return this.options && !this.ctrl.readonly;
    }

    get hasOptions() {
        return this.options && this.options.length > 0;
    }

    get selectedList(){
        return this.selected ? this.selected.replaceAll(";",", ") : null; 
    }

    async initialize() {
        this.options = await this.ctrl.picklists;
        this.selected = this.ctrl.selected;
    }

    @api updateOptions(value, source) {
        this.ctrl.controllingValue = value;
        this.initialize();
        source = source || "ControllingFieldChanged";
        const changedEvent = new CustomEvent("change", { detail: source });
        this.dispatchEvent(changedEvent);
    }

    handleChange(event) {
        this.ctrl.setFieldValue(event.detail.value.join(";"));
    }

    @api checkValidity() {
        let element = this.template.querySelector("lightning-dual-listbox");
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