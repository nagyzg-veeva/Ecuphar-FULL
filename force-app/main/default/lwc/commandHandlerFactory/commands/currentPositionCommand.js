import CommandHandler from "./commandHandler";

export default class CurrentPositionCommand extends CommandHandler {
    async response() {
        return new Promise(resolve => {
            if (window.navigator && window.navigator.geolocation) {
                window.navigator.geolocation.getCurrentPosition(
                    position => this.successCallback(resolve, position),
                    err => this.errorCallback(resolve, err)
                );
            } else {
                this.errorCallback(resolve, {});
            }
        });
    }

    successCallback(resolve, position) {
        let coordinates = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy
        };
        resolve({
            success: true,
            coordinates: coordinates,
            timestamp: position.timestamp
        });
    }

    errorCallback(resolve, error) {
        let message = "Request Failed";
        let code = 0;
        if (error.code === 1) {
            message = "No Access Granted";
            code = 61;
        } else if (error.code === 2) {
            message = "Location Unavailable";
            code = 62;
        }

        resolve({
            success: false,
            message: message,
            code: code
        });
    }
}