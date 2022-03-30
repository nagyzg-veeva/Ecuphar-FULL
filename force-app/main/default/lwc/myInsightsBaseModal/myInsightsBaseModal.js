import { api, LightningElement, track, wire } from "lwc";
import { MessageContext, publish, subscribe, unsubscribe } from "lightning/messageService"
import myInsightsModalChannel from "@salesforce/messageChannel/MyInsights_Modal__c";

export default class MyInsightsBaseModal extends LightningElement {
    @api htmlReportId;
    @api htmlReportUuid;

    @track modal = {
        show: false
    }

    @wire(MessageContext)
    messageContext;

    subscription;

    connectedCallback() {
        this.subscribeToModalChannel();
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
        }
    }

    subscribeToModalChannel() {
        this.subscription = subscribe(
            this.messageContext,
            myInsightsModalChannel,
            message => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        const { htmlReportId, htmlReportUUID, type, data } = message;
        if (this.hasExpectedMessage(type, data, htmlReportId, htmlReportUUID)) {
            this.updateModal(data);
        }
    }

    // To be overridden by a child class
    updateModal() {
        this.modal.show = true;
    }

    // To be overridden by a child class
    clearModal() {
        this.modal.show = false;
    }

    hasExpectedMessage(type, data, htmlReportId, htmlReportUUID) {
        return type && data && htmlReportId === this.htmlReportId && htmlReportUUID === this.htmlReportUuid;
    }

    handleModalClose() {
        this.clearModal();
        publish(this.messageContext, myInsightsModalChannel, {
            htmlReportId: this.htmlReportId,
            htmlReportUUID: this.htmlReportUuid,
            type: "modalClosed",
            data: {
                result: "closed"
            }
        });
    }
}