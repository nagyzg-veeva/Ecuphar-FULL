/* eslint-disable @lwc/lwc/no-async-operation */
import { api, track, LightningElement } from 'lwc';

export default class VeevaMultiObjectLookup extends LightningElement {
    @api ctrl;

    @track objectListFocus = false; 

    connectedCallback() {
        if (!this.ctrl.selectedObject.value) {
            this.ctrl.selectedObject = this.defaultObject;
        }
    }

    //object list handlers
    handleObjectListFocus() {
        this.objectListFocus = true;
    }

    handleObjectListClose() {
        setTimeout(() => {
            this.objectListFocus = false;
        }, 200);
    }

    handleObjectListClick(event) {
        let selected = this.objectList.find(object => object.value === event.currentTarget.dataset.objectname);
        if (selected && this.ctrl.selectedObject.value !== selected.value) {
            this.ctrl.selectedObject = selected;
            this.template.querySelector("c-veeva-lookup.veeva-lookup").handleClearLookup();
        }
        this.objectListFocus = false;
    }

    bubbleLookupSelection(event) {
        this.dispatchEvent(new CustomEvent("lookupselection", event));
    }

    bubbleSearchMode(event) {
        this.dispatchEvent(new CustomEvent("searchmode", event));
    }

    bubbleClearLookup() {
        this.dispatchEvent(new CustomEvent("clearlookup"));
    }

    get objectList() {
        return (this.ctrl && this.ctrl.meta && this.ctrl.meta.objectList) || [];
    }

    get showLabel() {
        return this.ctrl && this.ctrl.meta && this.ctrl.meta.label;
    }

    get isMultilookup() {
        return this.objectList && this.objectList.length > 1;
    }

    get defaultObject() {
        let defaultObj;
        if (this.objectList.length > 0) {
            defaultObj = this.objectList.find(object => object.defaultValue);
            if (!defaultObj) { //use first element as fallback
                defaultObj = this.objectList[0];
            }
        }
        return defaultObj;
    }

    // styles
    get containerClass() {
        let css = 'slds-combobox_container';
        if (this.isMultilookup) {
            css += ' slds-combobox-addon_end';
        }
        return css;
    }

    //multi object styles
    get objectListDropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        if (this.objectListFocus) {
            css += ' slds-is-open';
        }
        return css;
    }

    get comboBoxGroupClass() {
        if (this.isMultilookup) {
            return 'slds-combobox-group';
        }
        return '';
    }
}