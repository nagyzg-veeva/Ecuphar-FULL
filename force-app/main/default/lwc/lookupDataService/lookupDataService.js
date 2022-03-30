export default class LookupDataService {

    constructor(dataSvc) {
        this.dataSvc = dataSvc;
    }

    async search(object, queryParams) {
        let path = `/api/v1/layout3/lookup/${object}`;
        return this.dataSvc.sendRequest('GET', path, queryParams, null, 'lookupSearch');
    }
}