import getVeevaMessages from "@salesforce/apex/VeevaMessageController.getVeevaMessages";

const INIT_CATEGORIES = ['Common', 'Lightning'];

export default class VeevaMessageService {
    _messageMap;
    _loadedCategories;
    _msgPromise;
    
    constructor() {
        this._messageMap = {};
        this._loadedCategories = {};
        this._filterAndLoad(INIT_CATEGORIES);
    }

    async loadVeevaMessageCategories(categories) {
        await this._msgPromise;
        this._filterAndLoad(categories);
    }

    async getMessageWithDefault(key, category, defaultMessage) {
        const msgKey = `${category};;${key}`;
        let message = this._messageMap[msgKey];
        if (!message) {
            await this.loadVeevaMessageCategories([category]);
            await this._msgPromise;
            message = this._messageMap[msgKey];
        }
        return message || defaultMessage;
    }

    _filterAndLoad(categories) {
        const uncached = categories.filter(cat => !this._loadedCategories[cat]).sort();
        if (uncached.length > 0) {
            uncached.forEach(cat => {this._loadedCategories[cat] = true;});
            this._msgPromise = this._loadAndMapMessages(uncached);
        }
    }

    async _loadAndMapMessages(categories) {
        const msgData = await getVeevaMessages({"categories": categories});
        Object.assign(this._messageMap, msgData);
        if (msgData) {
            Object.keys(msgData).forEach(msgKey => {
                const msgCat = msgKey.split(';;')[0];
                this._loadedCategories[msgCat] = true;
            });
        }
    }
}