import CommandHandler from "./commandHandler";
import CommandError from "c/commandError";
import { createMessageContext, publish } from "lightning/messageService";
import myInsightsNavigationChannel from "@salesforce/messageChannel/MyInsights_Navigation__c";
import MEDICAL_INQUIRY_OBJ from "@salesforce/schema/Medical_Inquiry_vod__c";

export default class NewRecordCommand extends CommandHandler {

    veevaDataService;
    constructor(veevaUserInterfaceAPI, veevaDataService) {
        super(veevaUserInterfaceAPI);
        this.veevaDataService = veevaDataService;
        this.messageContext = createMessageContext();
    }

    async response(config) {
        const object = config.configObject.object;
        if (object) {
            const fields = config.configObject.fields;
            const newRecordRequest = await this.newRecordRequest(object, fields);
            await this.navigateToNewRecord(newRecordRequest, object, fields);
        }
    }

    async navigateToNewRecord(newRecordRequest, object, fields) {
        try {
            // The request to CRM will determine if we support this object
            // For instance even if a user has access to "Account" objects we will not reach
            // navigate to create a new Account record from this newRecord command
            const response = await this.veevaDataService.request(newRecordRequest);
            if (response.data.success && response.data.url) {
                if (object === MEDICAL_INQUIRY_OBJ.objectApiName) {
                    this.navigateUsingRecordTypeSelector(object, fields);
                } else {
                    // Once we know that this object is supported we will go ahead and navigate
                    this.navigateUsingLightning(response.data.url);
                }
            } else {
                this.throwCommandError(response.data.errorMessage);
            }
        } catch (e) {
            let message = e.message;
            if (e instanceof CommandError) {
                message = e.errorData.message;
            }
            this.throwCommandError("Could not navigate to new record url - " + message);
        }
    }

    navigateUsingRecordTypeSelector(object, fields) {
        publish(this.messageContext, myInsightsNavigationChannel, {
            recordTypeSelector: {
                object: object,
                fields: fields
            }
        });
    }

    navigateUsingLightning(url) {
        publish(this.messageContext, myInsightsNavigationChannel, {
            urlInfo: {
                url: url
            }
        });
    }

    async newRecordRequest(object, fields) {
        const request = await this.veevaDataService.initVodRequest();
        request.url += `/api/v1/smart-linking/new-record/${object}`;
        request.body = JSON.stringify(fields);
        request.method = "POST";
        return request;
    }
}