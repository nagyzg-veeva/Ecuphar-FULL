import MedInqConstant from 'c/medInqConstant';
import VeevaConstant from 'c/veevaConstant';

const MethodLayout = {
    describeMethod: async function (signal, isPrimary) {
        switch (signal || '') {
            case 'eom':
                return this.getMailLayout(isPrimary);
            case 'eop':
                return this.getPhoneLayout(isPrimary);
            case 'eof':
                return this.getFaxLayout(isPrimary);
            case 'eoe':
                return this.getEmailLayout(isPrimary);
            default:
                return null;
        }
    },

    getNewFields: function (names, required, isPrimary) {
        const isNew = this.pageCtrl.action === 'New';
        let readOnly = isPrimary && this.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD);
        let fields = names.map(x => this.pageCtrl.objectInfo.getFieldInfo(x));
        let meta = fields.filter(x => x && (isNew ? x.createable : x.updateable)).map(
            x => ({ field: x.apiName, label: x.label, editable: !readOnly, required: required.includes(x.apiName) }));
        return meta.map(item => this.pageCtrl.getItemController(item, this.data));
    },

    getNewCheckbox: function (label, isPrimary) {
        let readOnly = isPrimary && this.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD);
        return this.pageCtrl.getItemController({ label: label, editable: !readOnly }, this.data);
    },

    getMailLayout: async function (isPrimary) {
        let layout = { signal: 'eom', dataType: 'String' };
        const msg = await this._getMedinqMsg(MedInqConstant.MSG_MED_INQ_ADDRESS);
        layout.label = msg;
        layout.newOption = this.meta.options.includes('ana') && !this.actionView;
        if (layout.newOption) {
            const createNew = await this._getMedinqMsg(MedInqConstant.MSG_SHIP_TO_NEW_ADD);
            layout.checkbox = this.getNewCheckbox(createNew, isPrimary, this.data);
            layout.fields = this.getNewFields(MedInqConstant.NEW_FIELDS.ana.filter(x => this.meta.mailFields.includes(x)), this.meta.requiredMailFields, isPrimary, this.data);
        }
        return layout;
    },

    getPhoneLayout: async function (isPrimary) {
        let layout = { signal: 'eop', dataType: 'Phone' };
        const msg = await this._getMedinqMsg(MedInqConstant.MSG_MED_INQ_PHONE);
        layout.label = msg;
        layout.newOption = this.meta.options.includes('anp') && !this.actionView;
        if (layout.newOption) {
            const createNew = await this._getMedinqMsg(MedInqConstant.MSG_NEW_PHONE_NUMBER);
            layout.checkbox = this.getNewCheckbox(createNew, isPrimary, this.data);
            layout.fields = this.getNewFields(MedInqConstant.NEW_FIELDS.anp, MedInqConstant.NEW_FIELDS.anp, isPrimary, this.data);
        }
        return layout;
    },

    getFaxLayout: async function (isPrimary) {
        let layout = { signal: 'eof', dataType: 'Phone' };
        const msg = await this._getMedinqMsg(MedInqConstant.MSG_MED_INQ_FAX);
        layout.label = msg;
        layout.newOption = this.meta.options.includes('anf') && !this.actionView;
        if (layout.newOption) {
            const createNew = await this._getMedinqMsg(MedInqConstant.MSG_NEW_FAX_NUMBER);
            layout.checkbox = this.getNewCheckbox(createNew, isPrimary, this.data);
            layout.fields = this.getNewFields(MedInqConstant.NEW_FIELDS.anf, MedInqConstant.NEW_FIELDS.anf, isPrimary, this.data);
        }
        return layout;
    },

    getEmailLayout: async function (isPrimary) {
        let layout = { signal: 'eoe', dataType: 'Email' };
        const msg = await this._getMedinqMsg(MedInqConstant.MSG_MED_INQ_EMAIL);
        layout.label = msg;
        layout.newOption = this.meta.options.includes('ane') && !this.actionView;
        if (layout.newOption) {
            const createNew = await this._getMedinqMsg(MedInqConstant.MSG_SEND_TO_NEW_EMAIL);
            layout.checkbox = this.getNewCheckbox(createNew, isPrimary, this.data);
            layout.fields = this.getNewFields(MedInqConstant.NEW_FIELDS.ane, MedInqConstant.NEW_FIELDS.ane, isPrimary, this.data);
        }
        return layout;
    },

    _getMedinqMsg: function(msgName) {
        return this.pageCtrl.getMessageWithDefault(
            msgName,
            MedInqConstant.CAT_MEDICAL_INQUIRY,
            ""
        );
    }
};

export { MethodLayout };