import CommandHandler from "./commandHandler"

export default class SessionCommand extends CommandHandler {

    veevaSessionService;
    constructor(veevaUserInterfaceApi, veevaSessionService) {
        super(veevaUserInterfaceApi);
        this.veevaSessionService = veevaSessionService;
    }

    async response() {
        try {
            const { sfSession, sfEndpoint, isSandbox } = await this.veevaSessionService.getVodInfo();
            return this.formatResponse(sfSession, sfEndpoint, isSandbox);
        } catch (err) {
            return this.formatErrorResponse(err);
        }
    }

    formatResponse(sfSession, sfEndpoint, isSandbox) {
        return {
            success: true,
            data: {
                sessionId: sfSession,
                instanceUrl: sfEndpoint,
                isSandbox: isSandbox === "true"
            }
        };
    }

    formatErrorResponse() {
        return {
            success: false,
            message: "Could not retrieve session information",
            code: 52
        };
    }
}