import getMedEventAttendees from '@salesforce/apex/MedEventAttendee.getMedEventAttendees';
import VeevaUtils from 'c/veevaUtils';
import VeevaLayoutService from 'c/veevaLayoutService';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

export default class MedEventAccountSelectorCtrl {

    constructor(userInterface, messageSvc) {
        this.uiApi = userInterface;
        this.messageSvc = messageSvc;
    }

    async getColumns() {
        if (!this.columns) {
            let searchLayoutResponse = await this.uiApi.searchLayout(ACCOUNT_OBJECT.objectApiName);
            this.columns = VeevaLayoutService.toSearchLayoutColumns(searchLayoutResponse, this.objectInfo, ACCOUNT_OBJECT.objectApiName);
        }
        return this.columns;
    }

    async getRecordsWithColumns(columns, id) {
        let records = [];
        const accountIds = await getMedEventAttendees({ medEventId: id });
        if (accountIds && accountIds.length > 0) {
            let batchRecords = await this.uiApi.getBatchRecords(accountIds, columns);
            if (batchRecords) {
                records = batchRecords.reduce((searchRecords, batchRecord) => {
                    if (batchRecord.id) {
                        searchRecords.push(this.toSearchRecord(batchRecord));
                    }
                    return searchRecords;
                }, []);
            }
        }
        return records;
    }

    toSearchRecord(record) {
        let result = { id: record.id, apiName: record.apiName, icon: VeevaUtils.getIcon(record.apiName) };
        Object.entries(record.fields).forEach(([fldName, valueObj]) => {
            result[fldName] = valueObj.displayValue || valueObj.value;
        });
        result.name = result.Name || '';
        return result;
    }
}