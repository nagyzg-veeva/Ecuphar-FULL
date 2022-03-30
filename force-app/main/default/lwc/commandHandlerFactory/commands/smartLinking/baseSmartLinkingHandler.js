import CommandError from "c/commandError";

export default class BaseSmartLinkingHandler {
    async handle() {
        return null;
    }

    throwCommandError(message) {
        const errorData = { custom: true, message: message };
        throw new CommandError(errorData, this.constructor.name);
    }
}