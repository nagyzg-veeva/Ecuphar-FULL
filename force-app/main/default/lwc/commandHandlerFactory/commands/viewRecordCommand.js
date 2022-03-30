import CommandHandler from "./commandHandler";
import CommandError from "c/commandError";
import { createMessageContext, publish } from "lightning/messageService";
import myInsightsNavigationChannel from "@salesforce/messageChannel/MyInsights_Navigation__c";

export default class ViewRecordCommand extends CommandHandler {

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
            const updateRecordRequest = await this.updateRecordRequest(object, fields);
            await this.navigateToViewRecord(updateRecordRequest, object, fields);
        }
    }

    async navigateToViewRecord(updateRecordRequest, object, fields) {
        try {
            // The request to CRM will determine if we support this object
            const response = await this.veevaDataService.request(updateRecordRequest);
            if (response.data.success && response.data.url) {
                // Once we know that this object is supported we will go ahead and navigate
                this.navigateUsingLightning(object, fields);
            } else {
                this.throwCommandError(response.data.errorMessage);
            }
        } catch (e) {
            let message = e.message;
            if (e instanceof CommandError) {
                message = e.errorData.message;
            }
            this.throwCommandError("Could not navigate to view record - " + message);
        }
    }

    navigateUsingLightning(object, fields) {
        if (object && fields && fields.Id) {
            publish(this.messageContext, myInsightsNavigationChannel, {
                viewRecord: {
                    object: object,
                    recordId: fields.Id
                }
            });
        } else {
            this.throwCommandError(`Expected object name and id of record to view. Instead received object: ${object} and fields.Id: ${fields.Id}`);
        }
    }

    async updateRecordRequest(object, fields) {
        const request = await this.veevaDataService.initVodRequest();
        request.url += `/api/v1/smart-linking/view-record/${object}`;
        request.body = JSON.stringify(fields);
        request.method = "POST";
        return request;
    }
}