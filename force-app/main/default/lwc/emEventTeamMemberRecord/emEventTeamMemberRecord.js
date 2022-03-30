import VeevaRecord from "c/veevaRecord";
import GROUP_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Group_Name_vod__c';
import getTeamMemberGroupLabel from '@salesforce/apex/EmEventController.getTeamMemberGroupLabel';

export default class EmEventTeamMemberRecord extends VeevaRecord {
    
    groupNameLabel;

    constructor(value) {
        super(value);
        this.initGroupNameLabel(); //init group name label ahead of time
    }

    async initGroupNameLabel() {
        let groupDevName = this.rawValue(GROUP_NAME.fieldApiName);
        if (groupDevName) {
            this.groupNameLabel = await getTeamMemberGroupLabel({ groupDevName: groupDevName });
        }
    }

    displayValue(field) {
        let displayVal = super.displayValue(field);
        if (field === GROUP_NAME.fieldApiName || field.apiName === GROUP_NAME.fieldApiName) {
            displayVal = this.groupNameLabel;
        }
        
        return displayVal;
    }

    reference(field) {
        let ref = super.reference(field);
        if (field === GROUP_NAME.fieldApiName || field.apiName === GROUP_NAME.fieldApiName) {
            ref.name = this.groupNameLabel;
        }
        return ref;
    }

    updateReferenceField(field, reference) {
        if ((field === GROUP_NAME.fieldApiName || field.apiName === GROUP_NAME.fieldApiName) && reference?.name) {
            this.groupNameLabel = reference.name;
        }
        super.updateReferenceField(field, reference);
    }

}