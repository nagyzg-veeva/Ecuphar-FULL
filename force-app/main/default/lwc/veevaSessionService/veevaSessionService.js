import getVodInfo from "@salesforce/apex/SessionVod.getVodInfo";

export default class VeevaSessionService {
    constructor() {
        this.initialize();
    }

    initialize() {
        this.promise = getVodInfo().then(data => { this._vodInfo = data; });
    }

    async getVodInfo() {
        if (!this._vodInfo) {
            await this.promise;
        }
        return this._vodInfo;
    }
}