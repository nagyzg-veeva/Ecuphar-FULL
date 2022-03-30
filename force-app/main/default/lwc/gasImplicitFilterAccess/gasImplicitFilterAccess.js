import LOCATION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Location_vod__c';
import APPLIES_TO_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Applies_To_vod__c';
import INCLUSION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Inclusion_vod__c';

export default class GasImplicitFilterAccess {    

    static gasImplicitFilterReqdFields = [LOCATION_FIELD, APPLIES_TO_FIELD, INCLUSION_FIELD];

    static hasImplicitFilterAccess(implicitFilterObjectInfo, implicitFilterConditionObjectInfo){
        return implicitFilterObjectInfo.createable && implicitFilterConditionObjectInfo.createable
            && implicitFilterObjectInfo.updateable && implicitFilterConditionObjectInfo.updateable
            && implicitFilterObjectInfo.deletable && implicitFilterConditionObjectInfo.deletable
            && this.gasImplicitFilterReqdFields.every(field => implicitFilterObjectInfo.fields[field.fieldApiName]?.createable);
    }
}