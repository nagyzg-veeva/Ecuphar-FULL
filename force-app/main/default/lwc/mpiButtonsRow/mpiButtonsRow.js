import { LightningElement, api } from 'lwc';
import MedInqConstant from "c/medInqConstant";

export default class MpiButtonsRow extends LightningElement {
    _record;
    _pageCtrl;
    customButtonsIsSet;
    customButtons = [];
    
    @api 
    get record() {
        return this._record;
    }

    set record(value){
        this._record = value;
        this.setCustomButtons();
    }

    @api
    get pageCtrl() {
        return this._pageCtrl;
    }

    set pageCtrl(value) {
        this._pageCtrl = value;
        this.setCustomButtons();
    }

    async setCustomButtons() {
        if (this.record && this.pageCtrl && !this.customButtonsIsSet) {
            let buttons = await this.getMpiLinks();
            buttons = buttons.filter(x => MedInqConstant.CUSTOM_BUTTONS.includes(x.name));
            this.customButtons = [...buttons];
            this.customButtonsIsSet = true;
        }
    }

    async getMpiLinks() {
        let mpiLinks = [];
        if (this.pageCtrl.action === 'View' && this.record.isSubmitted && this.pageCtrl.page.layout.buttons) {
            const filtered = this.pageCtrl.page.layout.buttons.filter(x => MedInqConstant.CUSTOM_BUTTONS.includes(x.name));
            if (filtered.length) {
                const buttonCtrls = await Promise.all(filtered.map(x => this.pageCtrl.toButtonCtrl(x, this.record)));
                mpiLinks = buttonCtrls.filter(x => x);
            }
        }
        return mpiLinks;
    }
}