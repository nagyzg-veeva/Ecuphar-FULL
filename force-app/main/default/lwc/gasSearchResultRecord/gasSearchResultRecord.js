export default class GasSearchResultRecord {
    constructor(searchAccountResult) {
        Object.entries(searchAccountResult)
            .forEach(([key, value]) => {
                this[key] = value
            });
    }

    get ['Account.link']() {
        const accountId = this['Account.Id'];
        return `/${accountId}`;
    }
}