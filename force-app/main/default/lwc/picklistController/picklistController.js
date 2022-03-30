import FieldController from "c/fieldController";
import VeevaUtils from 'c/veevaUtils';

export default class PicklistController extends FieldController {
    
    get defaultValue() {
        return this._defaultValue;
    }

    initTemplate() {
        if (this.dataType === 'MultiPicklist') {
            this.multiPicklist = true;
        }
        else {
            this.veevaCombobox = true;
        }
        return this;
    }

    get picklists() {
        if (!this._picklists) {
            return this.options().then(options => {
                if (VeevaUtils.isEmptyObject(options.controllerValues)) {
                    this._picklists = options.values;
                    const defVal = options.defaultValue;
                    if (defVal) {
                        this._defaultValue = defVal.value;
                    }
                }
                else {
                    this._picklists = this.getDependentOptions(options, this.controllingValue);
                }
                return this._picklists;
            });
        }
        return this._picklists;
    }
    set picklists(value) {
        this._picklists = value;
    }

    async options() {
        if (!this._metaOptions) {
            let picklists = await this.pageCtrl.uiApi.getPicklistValues(this.recordTypeId, this.objectApiName, this.meta.field);
            this._metaOptions = picklists;
        }
        return this._metaOptions;
    }

    get selected() {
        return this.rawValue;
    }

    get controllingValue() {
        if (this._controllingVal === undefined) {
            this._controllingVal = this.data.rawValue(this.field.controllerName);
        }
        return this._controllingVal;
    }
    set controllingValue(value) {
        this.updateControllingValue(value);
    }

    updateControllingValue(value) {
        this._controllingVal = value;
        if (this._metaOptions) {
            this._picklists = this.getDependentOptions(this._metaOptions, value);
            let selected = this.selected;
            // remove invalid selection based on new controlling value
            if (this.multiPicklist) {
                if (selected) {
                    let valid = selected.split(";").filter(x => this._picklists.find(opt => opt.value === x));
                    this.setFieldValue(valid.join(";"));
                }
            } else if (!selected || !this._picklists.find(x => x.value === selected)) {
                this.setFieldValue(''); // clear selected
            }
        }
    }

    get controllerLabel() {
        let controllerLabel = '';
        if (this.field.controllerName) {
            const controllerFldMeta = this.pageCtrl.objectInfo.fields[this.field.controllerName];
            controllerLabel = controllerFldMeta ? controllerFldMeta.label : '';
        }
        return controllerLabel;
    }

    getDependentOptions(options, value) {
        let index = options.controllerValues[value];
        if (index === undefined) {
            return [];
        }
        return options.values.filter(x => x.validFor.includes(index));
    }

    track(element, funcName) {
        if (this.field.controllerName) {
            this.pageCtrl.track(this.field.controllerName, element, funcName);
        }
    }
}