import LookupDataReferenceController from 'c/lookupDataReferenceController';
import GROUP from '@salesforce/schema/Group';
import NAME from '@salesforce/schema/Group.Name';

export default class GroupNameReferenceController extends LookupDataReferenceController {
    
    get targetSObject() {
        return GROUP.objectApiName;
    }

    /*
        The object using GroupNameReferenceController is EM_Event_Team_Member_vod__c
        Subbing objectApiName for Group in order to invoke lookup service with Group filtering
    */
    get objectApiName() {
        return GROUP.objectApiName;
    }

    getQueryParams(term) {
        return {
            q: term,
            field: NAME.fieldApiName,
            refTo: this.targetSObject,
            id: this.id,
            recordType: this.recordTypeId,
            sobject: this.objectApiName
        };
    }

    toSearchRecord(record) {
        let searchRecord = super.toSearchRecord(record);
        searchRecord.id = record.DeveloperName;
        return searchRecord;
    }

    async getColumns() {
        if (!this._columns) {
            this._columns = [];
            this._columns.push({
                label: NAME.fieldApiName,
                fieldName: NAME.fieldApiName,
                type: 'text'
            });
        }
        return this._columns;
    }
}