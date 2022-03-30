import { LightningElement, api, track } from 'lwc';
import VeevaConstant from 'c/veevaConstant';

const RICH_TEXT_FORMATS = ['font', 'size', 'bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align', 'link', 'image', 'clean', 'table', 'header', 'color', 'background', 'code', 'code-block', 'script', 'blockquote', 'direction'];

export default class VeevaFieldTextArea extends LightningElement {
    @api get ctrl() {
        return this._ctrl;
    }
    set ctrl(value) {
        this._ctrl = value;
        this.retrieveDisplayValue();
    }

    @track value;
    invalidRichMessage;
    richValid = true;

    async retrieveDisplayValue(){
        this.value = await this.ctrl.displayValue;
        if (this.isRichTextArea && this.value === null) {
            // necessary to set value to empty string instead of null after undo
            // otherwise salesforce lwc doesn't update UI
            this.value = '';
        }
    }

    handleChange(event) {
        event.preventDefault();
        window.clearTimeout(this.delayTimeout);
        const value = event.target.value;
        if (value === this.value) {
            // necessary after undo is pressed in order to not retrigger handleFieldChange in veevaItem
            // unlike other salesforce lwc as change event is fired even when value is changed via code, not only UI
            event.stopPropagation();
        } else {
            this.value = value;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.delayTimeout = setTimeout(() => {
                this.ctrl.setFieldValue(value);
            }, VeevaConstant.DEBOUNCE_DELAY);
        }
    }
    
    @api checkValidity() {
        let valid = true;
        
        if (this.isRichTextArea) {
            valid = this._reportRichTextValidity();
            this.richValid = valid;
        } else {
            valid = this._reportTextAreaValidity();
        }

        return valid;
    }

    _reportTextAreaValidity() {
        const textAreaElement = this.template.querySelector("lightning-textarea");
        if (textAreaElement.checkValidity && textAreaElement.checkValidity()) {
            this.ctrl.validate();
            textAreaElement.setCustomValidity(this.ctrl.getError());
        }
        return !textAreaElement.reportValidity || textAreaElement.reportValidity();
    }

    _reportRichTextValidity() {
        let valid = true;

        const requiredAndEmpty = this.ctrl.required && !this.value;
        const overMaxLength = this.value && (this.value.length > this.ctrl.maxlength);
        if (requiredAndEmpty || overMaxLength) {
            valid = false;
            this._setInvalidRichMessage(requiredAndEmpty);
        }

        return valid;
    }

    async _setInvalidRichMessage(requiredAndEmpty) {
        let message;
        if (requiredAndEmpty) {
            message = await this.ctrl.pageCtrl.getMessageWithDefault(
                'REQUIRED_VALUE', 'Account', 'Complete this field.'
            );
        } else {
            message = await this.ctrl.pageCtrl.getMessageWithDefault(
                'TOO_MANY_CHARS', 'Common', `data value too large: ${this.value} (max length=${this.ctrl.maxlength})`
            );
            if (message.includes('{0}')) {
                message = `${message.replace('{0}', this.ctrl.maxlength)}: ${this.value}`;
            } 
        }
        this.invalidRichMessage = message;
    }

    get isRichTextArea() {
        return this.ctrl.field && this.ctrl.field.extraTypeInfo === 'RichTextArea';
    }
    
    get formats() {
        return RICH_TEXT_FORMATS;
    }
}