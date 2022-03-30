export default class SuggestionService {
    constructor(veevaDataService) {
        this.veevaDataService = veevaDataService;
    }

    async dismiss(accountId, suggestionId) {
        const dismissRequest = await this.makeCrmRequest("/api/v1/suggestion/action/dismiss");
        dismissRequest.method = "POST";
        dismissRequest.body = JSON.stringify({
            accountId: accountId,
            suggestionId: suggestionId
        });
        return this.veevaDataService.request(dismissRequest);
    }

    async surveyDismiss(suggestion, suggestionQuestions) {
        const dismissRequest = await this.makeCrmRequest("/api/v1/suggestion/action/surveydismiss");
        dismissRequest.method = "POST";
        const suggestionSurveyDismissRequestBody = {
            suggestion_dismissed_with_survey: true,
            surveyId: suggestion.SuggestionSurvey.Id,
            fieldErrors: {},
            type: "Suggestion_Survey_vod",
            Id: suggestion.Id,
            AccountId: suggestion.AccountId
        };
        suggestionQuestions.forEach(question => {
            suggestionSurveyDismissRequestBody[question.id] = question.value;
        });
        dismissRequest.body = JSON.stringify(suggestionSurveyDismissRequestBody);
        return this.veevaDataService.request(dismissRequest);
    }

    async complete(accountId, suggestionId) {
        const completeRequest = await this.makeCrmRequest("/api/v1/suggestion/action/markascomplete");
        completeRequest.method = "POST";
        completeRequest.body = JSON.stringify({
            accountId: accountId,
            suggestionId: suggestionId
        });
        return this.veevaDataService.request(completeRequest);
    }

    async createCall(accountId, suggestionId, plannedCallDate) {
        const createCallRequest = await this.makeCrmRequest("/api/v1/suggestion/action/call");
        const vodInfo = await this.veevaDataService.sessionService.getVodInfo();
        const { sfEndpoint, sfSession, veevaVersion, veevaServer } = vodInfo;
        const baseVeevaServerUrl = new URL(veevaServer);
        createCallRequest.method = "POST";
        createCallRequest.body = JSON.stringify({
            accountId: accountId,
            suggestionId: suggestionId,
            plannedCallDate: plannedCallDate,
            sfSession: sfSession,
            sfEndpoint: sfEndpoint,
            version: veevaVersion,
            baseUrl: baseVeevaServerUrl.origin
        });
        return this.veevaDataService.request(createCallRequest);
    }

    async createCallObjectives(callObjectives) {
        const callObjectiveRequest = await this.makeCrmRequest("/api/v1/suggestion/action/callObjective");
        callObjectiveRequest.method = "POST";
        callObjectiveRequest.body = JSON.stringify({
            objectives: callObjectives
        });
        return this.veevaDataService.request(callObjectiveRequest);
    }

    async metadata() {
        const suggestionMetadataRequest = await this.makeCrmRequest("/api/v1/suggestion/list/metadata");
        const response = await this.veevaDataService.request(suggestionMetadataRequest);
        return response.data;
    }

    // eslint-disable-next-line consistent-return
    async recordTypeName(suggestionId) {
        const suggestionRecordTypeRequest = await this.makeCrmRequest(`/api/v1/suggestion/data/${suggestionId}/recordTypeName`);
        const response = await this.veevaDataService.request(suggestionRecordTypeRequest);
        return response.recordTypeName;
    }

    // eslint-disable-next-line consistent-return
    async suggestionData(suggestionId, recordTypeName) {
        const requestPath = `/api/v1/suggestion/data?recordType=${recordTypeName}&suggestionId=${suggestionId}`;
        const suggestionDataRequest = await this.makeCrmRequest(requestPath);
        const response = await this.veevaDataService.request(suggestionDataRequest);
        return response.data;
    }

    async makeCrmRequest(path) {
        const crmRequest = await this.veevaDataService.initVodRequest();
        crmRequest.url += path;
        return crmRequest;
    }
}