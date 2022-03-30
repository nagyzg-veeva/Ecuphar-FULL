import ReferenceController from 'c/referenceController';
import LookupDataService from 'c/lookupDataService';
import VeevaUtils from 'c/veevaUtils';

export default class LookupDataReferenceController extends ReferenceController {
    
    constructor(item, pageCtrl, field, record) {
        super(item, pageCtrl, field, record);
        this.lookupDataSvc = new LookupDataService(pageCtrl.dataSvc);
    }

    getQueryParams(term) {
        return {
            q: term,
            field: this.field.apiName,
            refTo: this.targetSObject,
            id: this.id,
            recordType: this.recordTypeId,
            sobject: this.objectApiName
        };
    }

    async search(term) {
        if (!term) {
            return {};
        }

        let queryParams = this.getQueryParams(term);
        let response = {};
        try {
            response = await this.lookupDataSvc.search(this.objectApiName, queryParams);
            this._columns = response.metadata.map(column => this.toSearchColumn(column));
            response.records = response.payload.map(record => this.toSearchRecord(record));
            response.count = response.records.length;
        } finally {
            return response;
        }
    }

    toSearchRecord(record) {
        let result = { id: record.Id, apiName: record.type, icon: VeevaUtils.getIcon(record.type)};
        result.name = record.Name || '';
        if (this._columns) {
            this._columns.forEach(column => {
                result[column.fieldName] = record[column.fieldName];
            });
        }
        return result;
    }

    toSearchColumn(column) {
        return {
            label: column.label,
            fieldName: column.name,
            type: this.getColumnType(column),
            ... (column.name === 'Name') && { typeAttributes: { id: { fieldName: 'id' } } },
        }
    }

    getColumnType(column) {
        let type = 'text';
        if (column.name === 'Name') {
            type = 'nameLink';
        } else if (column.checkbox) {
            type = 'boolean';
        }
        return type;
    }
}