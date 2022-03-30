import CommandHandler from "./commandHandler";
import getPicklistLabelsByValue from "@salesforce/apex/MyInsightsService.getPicklistLabelsByValue";

export default class PicklistLabelsCommand extends CommandHandler {
    async response(queryConfig) {
        const objectName = queryConfig.object;
        const fieldName = queryConfig.field;
        await this.validateParameters(objectName, fieldName);

        return this.getPicklistValues(objectName, fieldName);
    }

    async validateParameters(objectName, fieldName) {
        if (!objectName) {
            this.throwCommandError("Object was not specified");
        }
        if (!fieldName) {
            this.throwCommandError("Field was not specified");
        }

        const accessToField = await this.hasAccessToField(objectName, fieldName);
        if (!accessToField) {
            this.throwCommandError(`User does not have access to ${fieldName} or field does not exist`);
        }
    }

    async hasAccessToField(objectName, fieldName) {
        const objectInfo = await this.objectInfo(objectName);
        return objectInfo.fields[fieldName] !== undefined;
    }

    async getPicklistValues(objectName, fieldName) {
        let picklistLabelsByValue;
        try {
            picklistLabelsByValue = await getPicklistLabelsByValue({
                objectName: objectName,
                fieldName: fieldName
            });    
        } catch (e) {
            this.throwCommandError(`Failed to retrieve picklist values and labels for ${objectName}.${fieldName} - ${e.body.message}`);
        }
        return this.formatResponse(objectName, fieldName, picklistLabelsByValue);
    }

    formatResponse(objectName, fieldName, picklistValues) {
        let response = {};
        response[objectName] = {};
        response[objectName][fieldName] = {};
        Object.entries(picklistValues).forEach(([value, label]) => {
            response[objectName][fieldName][value] = label;
        });
        return response;
    }
}