import CommandError from "c/commandError";

export default class MyInsightsLightningBridge {

    static _recentRequests = {};

    constructor(iframeOrigin, htmlReportId, htmlReportUUID, commandHandlers) {
        this.iframeOrigin = iframeOrigin;
        this.htmlReportId = htmlReportId;
        this.htmlReportUUID = htmlReportUUID;
        this.commandHandlers = commandHandlers;
        window.addEventListener('message', this.handleMessage.bind(this));
    }

    async handleMessage(event) {
        const sourceIFrame = event.source;
        const messageFromIFrame = this.getMessage(event);

        // Check to see that the origin of the message matches our expected iframe origin
        // We will also check to see that the message has a command
        if (event.origin === this.iframeOrigin && this.hasCommand(messageFromIFrame)) {
            if (this.hasMatchingHtmlReport(messageFromIFrame) || this.usingOldLibraryAndMessageNotHandled(messageFromIFrame)) {
                // Check commandHandlers to see if we support this message
                const handler = this.commandHandlers[messageFromIFrame.command];
                if (handler) {
                    await this.handleMessageWithCommandHandler(handler, messageFromIFrame, sourceIFrame);
                }
            } else if (this.messageAlreadyHandledForOlderLibraries(messageFromIFrame)) {
                // In the case that the HTML Report is using an older Library and we have "recently" (in the past few ms)
                // handled this message we will return the response we generated earlier.
                const dataPromise = this.getStoredRecentRequest(messageFromIFrame);
                await this.sendDataPromiseBackToIFrame(dataPromise, messageFromIFrame, sourceIFrame);
            }
        }
    }

    async handleMessageWithCommandHandler(commandHandler, messageFromIFrame, sourceIFrame) {
        const dataPromise = commandHandler.response(messageFromIFrame);
        if (this.usingOldLibrary(messageFromIFrame)) {
            this.addHandledMessageForOlderLibrary(messageFromIFrame, dataPromise);
        }
        await this.sendDataPromiseBackToIFrame(dataPromise, messageFromIFrame, sourceIFrame);
    }

    async sendDataPromiseBackToIFrame(dataPromise, messageFromIFrame, sourceIFrame) {
        try {
            const data = await dataPromise;
            // If data is null this means that we intentionally do not want to return a response
            if (data !== null) {
                this.sendResponse(messageFromIFrame, data, sourceIFrame);
            }
        } catch (err) {
            let errorData = { message: err.message };
            if (err instanceof CommandError) {
                errorData = err.errorData;
            }
            this.sendErrorResponse(messageFromIFrame, errorData, sourceIFrame);
        }
    }

    sendResponse(messageFromIFrame, data, sourceIFrame) {
        const responseMessage = this.createResponse(messageFromIFrame, "queryReturn", data);
        sourceIFrame.postMessage(JSON.stringify(responseMessage), "*");
    }

    sendErrorResponse(messageFromIFrame, errorData, sourceIFrame) {
        // Make sure that we set success to false when we send a message back to the sourceIFrame
        errorData.success = false;
        const responseMessage = this.createResponse(messageFromIFrame, "error", errorData);
        sourceIFrame.postMessage(JSON.stringify(responseMessage), "*");
    }

    createResponse(messageFromIFrame, command, data) {
        let responseMessage = {};
        if (data) {
            // We will copy data directly into the response since each Command
            // is handled differently. So we will simply take the response and
            // place additional properties such as command, deferredId, and messageId
            responseMessage = Object.assign(responseMessage, data);
        }
        // For some reason order of the body matters :(
        // since we need to support older MyInsight Library versions we need to keep
        // the order like this
        responseMessage.command = command;
        // Generally we will have either deferredId or messageId, so one of them will be undefined
        responseMessage.deferredId = messageFromIFrame.deferredId;
        responseMessage.messageId = messageFromIFrame.messageId;
        return responseMessage;
    }

