import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

// VeevaOverrideEdit hosts VeevaEditPage modal page
export default class VeevaOverrideEdit extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api pageReference;
    @track show = true;

    handleClose() {
        this.show = false;
    }
}