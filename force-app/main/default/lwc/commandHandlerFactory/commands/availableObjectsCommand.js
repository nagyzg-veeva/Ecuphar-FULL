import CommandHandler from "./commandHandler"

export default class AvailableObjectsCommand extends CommandHandler {

    async response() {
        return {
            data: await this.availableObjects()
        };
    }

    // eslint-disable-next-line consistent-return
    async availableObjects() {
        try {
            const describeGlobalResponse = await this.veevaUserInterfaceApi.performRequest("describeGlobal", "/sobjects");
            let sobjects;
            if (describeGlobalResponse.success) {
                sobjects = describeGlobalResponse.data.sobjects;
            } else {
                console.warn("Could not retrieve available objects", describeGlobalResponse.error);
                sobjects = [];
            }
            const availableObjects = {};
            sobjects.forEach(sobject => {
                availableObjects[sobject.name] = {};
            })
            return availableObjects;
        } catch (e) {
            this.throwCommandError("No Available Objects.");
        }
    }
}