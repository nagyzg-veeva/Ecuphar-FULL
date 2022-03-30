import { LightningElement, api, track } from "lwc";
import VeevaButtonTemplate from './veevaButton.html'

export default class VeevaButton extends LightningElement {
    @api button;
    @api disableButton;
    @track buttonCtrl;

    @api
    get pageCtrl() {
        return this._pageCtrl;
    }

    set pageCtrl(value) {
        this._pageCtrl = value;
        if (this._pageCtrl && this._pageCtrl.toButtonCtrl) {
            this.buttonCtrl = this._pageCtrl.toButtonCtrl(this.button);
        }
    }

    render() {
        return (this.buttonCtrl && this.buttonCtrl.template) || VeevaButtonTemplate;
    }

    get name() {
        return this.button && this.button.name;
    }

    get btnEdit() {
        return this.name === 'Edit';
    }
    get btnDelete() {
        return this.name === 'Delete';
    }

    get btnUnlock() {
        return this.name === 'Unlock';
    }

    get btnCancel() {
        return this.name === 'cancel';
    }

    get isModalSave() {
        return ['save', 'saveAndNew', 'submit'].indexOf(this.name) >= 0;
    }

    get recordId() {
        return this.pageCtrl && this.pageCtrl.id;
    }
    
    get pageMode() {
        return this.pageCtrl && this.pageCtrl.action;
    }

    get showVeevaCustomButton() {
        return this.button && !this.button.standard && !this.button.notVeevaCustomButton;
    }
}