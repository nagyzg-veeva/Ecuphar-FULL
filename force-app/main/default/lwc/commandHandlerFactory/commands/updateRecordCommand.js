import CommandHandler from "./commandHandler";
import CommandError from "c/commandError";
import { updateRecord } from "lightning/uiRecordApi";

export default class UpdateRecordCommand extends CommandHandler {
    async response(config) {
        const { id, fields } = config;
        const recordResult = await this.updateRecord(id, fields);
        return this.formatResponse(recordResult);
    }

    /**
     * Updates a record using an Id
     * @param {String} apiName 
     * @param {Map} fields 
     * @returns {Object} object with property id that matches the record that was update
     * @throws {CommandError}
     */
    // eslint-disable-next-line consistent-return
    async updateRecord(id, fields) {
        try {
            const fieldsForUpdate = {
                Id: id,
                ...fields
            };
            const result = await updateRecord({ fields: fieldsForUpdate });
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
        const errMsg = (e.body && e.body.message) ? e.body.message : "Could not update record";
        const errorData = {
            errors: e.message ? e.message : e,
            message: errMsg
        };
        return errorData;
    }
}