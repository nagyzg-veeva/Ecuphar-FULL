import { track } from "lwc";
import MyInsightsBaseModal from "c/myInsightsBaseModal";

export default class MyInsightsLoadingModal extends MyInsightsBaseModal {

    @track modal = {
        show: false
    };

    updateModal(data) {
        if (data.loading) {
            this.modal.show = true;
        } else if (data.loading === false) {
            this.modal.show = false;
        }
    }

    hasExpectedMessage(type, data, htmlReportId, htmlReportUUID) {
        return type === "loading" && data && htmlReportId === this.htmlReportId && htmlReportUUID === this.htmlReportUuid;
    }
}