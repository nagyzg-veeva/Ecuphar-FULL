import { LightningElement, api, track } from 'lwc';
import VeevaUtils from 'c/veevaUtils';

export default class VeevaRecordPreview extends LightningElement {
    @track selected = {};

    get name() {
        if (this.selected.name) {
            return this.selected.name;
        }
        return this.ctrl.selected.name;
    }
    @api
    get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        this._ctrl = value;
        this.getMissingName(value);
    }
    get url() {
        let recordUrl = '';
        if (this._isValidRecord()) {
            recordUrl = `/${this.ctrl.selected.id}`;
        }
        return recordUrl;
    }

    get extra() {
        let extraText = '';
        if (this._isValidRecord()) {
            extraText = this.ctrl.extra;
        }
        return extraText;
    }

    get isRecordType() {
        return this.ctrl.relationshipName === 'RecordType';
    }

    isNotValidName() {
        if (this.ctrl.selected.id) {
            return (!this.ctrl.selected.name) || (this.ctrl.selected.id === this.ctrl.selected.name);
        }
        return false;
    }

    _isValidRecord() {
        return this.name && VeevaUtils.validSfdcId(this.ctrl.selected.id);
    }
    async getMissingName(currCtrl) {
        if (this.isNotValidName()) {
            const selObj = currCtrl.selected;
            await populateMissingName(selObj, currCtrl.nameField, currCtrl.pageCtrl.uiApi)
            this.selected = selObj;
        }
        else {
            this.selected = currCtrl.selected;
        }
        async function populateMissingName(selectedObj, nameField, uiApi) {
            if (selectedObj.apiName) {
                const data = await VeevaUtils.to(uiApi.getRecord(selectedObj.id, [`${selectedObj.apiName}.${nameField}`]));
                if (data[1] && data[1].fields) {
                    selectedObj.name = data[1].fields.Name.value;
                }
            }
        }
    }
}