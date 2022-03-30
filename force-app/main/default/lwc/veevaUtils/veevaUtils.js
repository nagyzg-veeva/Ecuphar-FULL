import VeevaConstant from "c/veevaConstant";

export default class VeevaUtils {

    static validSfdcId = (id) => {
        return id && (/[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}/).test(id);
    }

    static getRandomId() {
        return '_' + Math.random().toString(36).substring(2, 15);
    }

    static clone = (obj) => {
        let result = Object.create(Object.getPrototypeOf(obj));
        // copy enumerable properties
        for (const x in obj) {
            if (obj.hasOwnProperty(x)) {
                result[x] = obj[x];
            }
        }
        return result;
    }

    static isEmptyObject = (obj) => {
        if (obj === undefined || obj === null) {
            return true;
        }
        // eslint-disable-next-line guard-for-in
        for (const name in obj) {
            return false;
        }
        return true;
    }

    static hasCJK = (term) => {
        if (term === null) {
            return false;
        }
        if (typeof term !== 'string') {
            return false;
        }
        const chars = term.trim().split('');
        for (let i = 0; i < chars.length; i++) {
            if (/^[\u1100-\u1200\u3040-\uFB00\uFE30-\uFE50\uFF00-\uFFF0]+$/.test(chars[i])) {
                return true;
            }
        }
        return false;
    }

    static isValidSearchTerm = (term) => {
        if (!term) {
            return false;
        }
        const normalizedTerm = term.replace(/[()"?*]+/g, '').trim();
        return normalizedTerm.length >= 2 || VeevaUtils.hasCJK(normalizedTerm);
    }

    static getIcon = (apiName) => {
        return VeevaConstant.OBJECT_ICONS[apiName] || VeevaConstant.DEFAULT_ICON;
    }

    static to = (promise) => {
        return promise.then(data => { return [null, data]; }, err => { return [err]; })
            .catch(err => {
                //console.log(err); 
                return [err];
            });
    }

    static getAvailableRecordTypes = (recordTypeInfos) => {
        let availableTypes = [];

        const convertRecordType = recordTypeInfo => {
            return {
                label: recordTypeInfo.name,
                value: recordTypeInfo.recordTypeId,
                defaultType: recordTypeInfo.defaultRecordTypeMapping,
            };
        }

        availableTypes = Object.values(recordTypeInfos)
            .filter(recordTypeInfo => !recordTypeInfo.master && recordTypeInfo.available)
            .map(convertRecordType)
            .sort(function(type1, type2) {
                if (type1.label && type2.label) {
                    if (type1.label < type2.label) {
                        return -1;
                    }
                    if (type1.label > type2.label) {
                        return 1;
                    }
                }
                return 0;
            });

        if (availableTypes.length === 0) {
            const masterType = Object.values(recordTypeInfos)
                .find(recordTypeInfo => recordTypeInfo.master);
            if (masterType) {
                availableTypes = [convertRecordType(masterType)];
            }
        }

        return availableTypes;
    }
}