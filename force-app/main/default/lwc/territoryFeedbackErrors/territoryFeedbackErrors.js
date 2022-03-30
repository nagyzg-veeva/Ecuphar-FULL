export class TimeoutError extends Error {
    constructor(message) {
        super(message);
        this.name = 'TimeoutError';
    }
}
export class AlignError extends Error {
    constructor(message, isUnauthorizedError) {
        super(message);
        this.name = 'AlignError';
        this.isUnauthorizedError = isUnauthorizedError;
    }
}

export class NotImplementedError extends Error {
    constructor(message) {
        super(message);
    }
}

export class NoFieldPlansError extends Error {
    constructor(message) {
        super(message);
    }
}

export class NotManagerError extends Error {
    constructor(message) {
        super(message);
    }
}

export class AsyncProcessRunningError extends Error {
    constructor(message) {
        super(message);
    }
}

export const ERROR_TYPES = {
    TIMEOUT: 'Timeout',
    UNAUTHORIZED: 'Unauthorized',
    PAGE_NOT_AVAILABLE: 'PageNotAvailable',
    CONNECTION: 'Connection',
    ASYNC_PROCESS_RUNNING: 'AsyncProcessRunning',
    NOT_MANAGER: 'NotManager',
    NO_FIELD_PLANS: 'NoFieldPlans'
};