import CommandHandler from "./commandHandler";
import SmartLinkingHandlerFactory from "./smartLinking/smartLinkingHandlerFactory";

export default class SmartLinkingCommand extends CommandHandler {

    constructor(veevaUserInterfaceAPI, veevaDataService, myInsightsPageController, smartLinkingHandlers) {
        super(veevaUserInterfaceAPI);
        if (smartLinkingHandlers) {
            this.smartLinkingHandlers = smartLinkingHandlers;
        } else {
            this.smartLinkingHandlers = SmartLinkingHandlerFactory.handlers(veevaUserInterfaceAPI, veevaDataService, myInsightsPageController);
        }
    }

    async response(commandWithConfig) {
        const configObject = commandWithConfig ? commandWithConfig.configObject : {};
        const { object } = configObject || {};
        if (!object) {
            this.throwCommandError("Require parameters to contain object");
        }
        const handler = this.smartLinkingHandlers[object.toLowerCase()];
        if (!handler) {
            return null;
        }
        const responseFromHandler = await handler.handle(configObject);
        return this.formatResponse(responseFromHandler);
    }

    formatResponse(response) {
        if (response === null) {
            return null;
        }
        return {
            custom: true,
            ...response
        }
    }

}