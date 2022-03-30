import getInfo from '@salesforce/apex/VeevaUserInterfaceAPI.getInfo';
import getData from '@salesforce/apex/VeevaUserInterfaceAPI.getData';
import VeevaUtils from 'c/veevaUtils';
import VeevaLayoutService from 'c/veevaLayoutService';

// https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_get_started.htm
export default class VeevaUserInterfaceAPI {
    constructor(sessionService, requests) {
        this.sessionService = sessionService;
        this.requests = requests;
    }

    async getPicklistValues(recordTypeId, sobject, field) {
        const url = `/ui-api/object-info/${sobject}/picklist-values/${recordTypeId}/${field}`;
        const response = await this.performRequest('getPicklistValues', url);
        if (response.error) {
            console.warn(`Could not retrieve picklist values for ${sobject}.${field} (RecordTypeId: ${recordTypeId})`, response.error);
            return {};
        }
        return response.data;
    }

    async getBatchRecords(ids, fields) {
        const idsStr = ids.join(',');
        const url = `/ui-api/records/batch/${idsStr}?fields=${fields}`;
        const response = await this.performRequest('getBatchRecords', url, true);
        if (response.error) {
            console.warn(`Could not retrieve batch records for [${idsStr}] for fields ${fields}`, response.error);
            return [];
        }
        const results = response.data.results;
        return results.map(x => x.result);
    }

    async getCreateDefaults(sobject, recordTypeId, optionalFields = null) {
        let url = `/ui-api/record-defaults/create/${sobject}?`;
        const urlSearchParams = new URLSearchParams();
        if (recordTypeId) {
            urlSearchParams.append('recordTypeId', recordTypeId);
        }
        if (optionalFields) {
            const fields = optionalFields.join(',');
            urlSearchParams.append('optionalFields', fields);
        }
        url += urlSearchParams.toString();
        const response = await this.performRequest('getCreateDefaults', url);
        if (response.error) {
            console.warn(`Could not get create defaults for ${sobject} (RecordTypeId: ${recordTypeId})`, response.error);
            return {};
        }
        return response.data;
    }

    async getDescribeButtons(sobject, recordTypeId) {
        let buttons = [];
        const url = `/sobjects/${sobject}/describe/layouts/${recordTypeId || ''}`;
        const response = await this.performRequest('describeButtons', url);
        if (response.error) {
            console.warn(`Could not describe buttons for ${sobject} (RecordTypeId: ${recordTypeId})`, response.error);
            return [];
        }

        const layoutRes = response.data;
        if (layoutRes.buttonLayoutSection) {
            buttons = layoutRes.buttonLayoutSection.detailButtons;
        }
        return buttons;
    }

    async search(sobject, field, target, term, dependents, nextPageUrl) {
        let url = `/ui-api/lookups/${sobject}/${field}/${target}`;
        if (!nextPageUrl){
            if (VeevaUtils.isValidSearchTerm(term)) {
                const param = encodeURIComponent(term.trim());
                url += `?searchType=Search&q=${param}`;
            }
            else {
                url += '?searchType=Recent';
            }
            if (dependents) {
                const str = Object.entries(dependents).map(([key, value]) => `${key}=${encodeURIComponent(value)}`).join(',');
                if (str) {
                    url += `&dependentFieldBindings=${str}`;
                }
            }
            url += '&pageSize=50';
        } else{
            const [, nextPageParams] = nextPageUrl.split('?')
            url += '?' + nextPageParams;
        }
        const response = await this.performRequest('search', url);
        if (response.error) {
            console.warn(`Could not search ${sobject} for ${field} with target of ${target}`, response.error);
            return null;
        }
        return response.data;
    }

    async searchLayout(sobject) {
        const response = await this.searchLayouts([sobject]);
        return (response && response.length > 0) ? response[0] : null;
    }

    async searchLayouts(sobjects) {
        const url = `/search/layout?q=${sobjects}`;
        const response = await this.performRequest('searchLayout', url);
        if (response.error) {
            console.warn(`Could not search layouts for ${sobjects}`, response.error);
            return null;
        }
        return response.data;
    }

    async objectInfoDirectory() {
        const url = '/ui-api/object-info';
        const response = await this.performRequest('objectInfoDirectory', url) || {};
        if (response.error) {
            console.warn(`Could not get object info directory`, response.error);
            return {};
        }
        return response.data;
    }

    async objectInfo(sobject) {
        const url = `/ui-api/object-info/${sobject}`;
        const response = await this.performRequest('objectInfo', url) || {};
        if (response.error) {
            console.warn(`Could not get object info`, response.error);
            return [];
        }
        return response.data;
    }

