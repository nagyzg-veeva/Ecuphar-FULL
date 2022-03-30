import { api, LightningElement } from 'lwc';

export default class MyInsightsReportContainer extends LightningElement {
    @api url;
    @api htmlReportId;
    @api htmlReportUuid;
    @api maxHeight;

    defaultHeight = 150;

    dynamicResizingSupport = false;
    recentIFrameDimensionUpdate = false;
    hasAdditionalIFrameDimension = false;

    get iframe() {
        return this.template.querySelector("iframe");
    }

    connectedCallback() {
        window.addEventListener("message", this.handleMessage.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener("message", this.handleMessage.bind(this));
    }

    iframeContentLoaded() {
        this.sendHTMLReportIdToIFrame();
        this.retrieveIFrameDimensions();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if (!this.dynamicResizingSupport) {
                const oldLibraryHeight = this.maxHeight ?? this.defaultHeight;
                this.setReportUsingOldLibraryDimensions(oldLibraryHeight);
            }
        }, 500);
    }

    handleMessage(event) {
        const data = this.parseData(event);
        const commandName = data ? data.command : null;
        if (data && data.htmlReportId === this.htmlReportId && data.htmlReportUUID === this.htmlReportUuid) {
            switch (commandName) {
                case "iframeDimensions":
                    this.updateIFrameDimensions(data);
                    break;
                default:
                    break;
            }
        }
    }

    updateIFrameDimensions(data) {
        const newIFrameWindowDimensions = data.iframeDimensions;

        // We will only set the iframe dimensions if we haven't recently updated
        // the iframe dimensions
        if (!this.recentIFrameDimensionUpdate) {
            this.recentIFrameDimensionUpdate = true;
            this.setIFrameDimensionsUsingIFrameDimensions(newIFrameWindowDimensions);

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                // We will only consider updates additional updates after this timeout
                // The timeout will match the transition time that we have in CSS for the iframe
                // Note: this time should be long enough that we do not end up in a cycle for resizing
                this.recentIFrameDimensionUpdate = false;
                // If more dimension came in prior to the timeout we will make another request
                // to retrieve the iframe dimensions.
                if (this.hasAdditionalIFrameDimension) {
                    this.retrieveIFrameDimensions();
                    this.hasAdditionalIFrameDimension = false;
                }
            }, 300);
        } else {
            this.hasAdditionalIFrameDimension = true;
        }
    }

    setIFrameDimensionsUsingIFrameDimensions(newIFrameWindowDimensions) {
        let { height } = newIFrameWindowDimensions;
        const newIFrameHeight = this.maxHeight ? Math.min(this.maxHeight, height) : height;
        this.iframe.style.height = `${newIFrameHeight}px`;
        // We will set that our height was updated.
        // This means the HTML Report is using a version of MyInsights that supports dynamic resizing
        this.dynamicResizingSupport = true;
    }

    setReportUsingOldLibraryDimensions(oldLibraryHeight) {
        this.iframe.style.height = `${oldLibraryHeight}px`;
    }

    sendHTMLReportIdToIFrame() {
        this.sendMessageToIFrame({
            command: "setHTMLReportIdAndUUID"
        });
    }

    retrieveIFrameDimensions() {
        this.sendMessageToIFrame({
            command: "iframeDimensions"
        });
    }

    sendMessageToIFrame(message) {
        // We will always send the HTML Report Id and our UUID to the iframe
        message.htmlReportId = this.htmlReportId;
        message.htmlReportUUID = this.htmlReportUuid;
        this.iframe.contentWindow.postMessage(JSON.stringify(message), "*");
    }

    parseData(event) {
        if (typeof event.data === "string") {
            try {
                return JSON.parse(event.data);
            } catch {
                return event.data;
            }
        }
        return event.data;
    }
}