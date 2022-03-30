import { api, LightningElement } from "lwc";

export default class GasUserFilterItem extends LightningElement {

    _options = [];

    @api label;
    @api selectedOptions;

    @api get options() {
        return this._options;
    }

    set options(values) {
        this._options = [...values];
    }

    addSelectedOption(event) {
        const value = event.detail.value;
        const label = this.options.find(option => option.value === value).label
        if (this.selectedOptions.every(selectedOption => selectedOption.name !== value)) {
            this.dispatchEvent(new CustomEvent("add", { detail: { label: label, name: value }}));
        }
        const currentTarget = event.currentTarget;
        // Clears the selected value since the selected value was already added
        currentTarget.value = null;
    }

    removeSelectedOption(event) {
        const indexToRemove = event.detail.index;
        this.dispatchEvent(new CustomEvent("remove", { detail: { index: indexToRemove }}));
    }
}