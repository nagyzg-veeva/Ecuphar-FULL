export default class VeevaBaseController {
    constructor(meta, pageCtrl, record) {
        this.meta = meta || {};
        this.pageCtrl = pageCtrl || { record: {}, objectInfo: {} };
        // set initial values 
        this.editable = meta.editable;
        this.required = meta.required;
        this.data = record;
    }

    initTemplate() {
        return this;
    }

    setData(value) {
        this.data = value;
    }

    get id() {
        return this.data.id;
    }

    get recordTypeId() {
        return this.data.recordTypeId;
    }

    get objectApiName() {
        return this.data.apiName;
    }

    get label() {
        return this.meta.label;
    }

    get helpText() {
        return this.meta.helpText;
    }

    get readonly() {
        if (this.editable !== undefined) {
            return !this.editable;
        }
        return this.meta ? !this.meta.editable : true;
    }

    get disabled() {
        return this.meta && this.meta.disabled ? true : false;
    }

    get actionView() {
        return this.pageCtrl.action === 'View';
    }

    get fieldApiName() {
        return '';
    }

    get objectLabel() {
        return this.pageCtrl.objectInfo.label;
    }

    save(value) {
        return this.pageCtrl.save(value);
    }

    // validation
    validate() {
        return true;
    }

    getError() {
        return this.error || '';
    }
}