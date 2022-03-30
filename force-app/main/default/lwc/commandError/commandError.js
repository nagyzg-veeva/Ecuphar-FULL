export default class CommandError extends Error {
    constructor(errorData, commandName) {
        super(`Error Occurred while handling command ${commandName}`);
        this._errorData = errorData;
    }

    get errorData() {
        return this._errorData;
    }
}