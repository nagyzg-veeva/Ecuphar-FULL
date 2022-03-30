import FieldPlanRecord from "c/fieldPlanRecord";
import { TimeoutError, AlignError, NoFieldPlansError } from "c/territoryFeedbackErrors";

export default class TerritoryFeedbackService {
    static FEEDBACK_PATH = '/align/feedback';
    static LOGIN_PATH = '/login';
    static FIELD_PLANS_PATH = '/manager/field-plans';
    static REQUEST_TIMEOUT_MS = 20000;
    static POST_REQUEST_TIMEOUT_MS = 60000;

    // CRM-234394 temporarily add auth params to constructor so that they can be sent with every request
    // Remove after ALN-25276 is resolved
    constructor(alignServer, alignVersion, sfUserId, sfUserLanguage, sfSession, sfEndpoint) {
        this._alignServer = convertToRedesignedFeedbackURL(alignServer);
        this._alignVersion = alignVersion;
        this._sfUserId = sfUserId;
        this._sfUserLanguage = sfUserLanguage;
        this._sfSession = sfSession;
        this._sfEndpoint = sfEndpoint;
    }

    async login(/* sfUserId, sfUserLanguage, sfSession, sfEndpoint */) {
        return this.getRequest(`${this.feedbackApiPathString}${TerritoryFeedbackService.LOGIN_PATH}`);
    }

    async getFieldPlans() {
        const json = await this.getRequest(`${this.feedbackApiPathString}${TerritoryFeedbackService.FIELD_PLANS_PATH}`);
        json.fieldPlans = json.fieldPlans.map(fieldPlan => new FieldPlanRecord(fieldPlan));
        return json;
    }

    async getFieldPlanInfo(fieldPlanId) {
        const json = await this.getRequest(this.getFieldPlanInfoUrlString(fieldPlanId));
        return new FieldPlanRecord(json);
    }

    async bulkApproveOrRejectPendingChallenges(territoryModelId, shouldApprove) {
        return this.postRequest(this.getBulkChallengesUrl(territoryModelId), { isApprove: shouldApprove });
    }

    async moveToLifecycleState(territoryModelId, targetLifecycleState, runAsynchronously) {
        return this.postRequest(this.getMoveToLifecycleStateUrl(territoryModelId, runAsynchronously), { lifecycleStateAction: targetLifecycleState });
    }

    async getAsynchronousProcessFlag() {
        const json = await this.getRequest(this.asynchronousProcessFlagUrl);
        return json.asynchronousProcessRunning;
    }

    async getTerritoryModelDetails(territoryModelId, filter) {
        const url = this.getTerritoryModelDetailsUrl(territoryModelId);
        return filter ? this.getRequest(url, { filter: filter }) : this.getRequest(url);
    }

    async approveOrRejectChallenges(territoryModelId, accountIds, shouldApprove, filter) {
        const requestData = {
            approve: shouldApprove,
            accountIds: accountIds
        };
        if (filter && shouldApprove && accountIds.length === 1) {
            requestData.filter = filter;
        }

        return this.postRequest(this.getAccountChallengesUrl(territoryModelId), null, requestData);
    }

    get feedbackApiPathString() {
        return `https://${this._alignServer}${TerritoryFeedbackService.FEEDBACK_PATH}`;
    }

    get loginUrlString() {
        return `${this.feedbackApiPathString}${TerritoryFeedbackService.LOGIN_PATH}`;
    }

    get fieldPlansUrlString() {
        return `${this.feedbackApiPathString}${TerritoryFeedbackService.FIELD_PLANS_PATH}`;
    }

    get asynchronousProcessFlagUrl() {
        return `${this.feedbackApiPathString}/manager/async-processing-flag`;
    }

    getFieldPlanInfoUrlString(fieldPlanId) {
        return `${this.fieldPlansUrlString}/${fieldPlanId}`
    }

    getBulkChallengesUrl(territoryModelId) {
        return `${this.feedbackApiPathString}/manager/territory-model/${territoryModelId}/hierarchy/challenges`;
    }

    getMoveToLifecycleStateUrl(territoryModelId, runAsynchronously) {
        return `${this.feedbackApiPathString}/manager/territory-model/${territoryModelId}/hierarchy/lifecycle-state/${runAsynchronously ? 'async' : 'sync'}`;
    }

    getTerritoryModelDetailsUrl(territoryModelId) {
        return `${this.feedbackApiPathString}/territory/${territoryModelId}`;
    }

    getAccountChallengesUrl(territoryModelId) {
        return `${this.feedbackApiPathString}/manager/territory-model/${territoryModelId}/challenges`;
    }

    async postRequest(urlString, queryParams, requestData) {
        const url = new URL(urlString);

        // CRM-234394 temporarily add auth params to every request
        // Remove after ALN-25276 is resolved
        url.search = this.getQueryParamsWithAuth(queryParams);

        const requestInit = {
            method: 'POST'
        };
        if (requestData) {
            requestInit.headers = {
                'Content-Type': 'application/json'
            };
            requestInit.body = JSON.stringify(requestData);
        }

        const response = await timeoutPromise(TerritoryFeedbackService.POST_REQUEST_TIMEOUT_MS, fetch(url, requestInit));

        if (!response.ok) {
            const isUnauthorizedError = response.status === 401;
            throw new AlignError(response.statusText, isUnauthorizedError);
        }

        return response.json();
    }

    async getRequest(urlString, queryParams) {
        const url = new URL(urlString);

        // CRM-234394 temporarily add auth params to every request
        // Remove after ALN-25276 is resolved
        url.search = this.getQueryParamsWithAuth(queryParams);

        const response = await timeoutPromise(TerritoryFeedbackService.POST_REQUEST_TIMEOUT_MS, fetch(url));

        if (!response.ok) {
            if (response.status === 400) {
                const errorBody = await response.json();
                throw new NoFieldPlansError(errorBody.message);
            } else {
                const isUnauthorizedError = response.status === 401;
                throw new AlignError(response.statusText, isUnauthorizedError);
            }
        }

        return response.json();
    }

    // CRM-234394 temporarily add auth params to every request
    // Remove after ALN-25276 is resolved
    getQueryParamsWithAuth(queryParams) {
        const authParams = {
            crmUserId: this._sfUserId,
            crmLanguage: this._sfUserLanguage,
            sfSession: this._sfSession,
            sfEndpoint: this._sfEndpoint
        };

        if (queryParams) {
            Object.assign(authParams, queryParams);
        }

        return new URLSearchParams(authParams);
    }
}

function timeoutPromise(ms, promise) {
    return new Promise((resolve, reject) => {
        const timeoutId = setTimeout(() => {
            reject(new TimeoutError("Request to Align timed out"))
        }, ms);

        promise.then(
            (res) => {
                clearTimeout(timeoutId);
                resolve(res);
            },
            (err) => {
                clearTimeout(timeoutId);
                reject(err);
            }
        );
    })
}

function convertToRedesignedFeedbackURL(alignServer) {
    return alignServer.replace('-app.', '-feedback.');
}