import VeevaBaseController from "c/veevaBaseController";
import VeevaConstant from "c/veevaConstant";

export default class FieldController extends VeevaBaseController {
    constructor(meta, pageCtrl, field, record) {
        super(meta, pageCtrl, record);
        this.field = field;
    }

    initTemplate() {
        if (this.editable) {
            this.inputType = VeevaConstant.DATATYPE_TO_INPUTTYPE[this.dataType];
            if (this.dataType === 'TextArea') {
                this.inputType = 'textarea';
                this.veevaTextArea = true;
                return this;
            }
            if (this.inputType) {
                this.veevaLightningInput = true;
                return this;
            }
        }
        // For fields of Url datatype use veevaFieldUrl component
        if (this.dataType === 'Url') {
            this.veevaUrl = true;
        }else if (this.field.calculated){
            this.veevaFormula = true;
        } else {
            // Fields of other datatypes use veevaFieldText component
            this.veevaText = true;
        }
        return this;
    }

    get digits() {
        return this.field.scale || 0;
    }

    get maxlength() {
        let maxLength;
        switch (this.inputType || '') {
            case 'email':
            case 'tel':
            case 'text':
            case 'textarea':
            case 'url':
                maxLength = this.field.length;
                break;
            default:
        }
        return maxLength;
    }

    get displayValue() {
        return this.data.displayValue(this.field);
    }

    get value() {
        return this.data.value(this.field);
    }

    get rawValue() {
        return this.data.rawValue(this.field);
    }

    get dataType() {
        return this.field.dataType;
    }

    get fieldApiName() {
        return this.field.apiName;
    }

    setFieldValue(value, reference, source) {
        this.pageCtrl.setFieldValue(this.field, value, reference, this.data, source);
    }

    get helpText() {
        return this.field.inlineHelpText;
    }

    getError() {
        let errors = this.pageCtrl.fieldErrors;
        if (errors && errors[this.fieldApiName]) {
            return errors[this.fieldApiName];
        }
        return super.getError();
    }
}