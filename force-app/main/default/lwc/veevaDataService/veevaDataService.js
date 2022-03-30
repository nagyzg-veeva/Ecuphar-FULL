export default class VeevaDataService {

    constructor(sessionService, requests) {
        this.sessionService = sessionService;
        this.requests = requests;
    }

    toQueryParams(params) {
        if (params instanceof Object) {
            return Object.keys(params).map(key => encodeURIComponent(key) + '=' + encodeURIComponent(params[key])).join('&');
        }
        return params;
    }

    async sendRequest(method, path, params, body=null , name) {
        let paramString = this.toQueryParams(params);
        if (typeof paramString === 'string') {
            path += '?'+ paramString;
        }

        let vodRequest = await this.initVodRequest();
        vodRequest.method = method;
        vodRequest.url += path;
        if (body) {
            vodRequest.body = JSON.stringify(body);
        }
        return this.request(vodRequest, name);
    }

    request(obj, name) {
        return new Promise((resolve, reject) => {
            //console.time(name);
            let xhr = new XMLHttpRequest();
            xhr.open(obj.method || "GET", obj.url);
            if (obj.headers) {
                Object.keys(obj.headers).forEach(key => {
                    xhr.setRequestHeader(key, obj.headers[key]);
                });
            }
            xhr.onload = () => {
                //console.timeEnd(name);
                this.requests.splice(this.requests.indexOf(name), 1);
                //console.log(JSON.stringify(JSON.parse(xhr.response), null, 2));
                if (xhr.status >= 200 && xhr.status < 300) {
                    resolve(this.safeJsonParse(xhr.response));
                } else {
                    reject(this.safeJsonParse(xhr.response));
                }
            };
            xhr.onerror = () => { this.requests.splice(this.requests.indexOf(name), 1); reject(this.safeJsonParse(xhr.response)); };
            this.requests.push(name);
            //console.log(JSON.stringify(obj, null, 2));
            xhr.send(obj.body);
        });
    }

    async logClientPageTiming(msg){
        if (msg){
            let vodRequest = await this.initVodRequest();
            vodRequest.url += '/api/v1/clientPageTiming';
            vodRequest.method = 'POST';
            vodRequest.body = JSON.stringify(msg);
            await this.request(vodRequest, 'logClientPageTiming');
        }
    }

    async save(changes) {
        if (changes) {
            let url = changes.type || changes.url;
            let data = changes.data || changes;
            if (url) {
                let vodRequest = await this.initVodRequest();
                vodRequest.url += '/api/v1/layout3/data/' + url + '?data-format=raw';
                vodRequest.method = 'POST';
                vodRequest.body = JSON.stringify(data);
                return this.request(vodRequest, 'save');
            }
        }
        return Promise.resolve({ data: {} }); // empty data
    }

    async lookupSearch(sObject, params) {
        let vodRequest = await this.initVodRequest();
        vodRequest.url += '/api/v1/layout3/lookup/' + sObject;
        let urlSearchParamsBuilder = new URLSearchParams();
        for (let [key, value] of Object.entries(params)) {
            // filter out null/undefined values but keep empty strings
            if (value != null) {
                urlSearchParamsBuilder.append(key, value);
            }
        }
        vodRequest.url += "?" + urlSearchParamsBuilder.toString();
        vodRequest.method = 'GET';
        return this.request(vodRequest, 'lookupSearch');
    }

    async initVodRequest() {
        let vodRequest = {};
        let vodInfo = await this.sessionService.getVodInfo();
        vodRequest.url = vodInfo.veevaServer;
        vodRequest.headers = { sfSession: vodInfo.sfSession, sfEndpoint: vodInfo.sfEndpoint, 'Content-Type': 'application/json' };
        return vodRequest;
    }

    async initMcRequest() {
        let mcRequest = {};
        let mcInfo = await this.sessionService.getVodInfo();
        mcRequest.url = mcInfo.mcServer + '/' + mcInfo.mcVersion;
        mcRequest.headers = { sfSession: mcInfo.sfSession, sfEndpoint: mcInfo.sfEndpoint };
        return mcRequest;
    }

    safeJsonParse(response) {
        try {
            return JSON.parse(response);
        } catch (err) {
            return response;
        }
    }

}