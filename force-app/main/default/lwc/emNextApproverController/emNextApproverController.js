import MultiObjectReferenceController from 'c/multiObjectReferenceController';
import LookupDataService from 'c/lookupDataService';
import VeevaUtils from 'c/veevaUtils';
import VeevaConstant from 'c/veevaConstant';
import EmEventConstant from 'c/emEventConstant';
import EM_EVENT from '@salesforce/schema/EM_Event_vod__c';

export default class EmNextApproverController extends MultiObjectReferenceController {

    constructor(meta, pageCtrl, model) {
        super(EM_EVENT.objectApiName, meta, pageCtrl, {}, pageCtrl.record);
        this.model = model;
        this.lookupDataSvc = new LookupDataService(pageCtrl.dataSvc);
    }

    get selected() {
        let ret = super.selected;
        if ((ret && !ret.id) && this._selected) {
            ret = this._selected;
        }
        return ret;
    }

    get nameField() {
        return 'Name';
    }

    setFieldValue(id, detail) {
        this._selected = detail;
        if (id) {
            this.model[EmEventConstant.APPROVER_ID] = id;
        } else {
            delete this.model[EmEventConstant.APPROVER_ID];
        }
    }

    async search(term) {
        if (!term) {
            return {};
        }

        let queryParams = {
            field: this.selectedObject.field || '', 
            q: term, 
            refTo: this.selectedObject.value || '', 
        };
        let response = await this.lookupDataSvc.search(this.objectType, queryParams);
        response.records = response.payload.map(record => this.toSearchRecord(record));
        response.count = response.records.length;
        return response;
    }

    toSearchRecord(record) {
        let result = { id: record.Id, apiName: record.type, icon: VeevaUtils.getIcon(record.type)};
        VeevaConstant.SEARCH_COLUMNS.forEach(key => {
            if (record[key]) {
                result[key] = record[key];
            }
        });
        result.name = result.Name || '';
        return result;
    }
}