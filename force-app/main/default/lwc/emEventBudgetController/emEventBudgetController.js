import EmController from "c/emController";
import LookupDataReferenceController from "c/lookupDataReferenceController";
import BUDGET from '@salesforce/schema/EM_Event_Budget_vod__c.Budget_vod__c';

export default class EmEventBudgetController extends EmController {

    initItemController(meta, record) {
        let field = meta.field;
        if (field === BUDGET.fieldApiName) {
            return new LookupDataReferenceController(this.layoutFields[field], this, this.objectInfo.getFieldInfo(field), record);
        }
        return super.initItemController(meta, record);
    }

}