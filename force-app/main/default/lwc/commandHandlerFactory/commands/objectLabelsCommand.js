import CommandHandler from "./commandHandler"

export default class ObjectLabelsCommand extends CommandHandler {

    async response(queryConfig) {
        const objects = queryConfig.object;
        const objectInfoPromises = this.retrieveObjectInfoPromises(objects)
        const objectInfos = await Promise.all(objectInfoPromises).catch();
        return this.formatResponse(objects, objectInfos);
    }

    formatResponse(objects, objectInfos) {
        const objectLabelsMap = this.objectLabelsMap(objectInfos);
        const response = {};
        objects
            .filter(object => objectLabelsMap[object])
            .forEach(object => {
                response[object] = [objectLabelsMap[object]];
            });
        return response;
    }

    objectLabelsMap(objectInfos) {
        const objectLabelsMap = {};
        objectInfos.forEach(objectInfo => {
            const objectLabels = {
                singular: objectInfo.label,
                plural: objectInfo.labelPlural
            };
            objectLabelsMap[objectInfo.apiName] = objectLabels;
        });
        return objectLabelsMap;
    }

    retrieveObjectInfoPromises(objects) {
        const objectInfoPromises = [];
        objects.forEach(object => {
            objectInfoPromises.push(this.objectInfo(object));
        });
        return objectInfoPromises;
    }
}