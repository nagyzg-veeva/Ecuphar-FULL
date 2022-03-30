import CommandHandler from "./commandHandler"

export default class FieldLabelsCommand extends CommandHandler {

    async response(queryConfig) {
        const object = queryConfig.object;
        const fields = queryConfig.fields;
        const objectInfoData = await this.objectInfo(object);
        const objectFieldMap = objectInfoData.fields;
        return this.formatResponse(object, fields, objectFieldMap);
    }

    formatResponse(object, fields, objectFieldMap) {
        const response = {};
        const fieldLabelMap = {};
        fields.filter(field => field in objectFieldMap)
            .forEach(field => {
                fieldLabelMap[field] = objectFieldMap[field].label
            });
            response[object] = fieldLabelMap;
        return response;
    }
}