import BaseSmartLinkingHandler from "./baseSmartLinkingHandler";
import SuggestionService from "c/suggestionService";

export default class SuggestionHandler extends BaseSmartLinkingHandler {

    veevaUserInterfaceAPI;
    veevaDataService;
    myInsightsPageController;
    constructor(veevaUserInterfaceAPI, veevaDataService, myInsightsPageController, suggestionService) {
        super();
        this.veevaUserInterfaceAPI = veevaUserInterfaceAPI;
        this.veevaDataService = veevaDataService;
        this.myInsightsPageController = myInsightsPageController;
        if (suggestionService) {
            this.suggestionService = suggestionService;
        } else {
            this.suggestionService = new SuggestionService(this.veevaDataService);
        }
        this.loadSuggestionMetadata();
    }

    async handle(config) {
        const action = config.action || "execute";
        const options = config.options;
        if (!this.hasValidOptions(options)) {
            this.throwCommandError("Did not receive Id for Suggestion_vod__c");
        }

        this.myInsightsPageController.showLoadingModal();
        // Maybe an array of Ids
        const suggestionId = options.record.Id || options.record.id;
        const recordTypeName = await this.getSuggestionRecordTypeName(suggestionId);
        const suggestionData = await this.getSuggestionData(suggestionId, recordTypeName);
        const suggestion = this.getSuggestionById(suggestionId, suggestionData);
        const suggestionGroup = this.getSuggestionGroupById(suggestionId, suggestionData);
        if (!suggestionGroup) {
            this.throwCommandError(`This Suggestion (${suggestionId}) was not included in response from CRM. It may not exist or may have already been actioned.`);
        }
        const accountId = suggestionGroup.AccountId;
        let response;
        switch (action) {
            case "dismiss":
                response = await this.handleSuggestionDismiss(suggestion, accountId);
                break;
            case "complete":
                response = await this.handleSuggestionComplete(suggestion, accountId);
                break;
            case "execute":
                response = await this.handleSuggestionExecute(suggestion, suggestionData, accountId, recordTypeName);
                break;
            default:
                // It appears that the pre-LEX MyInsights behavior is to do nothing if we receive an unexpected action
                return null;
        }
        this.myInsightsPageController.closeLoadingModal();
        return response;
    }

    async handleSuggestionDismiss(suggestion, accountId) {
        const suggestionId = suggestion.Id;
        const dismissTitle = await this.getMessage("dismissTitle")
        const dismissMessage = await this.getMessage("confirmDismiss");
        const modalConfig = {
            title: dismissTitle,
            messages: [dismissMessage]
        };
        return new Promise(resolve => {
            if (this.suggestionHasSurvey(suggestion)) {
                this.showDismissSuggestionSurveyModal(suggestion.SuggestionSurvey, resolve, populatedSurveyQuestions => {
                    this.dismissSuggestionSurvey(resolve, suggestion, populatedSurveyQuestions);
                });
            } else {
                this.showConfirmationModal(modalConfig, resolve, () => {
                    this.dismissSuggestion(resolve, suggestionId, accountId);
                });
            }
        })
    }

    async handleSuggestionComplete(suggestion, accountId) {
        const suggestionId = suggestion.Id;
        const markCompleteTitle = await this.getMessage("markComplete")
        const completeMessage = await this.getMessage("confirmMarkComplete");
        const modalConfig = {
            title: markCompleteTitle,
            messages: [completeMessage]
        };
        return new Promise(resolve => {
            this.showConfirmationModal(modalConfig, resolve, async () => {
                await this.completeSuggestion(resolve, suggestionId, accountId);
            });
        });
    }

