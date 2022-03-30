import { LightningElement, api, wire } from "lwc";
import veevaButtonAction from '@salesforce/messageChannel/Veeva_Button_Action__c';
import { MessageContext, publish } from 'lightning/messageService';

export default class VeevaButtonSave extends LightningElement {
    @api meta;
    @api recordId;
    @api pageMode;
    @api disableButton;

    @wire(MessageContext)
    messageContext;

    get name() {
        return this.meta.name;
    }

    get isSubmit() {
        return this.name === 'submit';
    }

    get isSaveAndNew() {
        return this.name === 'saveAndNew';
    }

    get variant() {
        return this.isSaveAndNew ? 'neutral' : this.meta.variant;
    }

    handleSave(event) {
        event.preventDefault();
        publish(this.messageContext, veevaButtonAction, {
            action: 'saverecord',
            recordId: this.recordId,
            pageMode: this.pageMode,
            parameters: {
                submit: this.isSubmit,
                saveAndNew: this.isSaveAndNew
            }
        });
    }
}