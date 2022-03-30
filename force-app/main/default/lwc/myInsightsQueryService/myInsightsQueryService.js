const SALESFORCE_API_VERSION = "52.0";
const REQUEST_TIMEOUT_MS = 60000;

class QueryTimeoutError extends Error { }

export default class MyInsightsQueryService {
    constructor(veevaSessionService) {
        this.veevaSessionService = veevaSessionService;
        this.updatedRequestDomain = null;
    }

    async query(query) {
        const response = await this.sendQuery(query);
        if (response.success) {
            const queryResult = response.data;
            queryResult.records = await this.queryAllRecords(queryResult);
        }
        return response;
    }

    async queryAllRecords(queryResult) {
        let records = queryResult.records;
        let nextRecordsUrl = queryResult.nextRecordsUrl;
        let done = queryResult.done;
        // Retrieve all records
        while (!done && nextRecordsUrl) {
            // eslint-disable-next-line no-await-in-loop
            const nextRecordsUrlResponse = await this.fetchNextRecords(nextRecordsUrl);
            if (nextRecordsUrlResponse.ok) {
                // eslint-disable-next-line no-await-in-loop
                const nextRecordsQueryResult = await nextRecordsUrlResponse.json();
                records = records.concat(nextRecordsQueryResult.records);
                nextRecordsUrl = nextRecordsQueryResult.nextRecordsUrl;
                done = nextRecordsQueryResult.done;
            } else {
                console.error("Failed to query more records");
                nextRecordsUrl = null;
            }
        }
        return records;
    }

    async sendQuery(query) {
        const compositeRequest = this.createCompositeRequestForSingleQuery(query);
        try {

            let response = await this.performCompositeRequest(compositeRequest);

            // Following a redirected POST Request results in a GET request.
            // This is not desired so we will make another POST request with the new domain.
            if (response.redirected) {
                this.updateRequestDomain(response.url);
                response = await this.performCompositeRequest(compositeRequest);
            }
            if (!response.ok) {
                return this.createErrorResponse(response);
            }

            const compositeResponses = (await response.json()).compositeResponse;
            if (compositeResponses.length === 0) {
                return this.createErrorResponse(response, [{
                    message: `Failed to perform query - ${query}`
                }]);
            }

            const compositeResponse = compositeResponses[0];
            if (compositeResponse.httpStatusCode >= 400) {
                const errorData = compositeResponse.body;
                const errorStatus = compositeResponse.httpStatusCode;
                return this.createErrorResponse(response, errorData, errorStatus);
            }

            return {
                success: true,
                data: compositeResponse.body
            };
        } catch (e) {
            return this.handleErrorFromRequest(e);
        }
    }

    async performCompositeRequest(compositeRequest) {
        const requestOptions = await this.baseRequestOptions();
        requestOptions.method = "POST";
        requestOptions.body = JSON.stringify(compositeRequest);
        const requestDomain = this.getRequestDomain();
        try {
            const response = await this.sendRequestWithTimeout(`${requestDomain}/services/data/v${SALESFORCE_API_VERSION}/composite/`, requestOptions, REQUEST_TIMEOUT_MS);
            return response;
        } catch (e) {
            if (e instanceof QueryTimeoutError) {
                throw e;
            }
            // In Safari we get an error on redirects because the redirect response does not have the 'Access-Control-Allow-Origin' header
            // This prevents us from determining where the redirect response is trying to redirect us.
            // We will retry the request using the sfEndpoint's domain
            return this.retryRequestWithSfEndpoint(requestOptions);
        }
    }

    async retryRequestWithSfEndpoint(requestOptions) {
        const { sfEndpoint } = await this.veevaSessionService.getVodInfo();
        // We will update the request domain to continue to use the sfEndpoint's domain 
        this.updateRequestDomain(sfEndpoint);
        // Retrieves only the domain from sfEndpoint
        const sfEndpointDomain = this.getRequestDomain();

        // If we still have an error that means another error occurred unrelated to redirects.
        return this.sendRequestWithTimeout(`${sfEndpointDomain}/services/data/v${SALESFORCE_API_VERSION}/composite/`, requestOptions, REQUEST_TIMEOUT_MS);
    }

    createCompositeRequestForSingleQuery(query) {
        const formattedQuery = this.formatQuery(query);
        const compositeSubrequest = {
            method: "GET",
            referenceId: "query",
            url: `/services/data/v${SALESFORCE_API_VERSION}/query/?q=${formattedQuery}`
        };
        return {
            allOrNone: true,
            collateSubrequests: true,
            compositeRequest: [compositeSubrequest]
        };
    }

    async fetchNextRecords(nextRecordsUrl) {
        const requestOptions = await this.baseRequestOptions();
        // Since the nextRecordsUrl is a path to the next set of records to retrieve, we will need to retrieve the domain ourselves,
        // in case that there was a redirect for our initial request to get the first set of records that means that we need to request
        // from a new domain (this.getRequestDomain will retrieve the updated domain).
        const requestDomain = this.getRequestDomain();
        try {
            const nextRecords = await this.sendRequestWithTimeout(`${requestDomain}${nextRecordsUrl}`, requestOptions, REQUEST_TIMEOUT_MS);
            return nextRecords;
        } catch (e) {
            return this.handleErrorFromRequest(e);
        }
    }

    async sendRequestWithTimeout(url, requestOptions, timeout) {
        return new Promise((resolve, reject) => {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            const requestTimeoutId = setTimeout(() => {
                reject(new QueryTimeoutError(`Request made to ${url} timed out`));
            }, timeout);

            fetch(url, requestOptions).then(response => {
                clearTimeout(requestTimeoutId);
                resolve(response);
            }).catch(error => {
                clearTimeout(requestTimeoutId);
                reject(error);
            });
        });
    }

    async baseRequestOptions() {
        const { sfSession } = await this.veevaSessionService.getVodInfo();
        return {
            method: "GET",
            redirect: "follow",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${sfSession}`
            }
        };
    }

    async createSuccessResponse(response) {
        return {
            success: true,
            data: await response.json()
        };
    }

    async createErrorResponse(response, errorData, errorStatus) {
        errorData = errorData || await response.json();
        errorStatus = errorStatus || response.statusText || response.status;
        return {
            success: false,
            error: {
                errorData: errorData,
                errorStatus: errorStatus
            }
        };
    }

    formatQuery(query) {
        return encodeURIComponent(query);
    }

    async handleErrorFromRequest(e) {
        const message = e.message;
        const statusText = e instanceof QueryTimeoutError ? "Timeout" : "Request Failed"
        return this.createErrorResponse(
            {
                statusText: statusText
            },
            [{
                message: message
            }]
        );
    }

    getRequestDomain() {
        // If updatedRequestDomain is defined this means that one of our previous requests has been redirected so we will go ahead and use the redirected domain for consecutive requests.
        return this.updatedRequestDomain ?? "";
    }

    updateRequestDomain(url) {
        const redirectedUrl = new URL(url);
        // response.url will have the new domain that we will continue to use since we currently have our requests follow the redirect.
        // The reason we only care about the domain is because the only time we will get a redirect from Salesforce
        // is if they want us to use a different domain.
        this.updatedRequestDomain = redirectedUrl.origin;
    }
}