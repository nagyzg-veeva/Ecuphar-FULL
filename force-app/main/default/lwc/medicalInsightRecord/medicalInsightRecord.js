import VeevaRecord from 'c/veevaRecord';

export default class MedicalInsightRecord extends VeevaRecord {

    get isLocked() {
        if (this.fields.Status_vod__c) {
            return this.rawValue('Status_vod__c') === 'Submitted_vod';
        }
        return false;
    }
}