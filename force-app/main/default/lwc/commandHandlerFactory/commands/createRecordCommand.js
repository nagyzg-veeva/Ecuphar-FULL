import CommandHandler from "./commandHandler";
import CommandError from "c/commandError";
import { createRecord } from "lightning/uiRecordApi";

export default class CreateRecordCommand extends CommandHandler {
    async response(config) {
        const apiName = config.object;
        const fields = config.fields;
        const recordResult = await this.createRecord(apiName, fields);
        return this.formatResponse(recordResult);
    }

    /**
     * Creates a record of object type 
     * @param {String} apiName 
     * @param {Map} fields 
     * @returns {Object} object with property id that represents the new record's id
     * @throws {CommandError}
     */
    // eslint-disable-next-line consistent-return
    async createRecord(apiName, fields) {
        try {
            const result = await createRecord({ apiName: apiName, fields: fields });
            return result;
        } catch (e) {
            const errorData = this.getErrorDataObj(e);
            throw new CommandError(errorData, this.constructor.name);
        }
    }

    formatResponse(result) {
        return {
            success: true,
            data: { id: result.id }
        };
    }

    getErrorDataObj(e){
        const errMsg = (e.body && e.body.message) ? e.body.message : "Could not create record";
        const errorData = {
            errors: e,
            message: errMsg
        };
        return errorData;
    }
}