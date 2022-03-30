import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import MedInqConstant from "c/medInqConstant";
import VeevaConstant from "c/veevaConstant";
export default class MpiSection extends NavigationMixin(LightningElement) {
    @api ctrl;
    @track records = [];
    @track labelAddSection;
    @track labelCopy;
    @track labelDel;

    @api get recordUpdateFlag() {
        return this._recordUpdateFlag;
    }

    set recordUpdateFlag(value) {
        this.ctrl.getRecords().then((records) => {
            this.records = records;
            this._recordUpdateFlag = value;
        });
    }

    async connectedCallback() {
        // Get records first
        this.records = await this.ctrl.getRecords();

        if (!this.ctrl.actionView) {
            this.ctrl.pageCtrl.getMessageWithDefault(
                "ADD_SECTION_MPI",
                "MEDICAL_INQUIRY",
                "Add Section"
            ).then(data => { this.labelAddSection = data; });
            this.ctrl.pageCtrl.getMessageWithDefault(
                "COPY",
                "CallReport",
                "Copy"
            ).then(data => { this.labelCopy = data; });
            this.ctrl.pageCtrl.getMessageWithDefault(
                "Del",
                "Common",
                "Del"
            ).then(data => { this.labelDel = data; });
        }
    }

    addInquiry() {
        this.ctrl.addInquiry().then((inquiry) => {
            this.records = [...this.records, inquiry];
        });
    }

    get displayAddSectionCopy() {
        return !this.ctrl.actionView
                && !this.ctrl.data.isLocked
                && !this.ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD)
                && this.ctrl.pageCtrl.objectInfo.getFieldInfo(MedInqConstant.GROUP_IDENTIFIER)
                && this.ctrl.pageCtrl.objectInfo.createable;
    }

    get displayDeleteLink() {
        return !this.ctrl.actionView
                && !this.ctrl.data.isLocked
                && !this.ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD)
                && this.ctrl.pageCtrl.objectInfo.getFieldInfo(MedInqConstant.GROUP_IDENTIFIER)
                && this.ctrl.pageCtrl.objectInfo.deletable;
    }

    copyInquiry(event) {
        const inquiry = this.ctrl.copyInquiry(event.target.value);
        this.records = [...this.records, inquiry];
    }

    @api deleteInquiry(event) {
        this.ctrl.deleteInquiry(event.target.value);
        this.records = this.records.filter(x => x.id !== event.target.value);
    }

    @api checkValidity() {
        let errors = [...this.template.querySelectorAll("c-veeva-row")].filter(item => item.checkValidity && item.checkValidity() === false);
        if (!errors.length) {
            this.ctrl.saveCheckpoint();
        }
        return !errors.length;
    }
}