    async handleSuggestionExecute(suggestion, suggestionData, accountId, recordTypeName) {
        const suggestionId = suggestion.Id;
        const actionGroup = this.getActionGroupById(suggestionId, suggestionData);
        switch (actionGroup.Action) {
            case "Call_vod":
                return this.promptCreateCall(suggestion, accountId);
            case "Email_vod":
                return this.sendEmail([suggestion], accountId);
            case "Call_Objective_vod":
                return this.promptCreateCallObjectives([suggestion], accountId);
            case 'NO_PERMISSION_ERROR':
                return this.displayNoPermissionDialog(recordTypeName);
            default:
                return null;
        }
    }

    async promptCreateCall(suggestion, accountId) {
        const suggestionId = suggestion.Id;
        const plannedCallDate = suggestion.PlannedCallDate;
        const createCallMessage = await this.getMessage("suggestionPrompt");
        const modalConfig = {
            messages: [createCallMessage]
        };
        return new Promise(resolve => {
            this.showConfirmationModal(modalConfig, resolve, async () => {
                // We still need to continue loading to show that we are processing the request.
                this.myInsightsPageController.showLoadingModal();
                await this.createCall(resolve, suggestionId, accountId, plannedCallDate);
            });
        });
    }

    async promptCreateCallObjectives(suggestions) {
        const createCallObjectivesMessage = await this.getMessage("confirmCallObjectives");
        const modalConfig = {
            messages: [createCallObjectivesMessage]
        };
        return new Promise(resolve => {
            this.showConfirmationModal(modalConfig, resolve, async () => {
                // We still need to continue loading to show that we are processing the request.
                this.myInsightsPageController.showLoadingModal();
                const callObjectives = this.createCallObjectiveRecords(suggestions);
                await this.createCallObjectives(resolve, callObjectives);
            });
        });
    }

    async displayNoPermissionDialog(recordTypeName) {
        const noPermissionMessage = await this.getMessage("noPermissionError");
        const formattedNoPermissionMessage = noPermissionMessage.replace("{0}", recordTypeName);
        const modalConfig = {
            messages: [formattedNoPermissionMessage]
        };
        return new Promise(resolve => {
            this.showConfirmationModal(modalConfig, resolve, () => {
                resolve({
                    success: false,
                    message: formattedNoPermissionMessage
                });
            });
        });
    }

    sendEmail(suggestions, accountId) {
        const firstSuggestion = suggestions[0];
        let products = "";
        let suggestionsParameter = "";
        for (let i = 0; i < suggestions.length; i++) {
            const curSugg = suggestions[i];
            if (firstSuggestion.EmailTemplate && (!curSugg.Id || !curSugg.EmailTemplateID || !curSugg.EmailTemplateVaultId)) {
                continue;
            }
            suggestionsParameter += (i !== 0 ? ',' : '') + curSugg.Id + '|' + curSugg.EmailTemplateID + '|' + curSugg.EmailTemplateVaultId;
            for (let j = 0; j < curSugg.Tags.length; j++) {

                const tag = curSugg.Tags[j];
                if (tag.ProductId) {
                    products += (j !== 0 ? ',' : '') + tag.ProductId;
                    products += ',' + (tag.DetailGroupId ? tag.DetailGroupId : '') + '|' + tag.ProductId;
                }
                if (tag.EmailFragment) {
                    suggestionsParameter += '|' + tag.EmailFragment;
                }
            }
        }
        const toUrl = this.sendEmailRedirectUrl(firstSuggestion, accountId, suggestionsParameter, products);
        this.myInsightsPageController.navigateToUrl(toUrl);
        return null;
    }

    sendEmailRedirectUrl(firstSuggestion, accountId, suggestionsParameter, products) {
        let toUrl;
        if (firstSuggestion.EmailTemplate) {
            toUrl = `/apex/Send_Approved_Email_vod?location=Suggestion_vod&suggestedEmailTemplates=true&id=${accountId}&suggestions=${suggestionsParameter}` +
                (products ? '&productids=' + products : '');
        } else {
            const suggestionId = firstSuggestion.Id;
            toUrl = `/apex/Send_Approved_Email_vod?location=Suggestion_vod&id=${accountId}&suggestionId=${suggestionId}` +
                (products ? '&productids=' + products : '');
        }
        toUrl += '&retURL=' + encodeURIComponent(window.location.href);
        return toUrl;
    }

