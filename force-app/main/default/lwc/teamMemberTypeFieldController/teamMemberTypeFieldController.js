import PicklistController from 'c/picklistController';
import teamMemberTypeFieldTemplate from './teamMemberTypeField.html';
import TEAM_MEMBER from '@salesforce/schema/EM_Event_Team_Member_vod__c.Team_Member_vod__c';
import GROUP_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Group_Name_vod__c';
import FIRST_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.First_Name_vod__c';
import LAST_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Last_Name_vod__c';

const USER_VOD = 'User_vod';
const GROUP_VOD = 'Group_vod';
const WRITE_IN_VOD = 'Write_In_vod';

export default class TeamMemberTypeFieldController extends PicklistController {

    teamMemberMeta = {};
    groupNameMeta = {};
    firstNameMeta = {};
    lastNameMeta = {};

    constructor(meta, pageCtrl, field, record) {
        super(meta, pageCtrl, field, record);
        this.required = pageCtrl.action !== 'View';
        this.teamMemberMeta = this.getFieldMeta(TEAM_MEMBER.fieldApiName);
        this.groupNameMeta = this.getFieldMeta(GROUP_NAME.fieldApiName);
        this.firstNameMeta = this.getFieldMeta(FIRST_NAME.fieldApiName);
        this.lastNameMeta = this.getFieldMeta(LAST_NAME.fieldApiName);
    }

    getFieldMeta(fieldApiName) {
        let meta = {};
        if (this.pageCtrl.isFieldOnLayout(fieldApiName)) {
            meta = this.pageCtrl.layoutFields[fieldApiName];
        }
        return meta;
    }

    initTemplate() {
        this.template = teamMemberTypeFieldTemplate;
        return super.initTemplate();
    }

    async options() {
        let picklistValues = await super.options();
        let availableValues = [];
        for (let picklistValue of picklistValues.values) {
            let isFieldOnLayout = false;
            switch (picklistValue.value) {
                case USER_VOD:
                    isFieldOnLayout = this.pageCtrl.isFieldOnLayout(TEAM_MEMBER.fieldApiName);
                    break;
                case GROUP_VOD:
                    isFieldOnLayout = this.pageCtrl.isFieldOnLayout(GROUP_NAME.fieldApiName);
                    break;
                case WRITE_IN_VOD:
                    isFieldOnLayout = this.pageCtrl.isFieldOnLayout(FIRST_NAME.fieldApiName) && this.pageCtrl.isFieldOnLayout(LAST_NAME.fieldApiName);
                    break;
            }
            if (isFieldOnLayout) {
                availableValues.push(picklistValue);
            }
        }
        picklistValues.values = availableValues;
        return picklistValues;
    }

    clearFields() {
        //clear fields
        const fields = [TEAM_MEMBER.fieldApiName, GROUP_NAME.fieldApiName, FIRST_NAME.fieldApiName, LAST_NAME.fieldApiName];
        fields.forEach(field => {
            const fieldInfo = this.pageCtrl.objectInfo.getFieldInfo(field) || field;
            this.pageCtrl.setFieldValue(fieldInfo, null);
        });
    }
}