    getMessage(event) {
        if (typeof event.data === 'string') {
            try {
                return JSON.parse(event.data);
            } catch {
                return event.data;
            }
        }
        return event.data;
    }

    hasCommand(messageFromIFrame) {
        return messageFromIFrame && messageFromIFrame.command;
    }

    hasMatchingHtmlReport(messageFromIFrame) {
        return messageFromIFrame
            // We will handle the scenario where htmlReportUUID is undefined, this means that the iframe sent a message
            // before it received our UUID
            && (messageFromIFrame.htmlReportId === this.htmlReportId && messageFromIFrame.htmlReportUUID === undefined)
            || (messageFromIFrame.htmlReportId === this.htmlReportId && messageFromIFrame.htmlReportUUID === this.htmlReportUUID)
    }

    usingOldLibraryAndMessageNotHandled(messageFromIFrame) {
        return messageFromIFrame
            && this.usingOldLibrary(messageFromIFrame) && !this.messageAlreadyHandledForOlderLibraries(messageFromIFrame)
    }

    usingOldLibrary(messageFromIFrame) {
        return (messageFromIFrame.htmlReportId === undefined && messageFromIFrame.htmlReportUUID === undefined);
    }

    messageAlreadyHandledForOlderLibraries(messageFromIFrame) {
        const messageIdentifier = this.getMessageIdentifierForOlderLibraries(messageFromIFrame);
        const handledMessage = MyInsightsLightningBridge._recentRequests[messageIdentifier];
        return handledMessage && Date.now() < handledMessage.expirationTimeInMs;
    }

    /**
     * When the HTML Report is using an older MyInsights library it is possible that we may receive the same request multiple times
     * if there is more than one HTML Report on the screen and a single HTML Report is using a older MyInsights Library.
     *
     * This is a problem when we attempt to perform interactions with the user in Lightning, such as showing a modal to the user.
     *
     * The "simple" solution is to have the customer use our newer MyInsights library that has a UUID and HTML Report Id in each request.
     * However, if they choose to use a HTML Report with an older MyInsights library we need to "gracefully" handle the case where
     * one of the HTML Reports uses the older HTML Report (even if the other HTML Reports use the newer MyInsights library).
     *
     * The approach is to register the message as handled for 10 milliseconds and not respond to this request again for up to that time.
     * The identifier we will use for the request is the command-deferredId (or command-messageId).
     *
     * This will be an issue if the customer places two or more HTML Reports that are the exact same Report meaning the requests will be exactly the same.
     * This case would require that the user updates the MyInsights Library used or only place one of each HTML Report on the screen.
     *
     */
    addHandledMessageForOlderLibrary(messageFromIFrame, result) {
        const messageIdentifier = this.getMessageIdentifierForOlderLibraries(messageFromIFrame);
        MyInsightsLightningBridge._recentRequests[messageIdentifier] = {
            expirationTimeInMs: Date.now() + 10, // expiration is in ms
            result: result // some Promise
        };
    }

    /**
     * Determines an identifier for the message from the iframe.
     *
     * Each message has either a messageId or deferredId and command:
     *   - messageId is a simple increment from 0 on up for the iframe
     *   - deferredId uses Date, so it represents "exactly" when the message was created
     *
     * The command and messageId/deferredId are not sufficient to uniquely identify them for older
     * MyInsights Libraries is that two HTML Reports could request the same command at the same time (or messageId).
     * This means that we need a more unique identifier meaning we need to use the whole message
     */
    getMessageIdentifierForOlderLibraries(messageFromIFrame) {
        return JSON.stringify(messageFromIFrame);
    }

    getStoredRecentRequest(messageFromIFrame) {
        if (!messageFromIFrame) {
            return null;
        }
        const messageIdentifier = this.getMessageIdentifierForOlderLibraries(messageFromIFrame);
        return MyInsightsLightningBridge._recentRequests[messageIdentifier].result;
    }
}