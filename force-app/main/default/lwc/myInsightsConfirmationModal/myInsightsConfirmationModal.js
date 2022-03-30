import { track } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";
import { publish } from "lightning/messageService"
import myInsightsModalChannel from "@salesforce/messageChannel/MyInsights_Modal__c";
import MyInsightsBaseModal from "c/myInsightsBaseModal";

export default class MyInsightsConfirmationModal extends MyInsightsBaseModal {

    @track modal = {
        show: false,
        title: null,
        messages: null,
    };

    @track defaultVeevaMessages = {
        yes: "Yes",
        no: "No"
    };

    get hideHeader() {
        return !this.modal.title;
    }

    connectedCallback() {
        super.connectedCallback();
        const veevaMessageService = getPageController("messageSvc");
        this.loadDefaultVeevaMessages(veevaMessageService);
    }

    async loadDefaultVeevaMessages(veevaMessageService) {
        this.defaultVeevaMessages.yes = await veevaMessageService.getMessageWithDefault("YES", "Common", this.defaultVeevaMessages.yes);
        this.defaultVeevaMessages.no = await veevaMessageService.getMessageWithDefault("NO", "Common", this.defaultVeevaMessages.no);
    }

    updateModal(data) {
        if (data) {
            this.modal.show = true;
            this.modal.title = data.title;
            this.modal.messages = data.messages;
        }
    }

    clearModal() {
        this.modal.show = false;
        this.modal.title = null;
        this.modal.messages = null;
    }

    hasExpectedMessage(type, data, htmlReportId, htmlReportUUID) {
        return type === "confirm" && data && htmlReportId === this.htmlReportId && htmlReportUUID === this.htmlReportUuid;
    }

    handleModalAccept() {
        this.clearModal();
        publish(this.messageContext, myInsightsModalChannel, {
            htmlReportId: this.htmlReportId,
            htmlReportUUID: this.htmlReportUuid,
            type: "modalClosed",
            data: {
                result: "accepted"
            }
        });
    }
}