    showConfirmationModal(modalConfig, resolve, confirmCallback) {
        this.myInsightsPageController.closeLoadingModal();
        this.myInsightsPageController.showConfirmationModal(modalConfig, confirm => {
            if (confirm && confirmCallback) {
                confirmCallback();
            } else if (resolve && !confirm) {
                resolve({
                    success: false,
                    message: "cancel"
                });
            }
        });
    }

    showAlertModal(modalConfig, resolve, confirmCallback) {
        this.myInsightsPageController.closeLoadingModal();
        this.myInsightsPageController.showAlertModal(modalConfig, confirm => {
            if (confirm && confirmCallback) {
                confirmCallback();
            } else if (resolve && !confirm) {
                resolve({
                    success: false,
                    message: "cancel"
                });
            }
        });
    }

    async showDismissSuggestionSurveyModal(suggestionSurvey, resolve, confirmCallback) {
        this.myInsightsPageController.closeLoadingModal();
        const title = await this.getMessage("dismiss");
        const labels = {
            submit: await this.getMessage("submit"),
            cancel: await this.getMessage("cancel"),
            none: await this.getMessage("NONE")
        };
        this.myInsightsPageController.showDismissSuggestionSurveyModal(title, suggestionSurvey, labels, response => {
            const { submit, populatedSurveyQuestions } = response;
            if (submit && populatedSurveyQuestions && confirmCallback) {
                confirmCallback(populatedSurveyQuestions);
            } else if (resolve && !populatedSurveyQuestions) {
                resolve({
                    success: false,
                    message: "cancel"
                });
            }
        });
    }

    async dismissSuggestion(resolve, suggestionId, accountId) {
        try {
            const response = await this.suggestionService.dismiss(accountId, suggestionId);
            resolve({
                success: true,
                ...response
            });
        } catch (e) {
            resolve({
                success: false,
                message: e.message
            });
        }
    }

    async dismissSuggestionSurvey(resolve, suggestion, populatedSurveyQuestions) {
        try {
            const response = await this.suggestionService.surveyDismiss(suggestion, populatedSurveyQuestions);
            resolve({
                success: true,
                ...response
            });
        } catch (e) {
            resolve({
                success: false,
                message: e.message
            });
        }
    }

    async completeSuggestion(resolve, suggestionId, accountId) {
        try {
            const response = await this.suggestionService.complete(accountId, suggestionId);
            resolve({
                success: true,
                ...response
            });
        } catch (e) {
            resolve({
                success: false,
                message: e.message
            });
        }
    }

    async createCall(resolve, suggestionId, accountId, plannedCallDate) {
        try {
            const response = await this.suggestionService.createCall(accountId, suggestionId, plannedCallDate);
            resolve({
                success: true,
                ...response
            });
            const plannedCall = response.data;
            const params = `&view=agendaWeek&date=${plannedCall.startDate}&highlight=${plannedCall.id}`
            const navigateToURL = `/apex/VOD_Render_vod?oType=agendaWeek&queryParams=${encodeURIComponent(params)}`;
            this.myInsightsPageController.navigateToUrl(navigateToURL);
        } catch (e) {
            resolve({
                success: false,
                message: e.message
            });
        }
    }

    async createCallObjectives(resolve, callObjectives) {
        try {
            const response = await this.suggestionService.createCallObjectives(callObjectives);
            const { success, failed } = response.data;
            await this.showCallObjectiveSuccessAndFailed(success, failed);
            resolve({
                success: true,
                ...response
            });
        } catch (e) {
            await this.showCallObjectiveSuccessAndFailed(0, callObjectives.length);
            resolve({
                success: false,
                message: e.message
            });
        }
    }