    async getRecord(id, optionalFields) {
        const fields = optionalFields.join(',');
        const url = `/ui-api/records/${id}?optionalFields=${fields}`;
        const response = await this.performRequest('objectInfo', url);
        if (response.error) {
            console.warn(`Could not get record with id ${id} with fields ${optionalFields}`, response.error);
            return [];
        }
        return response.data;
    }

    async getPageLayout(apiName, action, recordTypeId, recordId) {
        const layoutUrl = `/ui-api/layout/${apiName}?mode=${action}&recordTypeId=${recordTypeId}`;
        const layoutPromise = this.performRequest('getRecordLayout', layoutUrl);
        const buttonUrl = `/ui-api/actions/record/${recordId}?actionTypes=StandardButton,CustomButton`;
        const buttonPromise = this.performRequest('getRecordActions', buttonUrl);

        const [layoutResponse, buttonsResponse] = await Promise.all([layoutPromise, buttonPromise]);
        if (layoutResponse.error) {
            console.warn(`Could not retrieve page layout for ${apiName} (RecordTypeId: ${recordTypeId}) in mode ${action}`, layoutResponse.error);
        }
        if (buttonsResponse.error) {
            console.warn(`Could not retrieve buttons for recordId: ${recordId}`, buttonsResponse.error);
        }

        const layout = VeevaLayoutService.toVeevaLayout(layoutResponse.data, action);
        const buttons = buttonsResponse.success ? buttonsResponse.data : [];
        if (buttons && buttons.actions && buttons.actions[recordId]) {
            layout.buttons = VeevaLayoutService.toButtons(buttons.actions[recordId].actions);
        } else {
            layout.buttons = [];
        }
        return layout;
    }

    async getPageLayoutNoButtons(apiName, action, recordTypeId) {
        const layoutMode = action === 'New' ? 'Create' : action; // layout api doesn't support New, only Create
        const layoutUrl = `/ui-api/layout/${apiName}?mode=${layoutMode}&recordTypeId=${recordTypeId}`;
        const layoutResponse = await this.performRequest('getRecordLayout', layoutUrl);

        if (layoutResponse.error) {
            console.warn(`Could not retrieve page layout for ${apiName} (RecordTypeId: ${recordTypeId}) in mode ${action}`, layoutResponse.error);
        }

        return VeevaLayoutService.toVeevaLayout(layoutResponse.data, action);
    }

    async getCompactLayout(apiName, action, recordTypeId) {
        let layoutUrl = `/ui-api/layout/${apiName}?mode=${action}&layoutType=Compact&recordTypeId=${recordTypeId}`;
        let layout = await this.performRequest('getRecordCompactLayout', layoutUrl);
        return layout;
    }

    async getRelatedLists(apiName, recordTypeId) {
        const relatedListUrl = `/ui-api/related-list-info/${apiName}?recordTypeId=${recordTypeId}`;
        const response = await this.performRequest('getRelatedLists', relatedListUrl);
        if (response.error) {
            console.warn(`Could not get related lists for ${apiName} (RecordTypeId: ${recordTypeId})`, response.error);
            return null;
        }
        return response.data;
    }

    /**
     * @deprecated This method does not provide error information, please use {@link VeevaUserInterfaceAPI.performRequest}
     */
    async request(name, url, data) {
        console.warn(`Using the deprecated ${this.constructor.name}.request method, please use the newer performRequest ${this.constructor.name}.method.`);
        const response = await this.performRequest(name, url, data);
        if (!response.success && response.error) {
            console.warn('Request Error Found');
            console.warn({ name: name, url: url, error: response.error });
            return null;
        }
        return response.data;
    }

    async performRequest(name, url, data) {
        const vodInfo = await this.sessionService.getVodInfo();
        const request = { session: vodInfo.sfSession, url: url };
        this.requests.push(name);
        const result = data ? await getData(request) : await getInfo(request);
        this.requests.splice(this.requests.indexOf(name), 1);
        if (result.data) {
            return {
                success: true,
                data: JSON.parse(result.data)
            }
        }
        else if (result.errorStatus) {
            return {
                success: false,
                error: this.errorFromResult(result)
            };
        }
        return {
            success: false,
            error: {
                errorStatus: 'Error in response or response from VeevaUserInterfaceAPI did not match expected format'
            }
        };
    }

    errorFromResult(result) {
        let message;
        try {
            message = JSON.parse(result.errorData);
        } catch {
            message = result.errorData;
        }
        return {
            errorStatus: result.errorStatus,
            message: message
        }
    }
}