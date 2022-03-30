import { LightningElement, api, track } from "lwc";

export default class VeevaDependentPicklistMsg extends LightningElement {
    // Picklist Controller
    @api  ctrl;

    @track dependsOnMsg;

    connectedCallback() {
        this.setDependsOnMsg();
    }

    setDependsOnMsg() {
        if (this.ctrl.controllerLabel) {
            this.ctrl.pageCtrl.getMessageWithDefault(
                "DEPENDENT_INFO",
                "Common",
                "Depends on {0}"
            ).then(msg => { 
                this.dependsOnMsg = this.capitalize(msg.replace('{0}', this.ctrl.controllerLabel)); 
            });
        }
    }

    capitalize (string) {
        if (string && typeof string !== 'string') return ''
        return string.charAt(0).toUpperCase() + string.slice(1);
    }
}