import { track } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";
import MyInsightsBaseModal from "c/myInsightsBaseModal"

export default class MyInsightsAlertModal extends MyInsightsBaseModal {

    @track modal = {
        show: false,
        title: null,
        messages: null,
    };

    @track defaultVeevaMessages = {
        ok: "Ok",
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
        this.defaultVeevaMessages.ok = await veevaMessageService.getMessageWithDefault("OK", "Common", this.defaultVeevaMessages.ok);
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
        return type === "alert" && data && htmlReportId === this.htmlReportId && htmlReportUUID === this.htmlReportUuid;
    }
}