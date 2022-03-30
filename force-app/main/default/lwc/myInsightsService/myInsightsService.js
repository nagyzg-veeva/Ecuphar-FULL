const CDN_DOMAIN_REQUEST_PATH = "/api/v1/custom-reports/metadata/cdn";
const CDN_AUTH_REQUEST_PATH = "/api/v1/mcservice/token/cdn";
const HTML_REPORTS_CDN_DOMAIN_SESSION_KEY = "html-reports-cdn-domain";

export default class MyInsightsService {

    constructor(dataSvc, sessionSvc) {
        this.dataSvc = dataSvc;
        this.sessionSvc = sessionSvc;
    }

    async retrieveCdnDomain() {
        const validStoredCdnDomain = validCdnDomainFromSessionStorage();
        if (validStoredCdnDomain) {
            return validStoredCdnDomain;
        }

        const validOrNullCdnDomain = await this.validOrNullCdnDomainFromCrm();
        if (validOrNullCdnDomain) {
            storeCdnDomain(validOrNullCdnDomain);
        }
        return validOrNullCdnDomain;
    }

    async validOrNullCdnDomainFromCrm() {
        const response = await this.crmRequest(CDN_DOMAIN_REQUEST_PATH, null, "cdnDomainUrl");
        if (response.status === "FAILURE" || !response.data || !response.data.cdnDomain) {
            logError("Could not retrieve CDN Domain from CRM", response);
            return null;
        }
        return response.data.cdnDomain;
    }

    async retrieveCdnAuthToken(cdnContentUrl) {
        const request = {
            method: "POST",
            body: `path=${cdnContentUrl}`,
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            }
        };
        const response = await this.mcRequest(CDN_AUTH_REQUEST_PATH, request, "cdnAuthToken");
        if (response.status === "FAILURE" || !response.payload || !response.payload[cdnContentUrl]) {
            logError("Could not retrieve CDN Authorization Token from MC", response);
            return null;
        }
        return response.payload[cdnContentUrl];
    }

    async retrieveOrgId() {
        const vodInfo = await this.sessionSvc.getVodInfo();
        return vodInfo.orgId;
    }

    async crmRequest(path, request, requestName) {
        // Gets Request with CRM URL and sfSession/sfEndpoint headers
        let vodRequest = await this.dataSvc.initVodRequest();
        vodRequest = mergeRequests(request, vodRequest);
        vodRequest.url += path;

        try {
            return await this.request(vodRequest, requestName);
        } catch (err) {
            return {};
        }
    }

    async mcRequest(path, request, requestName) {
        const vodInfo = await this.sessionSvc.getVodInfo();
        // Gets Request with CRM URL and sfSession/sfEndpoint headers
        let vodRequest = await this.dataSvc.initVodRequest();
        vodRequest = mergeRequests(request, vodRequest);
        // Updates URL to retrieve CDN Auth Token from MC
        vodRequest.url = `${vodInfo.mcServer}/${vodInfo.mcVersion}${path}`;

        try {
            return await this.request(vodRequest, requestName);
        } catch (err) {
            return {};
        }
    }

    async request(request, requestName) {
        return this.dataSvc.request(request, requestName);
    }
}

function mergeRequests(request, vodRequest) {
    request = request || {};
    const mergedRequest = Object.assign({}, vodRequest);
    // We only care about method, headers and body
    if (request.method) {
        // override method property
        mergedRequest.method = request.method;
    }

    if (request.body) {
        // override body property
        mergedRequest.body = request.body;
    }

    if (request.headers) {
        // Copy each key and since we want to maintain existing headers from vodRequest
        Object.keys(request.headers).forEach(key => {
            mergedRequest.headers[key] = request.headers[key];
        });
    }

    return mergedRequest;
}

function logError(msg, err) {
    console.error(msg, err);
}

function validCdnDomainFromSessionStorage() {
    const cdnDomain = sessionStorage.getItem(HTML_REPORTS_CDN_DOMAIN_SESSION_KEY);
    if (!cdnDomain) {
        return null
    }
    const cdnDomainParsed = JSON.parse(cdnDomain);
    if (expiredDate(cdnDomainParsed.expirationDate)) {
        return null;
    }
    return cdnDomainParsed.cdnDomain;
}

function storeCdnDomain(cdnDomain) {
    const expirationDate = new Date(Date.now());
    // Valid for one hour
    expirationDate.setHours(expirationDate.getHours() + 1);
    sessionStorage.setItem(HTML_REPORTS_CDN_DOMAIN_SESSION_KEY, JSON.stringify({
        cdnDomain: cdnDomain,
        expirationDate: expirationDate
    }));
}

function expiredDate(expirationDateStoredString) {
    const expirationDate = expirationDateStoredString ? new Date(Date.parse(expirationDateStoredString)) : null;
    const currentDate = new Date(Date.now());
    return expirationDate && expirationDate < currentDate;
}