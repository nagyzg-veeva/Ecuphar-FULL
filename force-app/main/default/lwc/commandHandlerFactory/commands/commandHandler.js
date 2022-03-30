import CommandError from "c/commandError";
export default class CommandHandler {
    veevaUserInterfaceApi;
    constructor(veevaUserInterfaceApi) {
        this.veevaUserInterfaceApi = veevaUserInterfaceApi;
    }

    async response(queryConfig) {
        throw new Error("Abstract Command not yet implemented", queryConfig);
    }

    async objectInfo(object) {
        const objectInfo = await this._getObjectInfo(object);
        if (!objectInfo || objectInfo.length === 0) {
            this.throwCommandError(`Could not retrieve information for object ${object}`);
        }
        return objectInfo;
    }

    async _getObjectInfo(object) {
        let objectInfo = await this.veevaUserInterfaceApi.objectInfo(object);
        if (!objectInfo || objectInfo.length === 0) {
            // Some objects such as Territory2 are not accessible from the UI-API
            if (object) {
                objectInfo = await this.getObjectInfoFromRestAPI(object);
            }
        }
        return objectInfo;
    }

    throwCommandError(message) {
        const errorData = { message: message };
        throw new CommandError(errorData, this.constructor.name);
    }

    async getRecordTypes(objectName) {
        const objectInfo = await this.objectInfo(objectName);
        const recordTypeInfos = Object.values(objectInfo.recordTypeInfos);
        return recordTypeInfos;
    }

    async getObjectInfoFromRestAPI(objectName) {
        const objectNameEncoded = encodeURIComponent(objectName);
        const url = `/sobjects/${objectNameEncoded}/describe`;
        let objectMetadata;
        try {
            const response = await this.veevaUserInterfaceApi.performRequest(`sobject-describe-${objectName}`, url);
            if (response.success) {
                objectMetadata = {
                    apiName: objectName,
                    ...response.data
                };
                objectMetadata.fields = this._formatFieldsSimilarToUiAPI(objectMetadata.fields);
            } else {
                console.warn(`Could not retrieve object info for ${objectName}`, response.error);
                objectMetadata = null;
            }
        } catch (e) {
            objectMetadata = null;
        }
        if (!objectMetadata) {
            this.throwCommandError(`Could not retrieve information for object ${objectName}`);
        }
        return objectMetadata;
    }

    _formatFieldsSimilarToUiAPI(fields) {
        const fieldMap = {};
        if (fields) {
            fields.forEach(field => {
                fieldMap[field.name] = {
                    apiName: field.name,
                    dataType: field.type,
                    ...field
                }
            });
        }
        return fieldMap;
    }
}