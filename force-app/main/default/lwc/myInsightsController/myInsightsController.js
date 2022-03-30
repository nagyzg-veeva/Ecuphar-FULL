import VeevaPageController from "c/veevaPageController";
import MyInsightsService from "c/myInsightsService";
import { createMessageContext, publish, subscribe, unsubscribe } from "lightning/messageService";
import myInsightsModalChannel from "@salesforce/messageChannel/MyInsights_Modal__c";
import myInsightsNavigationChannel from "@salesforce/messageChannel/MyInsights_Navigation__c";

export default class MyInsightsController extends VeevaPageController {
    _htmlReportId;
    _htmlReportUUID;
    _modal = {};
    constructor(dataSvc, userInterface, messageSvc, sessionSvc, myInsightsService) {
        super(dataSvc, userInterface, messageSvc);
        if (myInsightsService) {
            this.myInsightsService = myInsightsService;
        } else {
            this.myInsightsService = new MyInsightsService(dataSvc, sessionSvc);
        }
        this.messageContext = createMessageContext();
    }

    get htmlReportId() {
        return this._htmlReportId;
    }

    set htmlReportId(value) {
        this._htmlReportId = value;
    }

    get htmlReportUUID() {
        return this._htmlReportUUID;
    }

    set htmlReportUUID(value) {
        this._htmlReportUUID = value;
    }

    showLoadingModal() {
        this.publishLoadingModalMessage(true);
    }

    closeLoadingModal() {
        this.publishLoadingModalMessage(false);
    }

    publishLoadingModalMessage(loading) {
        publish(this.messageContext, myInsightsModalChannel, {
            htmlReportId: this.htmlReportId,
            htmlReportUUID: this.htmlReportUUID,
            type: "loading",
            data: {
                loading: loading
            }
        });
    }

    showConfirmationModal(modalConfig, closeCallback) {
        const title = this._getModalTitle(modalConfig);
        const messages = this._getModalMessages(modalConfig);
        if (modalConfig && title || messages) {
            const data = {
                title: title,
                messages: messages
            }
            this._showModal("confirm", data, message => {
                if (closeCallback) {
                    closeCallback(message.data.result !== "closed");
                }
            });
        }
    }

    showAlertModal(modalConfig, closeCallback) {
        const title = this._getModalTitle(modalConfig);
        const messages = this._getModalMessages(modalConfig);
        if (modalConfig && title || messages) {
            const data = {
                title: title,
                messages: messages
            }
            this._showModal("alert", data, () => {
                // The user cannot necessarily accept or decline an alert
                if (closeCallback) {
                    closeCallback();
                }
            });
        }
    }

    matchesHTMLReportIdAndUUID(message) {
        return message && this.htmlReportId === message.htmlReportId && this.htmlReportUUID === message.htmlReportUUID;
    }

    showDismissSuggestionSurveyModal(title, survey, labels, closeCallback) {
        if (title && survey && labels) {
            const data = {
                survey: survey,
                labels: labels,
                title: title
            };
            this._showModal("suggestionSurveyModal", data, message => {
                if (closeCallback) {
                    closeCallback({
                        submit: message.data.result === "submit",
                        populatedSurveyQuestions: message.data.populatedSurveyQuestions
                    });
                }
            });
        }
    }

    navigateToUrl(url) {
        publish(this.messageContext, myInsightsNavigationChannel, {
            urlInfo: {
                url: url
            }
        });
    }

    _showModal(type, data, modalCloseCallback) {
        publish(this.messageContext, myInsightsModalChannel, {
            htmlReportId: this.htmlReportId,
            htmlReportUUID: this.htmlReportUUID,
            type: type,
            data: data
        });
        const confirmationModalResponseSubscription = subscribe(
            this.messageContext,
            myInsightsModalChannel,
            message => {
                if (this.matchesHTMLReportIdAndUUID(message) && message.type === "modalClosed" && message.data) {
                    if (modalCloseCallback) {
                        modalCloseCallback(message);
                    }
                    unsubscribe(confirmationModalResponseSubscription);
                }
            }
        );
    }

    _getModalTitle(modalConfig) {
        if (!modalConfig) {
            return undefined;
        }
        return modalConfig.title;
    }

    _getModalMessages(modalConfig) {
        if (!modalConfig) {
            return undefined;
        }
        return modalConfig.messages;
    }

    async getBaseCdnDomainUrl() {
        return this.myInsightsService.retrieveCdnDomain();
    }

    async getOrgId() {
        return this.myInsightsService.retrieveOrgId();
    }

    async getCdnAuthToken(cdnContentUrl) {
        return this.myInsightsService.retrieveCdnAuthToken(cdnContentUrl);
    }
}