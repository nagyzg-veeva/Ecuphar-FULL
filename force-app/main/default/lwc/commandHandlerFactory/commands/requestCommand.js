import CommandError from "c/commandError";
import CommandHandler from "./commandHandler";

export default class RequestCommand extends CommandHandler {
    async response(requestObject) {
        const {
            url,
            body,
        } = requestObject;
        const method = requestObject.method || "GET";
        const expect = requestObject.expect || "text";
        const headers = requestObject.headers || {};
        const timeout = requestObject.timeout || 30;
        return this.executeRequest(url, method, body, headers, expect, timeout);
    }

    executeRequest(url, method, body, headers, expect, timeout) {
        return new Promise((resolve, reject) => {
            const headerKeys = Object.keys(headers);
            const request = new XMLHttpRequest();

            request.open(method, url);
            if (expect === 'blob') {
                //set response type to array buffer is binary data is expected
                request.responseType = 'arraybuffer';
            }

            // Set each header
            headerKeys.forEach(key => {
                request.setRequestHeader(key, headers[key]);
            });

            // Set timeout from seconds to milliseconds
            request.timeout = timeout * 1000;

            //handle 'successful' load
            request.onload = () => this.handleRequestLoad(request, expect, resolve, reject);
            //handle 'failed' load
            request.onerror = () => this.handleRequestError(request, expect, reject, expect);
            //handle timeout
            request.ontimeout = () => this.handleTimeoutError(reject);

            request.send(body);
        });
    }

    handleRequestLoad(request, expect, resolve, reject) {
        if (request.status < 400) {
            resolve(this.formatHttpResponse(request, expect, true));
        } else {
            this.performReject(reject, this.formatHttpResponse(request, expect, false));
        }
    }

    handleRequestError(request, expect, reject) {
        this.performReject(reject, this.formatHttpResponse(request, expect, false));
    }

    handleTimeoutError(reject) {
        var errorResponse = {
            success: false,
            code: 4,
            message: 'Timeout value exceeded'
        };
        this.performReject(reject, errorResponse);
    }

    formatHttpResponse(request, expect, isSuccess) {
        const formattedResponse = {};
        formattedResponse.success = isSuccess;
        formattedResponse.data = {};
        formattedResponse.data.statusCode = request.status;
        formattedResponse.data.headers = this.parseHeaderString(request.getAllResponseHeaders());
        if (isSuccess) {
            if (expect === 'blob') {
                formattedResponse.data.body = this.parseBlob(request, formattedResponse);
            } else {
                formattedResponse.data.body = request.responseText;
            }
        } else {
            formattedResponse.code = request.status;
            formattedResponse.data.body = request.responseText;
        }
        return formattedResponse;
    }

    parseBlob(request) {
        //if blob, read response as arraybuffer and encode to base64
        let codes = new Uint8Array(request.response);
        let bin = "";
        for (let i = 0; i < codes.length; i++) {
            bin += String.fromCharCode(codes[i]);
        }
        return btoa(bin);
    }

    parseHeaderString(headerString) {
        var headerObject = {};
        var headerKeyValuePairs = headerString.split('\r\n');
        headerKeyValuePairs
            .filter(keyValuePair => keyValuePair)
            .forEach(keyValuePair => {
                var keyValue = keyValuePair.split(':');
                headerObject[keyValue[0]] = keyValue[1];
            });
        return headerObject;
    }

    performReject(reject, rejectBody) {
        const commandError = new CommandError({
            ...rejectBody
        }, this.constructor.name);
        reject(commandError);
    }
}