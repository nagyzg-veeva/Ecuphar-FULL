import { LightningElement, api, track } from 'lwc';
import { TimeoutError, AlignError, NotManagerError, NoFieldPlansError, AsyncProcessRunningError, ERROR_TYPES } from 'c/territoryFeedbackErrors';

const ERROR_TYPE_TO_VEEVA_MESSAGE_KEYS = new Map([
    [ERROR_TYPES.TIMEOUT, { header: 'ERROR_REQUEST_TIMEOUT', body: 'ERROR_REQUEST_TIMEOUT_DESCRIPTION' }],
    [ERROR_TYPES.UNAUTHORIZED, { header: 'ERROR_TIMEOUT', body: 'ERROR_TIMEOUT_DESCRIPTION' }],
    [ERROR_TYPES.PAGE_NOT_AVAILABLE, { header: 'ERROR_UNAVAILABLE', body: 'ERROR_UNAVAILABLE_DESCRIPTION' }],
    [ERROR_TYPES.NOT_MANAGER, { header: 'MANAGER_ACCESS_ONLY', body: null }],
    [ERROR_TYPES.NO_FIELD_PLANS, { header: 'NO_PLANS_AVAILABLE', body: null }],
    [ERROR_TYPES.ASYNC_PROCESS_RUNNING, { header: 'PROCESSING_FEEDBACK', body: 'PROCESSING_FEEDBACK_DESCRIPTION' }],
    [ERROR_TYPES.CONNECTION, { header: 'ERROR_NO_INTERNET_CONNECTION', body: 'ERROR_NO_INTERNET_DESCRIPTION_1' }]
]);

const VEEVA_MESSAGE_KEY_TO_DEFAULT_MESSAGE = new Map([
    ['ERROR_REQUEST_TIMEOUT', 'Request Timeout'],
    ['ERROR_REQUEST_TIMEOUT_DESCRIPTION', 'Your request has timed out.'],
    ['ERROR_TIMEOUT', 'Session Timeout'],
    ['ERROR_TIMEOUT_DESCRIPTION', 'Territory Feedback session timed out and requires re-loading to continue.'],
    ['ERROR_UNAVAILABLE', 'Feedback Unavailable'],
    ['ERROR_UNAVAILABLE_DESCRIPTION', 'Service is currently unavailable.  Try again later.'],
    ['MANAGER_ACCESS_ONLY', 'Manager access only'],
    ['NO_PLANS_AVAILABLE', 'No plans have been made available for feedback'],
    ['PROCESSING_FEEDBACK', 'Processing Feedback'],
    ['PROCESSING_FEEDBACK_DESCRIPTION', 'A large number of territories are currently having their statuses updated.  Please check back again in a few minutes.'],
    ['ERROR_NO_INTERNET_CONNECTION', 'No Internet Connection'],
    ['ERROR_NO_INTERNET_DESCRIPTION_1', 'Territory Feedback requires an internet connection.']
]); 

export default class TerritoryFeedbackErrorHandler extends LightningElement {
    get showTimeoutOrConnectionError() {
        return this.error && (this.error.errorType === ERROR_TYPES.TIMEOUT || this.error.errorType === ERROR_TYPES.CONNECTION);
    }

    get showAsyncProcessRunning() {
        return this.error && this.error.errorType === ERROR_TYPES.ASYNC_PROCESS_RUNNING;
    }

    get showPageNotAvailableError() {
        return this.error && this.error.errorType === ERROR_TYPES.PAGE_NOT_AVAILABLE;
    }

    get showUnauthorizedError() {
        return this.error && this.error.errorType === ERROR_TYPES.UNAUTHORIZED;
    }

    get showNoFieldPlansError() {
        return this.error && this.error.errorType === ERROR_TYPES.NO_FIELD_PLANS;
    }

    get showNotManagerError() {
        return this.error && this.error.errorType === ERROR_TYPES.NOT_MANAGER;
    }

    @track error;

    @api messageService;

    @api
    async renderError(error) {
        let errorType;

        if (error instanceof TimeoutError) {
            errorType = ERROR_TYPES.TIMEOUT;
        } else if (error instanceof AlignError) {
            errorType = error.isUnauthorizedError ? ERROR_TYPES.UNAUTHORIZED : ERROR_TYPES.PAGE_NOT_AVAILABLE;
        } else if (error instanceof NotManagerError) {
            errorType = ERROR_TYPES.NOT_MANAGER;
        } else if (error instanceof NoFieldPlansError) {
            errorType = ERROR_TYPES.NO_FIELD_PLANS;
        } else if (error instanceof AsyncProcessRunningError) {
            errorType = ERROR_TYPES.ASYNC_PROCESS_RUNNING;
        } else {
            errorType = window.navigator.onLine ? ERROR_TYPES.PAGE_NOT_AVAILABLE : ERROR_TYPES.CONNECTION;
        }

        await this.setError(errorType);
    }

    async setError(errorType) {
        const messageKeys = ERROR_TYPE_TO_VEEVA_MESSAGE_KEYS.get(errorType);
        const defaultHeaderMessage = VEEVA_MESSAGE_KEY_TO_DEFAULT_MESSAGE.get(messageKeys.header);
        const defaultBodyMessage = VEEVA_MESSAGE_KEY_TO_DEFAULT_MESSAGE.get(messageKeys.body);

        const errorHeader = await this.messageService.getMessageWithDefault(messageKeys.header, 'Feedback', defaultHeaderMessage);
        const errorBody = (messageKeys.body) ? 
            await this.messageService.getMessageWithDefault(messageKeys.body, 'Feedback', defaultBodyMessage) :
            null;

        this.error = {
            errorType: errorType,
            errorHeader: errorHeader,
            errorBody: errorBody
        };
    }
}