    async showCallObjectiveSuccessAndFailed(success, failed) {
        const messages = [];
        if (success) {
            const successMessage = await this.getMessage("callObjectivesSuccess");
            const formattedSuccessMessage = successMessage.replace("{0}", success);
            messages.push(formattedSuccessMessage);
        }
        if (failed) {
            const failedMessage = await this.getMessage("callObjectivesFailed");
            const formattedFailedMessage = failedMessage.replace("{0}", failed);
            messages.push(formattedFailedMessage);
        }
        if (messages.length > 0) {
            this.showAlertModal({ messages: messages });
        }
    }

    getSuggestionById(suggestionId, suggestionData) {
        const actionGroups = suggestionData.SuggestionGroups.flatMap(suggestionGroup => suggestionGroup.ActionGroups);
        const suggestions = actionGroups.flatMap(actionGroup => actionGroup.Suggestions);
        return suggestions.find(suggestion => suggestion.Id === suggestionId);
    }

    getSuggestionGroupById(suggestionId, suggestionData) {
        return suggestionData.SuggestionGroups.find(suggestionGroup =>
            suggestionGroup.ActionGroups.find(actionGroup =>
                actionGroup.Suggestions.find(suggestion => suggestion.Id === suggestionId)
            )
        );
    }

    getActionGroupById(suggestionId, suggestionData) {
        const actionGroups = suggestionData.SuggestionGroups.flatMap(suggestionGroup => suggestionGroup.ActionGroups);
        return actionGroups.find(actionGroup =>
            actionGroup.Suggestions.find(suggestion => suggestion.Id === suggestionId)
        );
    }

    suggestionHasSurvey(suggestion) {
        return suggestion && suggestion.SuggestionSurvey && suggestion.SuggestionSurveyId;
    }

    async getMessage(messageName) {
        if (!this.suggestionMetadata) {
            try {
                this.suggestionMetadata = await this.suggestionMetadataPromise;
            } catch (e) {
                this.throwCommandError("Could not retrieve Suggestion Metadata");
            }
        }
        return this.suggestionMetadata.messages[messageName];
    }

    hasValidOptions(options) {
        return options && options.record
            && (options.record.id === undefined || options.record.Id);
    }

    async loadSuggestionMetadata() {
        this.suggestionMetadataPromise = this.suggestionService.metadata();
    }

    // eslint-disable-next-line consistent-return
    async getSuggestionRecordTypeName(suggestionId) {
        try {
            // Forcing an await here make sure that we can catch the possible exception
            const recordTypeName = await this.suggestionService.recordTypeName(suggestionId);
            return recordTypeName;
        } catch (e) {
            this.throwCommandError("Could not retrieve RecordTypeName for " + suggestionId);
        }
    }

    // eslint-disable-next-line consistent-return
    async getSuggestionData(suggestionId, recordTypeName) {
        try {
            // Forcing an await here make sure that we can catch the possible exception
            const suggestionData = await this.suggestionService.suggestionData(suggestionId, recordTypeName);
            return suggestionData;
        } catch (e) {
            this.throwCommandError("Could not retrieve Suggestion Data for " + suggestionId);
        }
    }

    createCallObjectiveRecords(suggestions) {
        const callObjectives = suggestions.map(suggestion => ({
            callObjectiveRecordType: suggestion.CallObjectiveRecordType,
            callObjectiveCLMId: suggestion.CallObjectiveCLMID,
            title: suggestion.Title,
            accountId: suggestion.AccountId,
            suggestionReason: suggestion.Reason,
            suggestionId: suggestion.Id,
            onByDefault: suggestion.CallObjectiveOnByDefault,
            fromDate: suggestion.CallObjectiveFromDate,
            toDate: suggestion.CallObjectiveToDate
        }));
        return callObjectives;
    }

    throwCommandError(message) {
        this.myInsightsPageController.closeLoadingModal();
        super.throwCommandError(message);
    }
}