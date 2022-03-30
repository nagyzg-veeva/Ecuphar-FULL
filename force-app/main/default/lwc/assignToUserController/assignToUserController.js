import ReferenceController from "c/referenceController";
import VeevaConstant from "c/veevaConstant";
import VeevaUtils from "c/veevaUtils";

export default class AssignToUserController extends ReferenceController {
    async search(term) {
        let searchQueryParams = {
            q: term,
            field: this.field.apiName,
            refTo: this.targetSObject,
            id: this.id,
            recordType: this.recordTypeId,
            sobject: this.objectApiName,
            mifAccountId: this.data.value("Account_vod__c").value
        };
        let response = await this.pageCtrl.dataSvc.lookupSearch(this.objectApiName, searchQueryParams);
        response.records = response.payload.map(record => this.toSearchRecord(record));
        response.count = response.records.length;
        return response;
    }

    toSearchRecord(record) {
        let result = { id: record.Id, apiName: record.type, icon: VeevaUtils.getIcon(record.type) };
        VeevaConstant.SEARCH_COLUMNS.forEach(key => {
            if (record[key]) {
                result[key] = record[key];
            }
        });
        result.name = result.Name || '';
        return result;
    }
}