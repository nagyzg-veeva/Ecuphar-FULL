import VeevaPageReference from "c/veevaPageReference";

export default class EmPageReference extends VeevaPageReference {
    static getCreateDefaults = async (uiAPI, recordTypeId, apiName, fields, pageRef) => {
        let optionalFields = Object.entries(fields).map(
            ([key, value]) => `${apiName}.${value.apiName}`
        );
        const defaults = await uiAPI.getCreateDefaults(apiName, recordTypeId, optionalFields);
        let result = {
            record: JSON.parse(JSON.stringify(defaults.record)),
        };

        await VeevaPageReference.setParentValueAndDisplayName(defaults, pageRef, result, apiName, uiAPI);

        return result;
    }
}