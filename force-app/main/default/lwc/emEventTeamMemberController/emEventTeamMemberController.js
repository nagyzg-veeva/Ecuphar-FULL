import EmController from 'c/emController';
import TeamMemberTypeFieldController from 'c/teamMemberTypeFieldController';
import LookupDataReferenceController from'c/lookupDataReferenceController';
import GroupNameReferenceController from 'c/groupNameReferenceController';
import EmEventTeamMemberRecord from 'c/emEventTeamMemberRecord';
import NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Name';
import GROUP from '@salesforce/schema/Group';
import TEAM_MEMBER_TYPE from '@salesforce/schema/EM_Event_Team_Member_vod__c.Team_Member_Type_vod__c';
import TEAM_MEMBER from '@salesforce/schema/EM_Event_Team_Member_vod__c.Team_Member_vod__c';
import GROUP_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Group_Name_vod__c';
import FIRST_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.First_Name_vod__c';
import LAST_NAME from '@salesforce/schema/EM_Event_Team_Member_vod__c.Last_Name_vod__c';

const HIDDEN_FIELDS = [TEAM_MEMBER.fieldApiName, GROUP_NAME.fieldApiName, FIRST_NAME.fieldApiName, LAST_NAME.fieldApiName];

export default class EmEventTeamMemberController extends EmController {
    
    toVeevaRecord(value) {
        return value instanceof EmEventTeamMemberRecord ? value : new EmEventTeamMemberRecord(value);
    }

    initItemController(meta, record) {
        let field = meta.field;
        if (field) {
            let fieldDescribe = this.objectInfo.getFieldInfo(field);
            if (field === TEAM_MEMBER_TYPE.fieldApiName) {
                return new TeamMemberTypeFieldController(meta, this, fieldDescribe, record);
            } else if (field === TEAM_MEMBER.fieldApiName) {
                const teamMemberCtrl = new LookupDataReferenceController(meta, this, fieldDescribe, record);
                teamMemberCtrl.required = this.action !== 'View';
                return teamMemberCtrl;
            } else if (field === GROUP_NAME.fieldApiName && this.action !== 'View') {
                fieldDescribe.referenceToInfos = [{ apiName: GROUP.objectApiName, nameFields: [] }];
                const groupNameCtrl = new GroupNameReferenceController(meta, this, fieldDescribe, record);
                groupNameCtrl.required = true;
                return groupNameCtrl;
            } else if (field === FIRST_NAME.fieldApiName || field === LAST_NAME.fieldApiName) {
                const writeInCtrl = super.initItemController(meta, record);
                writeInCtrl.required = this.action !== 'View';
                return writeInCtrl;
            }
        }
        return super.initItemController(meta, record);
    }

    processLayout(layout) {
        layout = super.processLayout(layout);
        if (this.isFieldOnLayout(TEAM_MEMBER_TYPE.fieldApiName) && layout.sections) {
            for (let section of layout.sections) {
                let rows = []
                for (let row of section.layoutRows) {
                    let items = [];
                    for (let item of row.layoutItems) {
                        if ((item.field === NAME.fieldApiName && this.page.action !== 'View') || 
                        (HIDDEN_FIELDS.includes(item.field))) {
                            let hiddenItem = Object.assign({}, item);
                            hiddenItem.label = '';
                            items.push(hiddenItem);
                        } else {
                            items.push(item);
                        }
                    }
                    if (items.length > 0) {
                        row.layoutItems = items;
                        rows.push(row);
                    }
                }
                section.layoutRows = rows;
            }
        }
        return layout;
    }
}