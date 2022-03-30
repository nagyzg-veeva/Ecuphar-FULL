import CommandHandler from "./commandHandler"

export default class ObjectMetadataCommand extends CommandHandler {

    async response(queryConfig) {
        const object = queryConfig.object;
        const objectInfo = await this.objectInfo(object);
        const objectMetadata = this.getObjectMetadata(object, objectInfo);
        return this.formatResponse(objectMetadata);
    }

    getObjectMetadata(object, objectInfo) {
        const objectMetadata = {
            object: object,
            fields: []
        };
        Object.keys(objectInfo.fields).forEach(fieldName => {
            const field = objectInfo.fields[fieldName];
            objectMetadata.fields.push({
                name: fieldName,
                dataType: field.dataType.toLowerCase()
            });
        });
        return objectMetadata;
    }

    formatResponse(objectMetadata) {
        const formattedResponse = {
            success: true,
            data: objectMetadata,
        }
        return formattedResponse;
    }
}