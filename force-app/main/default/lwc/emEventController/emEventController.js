import EmController from "c/emController";
import EmEventConstant from "c/emEventConstant";
import EmEventRecord from "c/emEventRecord";
import { fireEvent } from 'c/pubsub';

export default class EmEventController extends EmController {

    constructor(dataSvc, userInterface, messageSvc, emPageLayoutEngineSvc, eventActionSvc) {
        super(dataSvc, userInterface, messageSvc, emPageLayoutEngineSvc);
        this.eventActionSvc = eventActionSvc;
    }

    toVeevaRecord(value) {
        return value instanceof EmEventRecord ? value : new EmEventRecord(value);
    }
    
    initTemplate(ctrl) {
        switch (ctrl.fieldApiName) {
            // Render as text, not checkbox
            case EmEventConstant.ZVOD_EVENT_LAYOUT:
                ctrl.veevaText = true;
                return ctrl;
            case EmEventConstant.COUNTRY:
                if (this.record.isNew) {
                    ctrl.editable = false;                
                }
                return super.initTemplate(ctrl);
            case EmEventConstant.START_TIME:
            case EmEventConstant.END_TIME:
                if (this.record.isNew) {
                    ctrl.editable = true;
                    ctrl.required = true;
                    ctrl.veevaLightningInput = true;
                }
                return super.initTemplate(ctrl);
            default:
                return super.initTemplate(ctrl);
        }
    }

    async getModalButtons() {
        const buttonPromises = [this.createCancelButton()];

        if (this.action === 'New' || this.action === 'Edit') {
            buttonPromises.push(this.createSaveButton());
        }

        return Promise.all(buttonPromises);
    }

    async processLayout(layout) {
        super.processLayout(layout);

        this.processZvodField(layout);
        await this.processCountryField();
        
        return layout;
    }

    async processCountryField() {
        const result = await this.uiApi.getRecord(
            this.record.fields[EmEventConstant.COUNTRY].value,
            ['Country_vod__c.Country_name_vod__c']
        );
        this.record.updateCountryNameLabel(result.fields[EmEventConstant.COUNTRY_NAME].displayValue);
    }

    processZvodField(layout) {
        if(this.objectInfo.fields[EmEventConstant.ZVOD_EVENT_LAYOUT]) {
            this.record.setFieldValue(EmEventConstant.ZVOD_EVENT_LAYOUT, layout.layoutName);
        }
    }

    setCountryField(countryId) {
        if(this.objectInfo.fields[EmEventConstant.COUNTRY]) {
            this.record.setFieldValue(EmEventConstant.COUNTRY, countryId);
        }
    }

    setEventConfigField(eventId) {
        if(this.objectInfo.fields[EmEventConstant.EVENT_CONFIG]) {
            this.record.setFieldValue(EmEventConstant.EVENT_CONFIG, eventId);
        }
    }

    async initRecordCreate(pageRef) {
        await this.initRecordCreateBase(pageRef);
                
        const defVals = pageRef.state.defaultFieldValues && JSON.parse(pageRef.state.defaultFieldValues);
        this.emPageLayoutEngineSvcParams = this.getEmPleParams(defVals);

        this.setCountryField(defVals.CountryId);
        this.setEventConfigField(defVals.Event_Configuration_vod__c);
        
        await this.initPageLayout();
    }

    getEmPleParams({Country_vod__c, Event_Configuration_vod__c, RecordTypeId, Start_Time_vod__c, End_Time_vod__c}) {
        // Country_vod__c is not an Id
        // PLE expects Country_vod__c to hold 2 chars, Ex. 'US' or 'CN'
        return {Country_vod__c, Event_Configuration_vod__c, RecordTypeId, Start_Time_vod__c, End_Time_vod__c};
    }

    displayEventActionDialog(buttonName, eventAction) {
        //check event action and determine if we should show a dialog
        let actionType = eventAction.SFDC_Action_Type_vod__c;
        return (buttonName === 'Reschedule_vod') ||
            ((!actionType && buttonName === 'Submit_for_Approval_vod') || actionType === 'Submit_Manual_vod') ||
            (eventAction.Allow_Comments_vod__c) ||
            (eventAction.Confirmation_Message_vod__c);
    }

    async toButtonCtrl(btn) {
        if (this[btn.name]) {
            return this[btn.name](btn);
        }
        return this.eventAction(btn);
    }

    async handleEventActionResult(eventActionId, data) {
        let response = { success: true };
        try {
            await this.eventActionSvc.statusChange(this.id, eventActionId, data);
            this.processForLDSCache({ Id: this.id });
        } catch (error) {
            response.success = false;
            switch (error.message) {
                case "REQUIRED_FIELD_MISSING":
                    response.showApproverWarning = true;
                    break;
                case "NO_APPLICABLE_PROCESS":
                    response.message = error.errors.NO_APPLICABLE_PROCESS.errorMessage;
                    break;
                default:
                    response.message = error.message;
            }
        }
        return response;
    }

    async eventAction(btn) {
        let response = await this.eventActionSvc.getEventAction(this.id, btn.name);
        let eventAction = response.data[0];

        let dialogMeta = { eventAction: eventAction, button: btn, ctrl: this };
        if (this.displayEventActionDialog(btn.name, eventAction)) {
            fireEvent(this, EmEventConstant.DISPLAY_EVENT_ACTION_DIALOG, dialogMeta);
        } else {
            this.handleEventActionResult(eventAction.Id, {});
        }
    }
}