import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import EmNextApproverController from 'c/emNextApproverController';
import EmEventConstant from 'c/emEventConstant';
import getMsgWithDefault from "@salesforce/apex/VeevaMessageController.getMsgWithDefault";
import EM_EVENT_HISTORY from '@salesforce/schema/EM_Event_History_vod__c';
import START_TIME from '@salesforce/schema/EM_Event_vod__c.Start_Time_vod__c';
import END_TIME from '@salesforce/schema/EM_Event_vod__c.End_Time_vod__c';
import COMMENTS from '@salesforce/schema/EM_Event_History_vod__c.Comment_vod__c';

export default class EventActionDialog extends LightningElement {

    @api objectApiName;
    @api recordId;

    @wire(getObjectInfo, { objectApiName: EM_EVENT_HISTORY })
    eventHistoryDescribe;
    
    @track model = {};
    @track display = false;
    @track warnings = [];
    @track errors = [];

    dialog = {};
    approverCtrl = {};

    RESCHEDULE_START_DATE_TIME = 'startDatetime';
    RESCHEDULE_END_DATE_TIME = 'endDatetime';
    MESSAGES = {
        nextApproverLabel: {
            key: "NEXT_APPROVER",
            category: "EVENT_MANAGEMENT",
            defaultMessage: "Next Approver"
        },
        approverRequired: {
            key: "APPROVER_REQUIRED",
            category: "EVENT_MANAGEMENT",
            defaultMessage: "Please select an approver to continue"
        },
        endTimeError: {
            key: "END_TIME_BEFORE_START_TIME",
            category: "EVENT_MANAGEMENT",
            defaultMessage: "The end time must be later than the start time."
        },
        rescheduleError: {
            key: "RESCHEDULE_ERROR", 
            category: "EVENT_MANAGEMENT",
            defaultMessage: "You cannot reschedule to this date because of the following errors:"
        },
        noEventConfig: {
            key: "NO_EVENT_CONFIG", 
            category: "EVENT_MANAGEMENT",
            defaultMessage: "You are not allowed to schedule this type of event during this time frame. Please contact your administrator."
        },
        rescheduleWarning: {
            key: "RESCHEDULE_WARNING", 
            category: "EVENT_MANAGEMENT",
            defaultMessage: "If you reschedule to this date, please be aware that:"
        },
        budgetWarning: {
            key: "NEW_BUDGET_PERIOD_WARNING", 
            category: "EVENT_MANAGEMENT",
            defaultMessage: "The new event time is in a new budget period. You may have to manually select new budgets."
        },
        rescheduleRelatedEvents: {
            key: "RESCHEDULE_RELATED_EVENTS", 
            category: "EVENT_MANAGEMENT",
            defaultMessage: "Other events in this series will also be rescheduled"
        },
        cancelRelatedEvents: {
            key: "CANCEL_RELATED_EVENTS", 
            category: "EVENT_MANAGEMENT",
            defaultMessage: "All future events in this series will also be canceled"
        }
    };

    connectedCallback() {
        registerListener(EmEventConstant.DISPLAY_EVENT_ACTION_DIALOG, this.displayDialog, this);
        this.getMessages();
    }

    getMessages() {
        for (const [key, messageDetails] of Object.entries(this.MESSAGES)) {
            getMsgWithDefault(messageDetails).then((message) => {
                this[key] = message;
            });
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    async displayDialog(meta) {
        this.dialog = meta;
        this.model.eventActionId = meta.eventAction.Id;
        this.pageCtrl = meta.ctrl;
        
        //reset warnings/errors
        this.showChildWarning = false;
        this.showBudgetWarning = false;
        this.showConfigError = false;
        this.showEndTimeError = false;
        this.showResponseError = false;
        this.showApproverWarning = Boolean(this.dialog.showApproverWarning);
        this.showCancelWarning = this.eventAction.Ending_Status_vod__c === "Canceled_vod" && this.eventAction.hasChildEvents;
        
        if (this.showReschedule) {
            this.model[this.RESCHEDULE_START_DATE_TIME] = this.currentStartTime;
            this.model[this.RESCHEDULE_END_DATE_TIME] = this.currentEndTime;
            this.isDateRangeValid();
        } else if (this.showApproverLookup) {
            this.approverCtrl = this.nextApproverCtrl();
        }
        
        this.display = true;
    }
    
    closeModal() {
        let prevComment = this.model.comment;
        this.model = {};
        if (prevComment) { //keep comment
            this.model.comment = prevComment;
        }
        this.display = false;
    }

    async confirmation() {
        this.model.buttonName = this.buttonName;
        let response = await this.pageCtrl.handleEventActionResult(this.dialog.eventAction.Id, this.model);
        if (response.success) {
            this.model = {};
            this.display = false;
        } else {
            this.responseError = response.message || null;
            this.showResponseError = true;
            this.showApproverWarning = Boolean(response.showApproverWarning);
        }
    }

    updateModel(event) {
        this.model[event.target.name] = event.target.value;
        if (event.target.name === this.RESCHEDULE_START_DATE_TIME || 
            event.target.name === this.RESCHEDULE_END_DATE_TIME) {
            this.isDateRangeValid();
        }
    }

    async isDateRangeValid() {
        let startDateTimeValue = this.model[this.RESCHEDULE_START_DATE_TIME];
        let endDateTimeValue = this.model[this.RESCHEDULE_END_DATE_TIME];

        let startDateTime = new Date(startDateTimeValue);
        let endDateTime = new Date(endDateTimeValue);
        if (startDateTime && endDateTime && startDateTime < endDateTime) {
            this.showEndTimeError = false;

            let response = await this.pageCtrl.eventActionSvc.rescheduleValidation(this.pageCtrl.id, this.model[this.RESCHEDULE_START_DATE_TIME]);
            if (response && response.data && response.data.length == 1) {
                let responseData = response.data[0];
                this.showConfigError = responseData.noConfigError;
                this.showBudgetWarning = responseData.budgetWarning;
                this.showChildWarning = responseData.childRescheduleWarning;
            }
        } else {
            this.showEndTimeError = true;
        }
    }

    nextApproverCtrl() {
        let meta = {
            required: true,
            editable: true,
            label: this.nextApproverLabel,
            objectList: this.eventAction.objectPicklist || []
        };

        return new EmNextApproverController(meta, this.pageCtrl, this.model);
    }

    addOrRemoveAlert(list, key, toAdd) {
        let idx = list.findIndex((alert) => { return alert.key === key; });
        if (idx >= 0 && !toAdd) {
            list.splice(idx, 1);
        } else if (idx < 0 && toAdd && this[key]) {
            let alert = {
                key: key,
                message: this[key]
            };
            list.push(alert);
        }
    }

    get record() {
        let rcrd = {};
        if (this.dialog && this.dialog.hasOwnProperty('ctrl')) {
            rcrd = this.dialog.ctrl.record;
        }
        return rcrd;
    }

    get eventAction() {
        let eventAction = {}
        if (this.dialog && this.dialog.hasOwnProperty('eventAction')) {
            eventAction = this.dialog.eventAction;
        }
        return eventAction;
    }

    get buttonName() {
        let btnName = '';
        if (this.dialog && this.dialog.hasOwnProperty('button')) {
            btnName = this.dialog.button.name;
        }
        return btnName;
    }

    get buttonLabel() {
        let btnLabel = '';
        if (this.dialog && this.dialog.hasOwnProperty('button')) {
            btnLabel = this.dialog.button.label;
        }
        return btnLabel;
    }

    get currentStartTime() {
        return this.record.rawValue(START_TIME.fieldApiName);
    }

    get currentEndTime() {
        return this.record.rawValue(END_TIME.fieldApiName);
    }

    //UI conditionals
    get confirmationMessage() {
        return this.eventAction.Confirmation_Message_vod__c;
    }

    get showReschedule() {
        return this.buttonName === 'Reschedule_vod';
    }

    get startTimeLabel() {
        return this.pageCtrl.objectInfo.getFieldInfo([START_TIME.fieldApiName]).label;
    }

    get endTimeLabel() {
        return this.pageCtrl.objectInfo.getFieldInfo([END_TIME.fieldApiName]).label;
    }

    get showApproverLookup() {
        let actionType = this.eventAction.SFDC_Action_Type_vod__c;
        return (!actionType && this.buttonName === 'Submit_for_Approval_vod') || actionType === 'Submit_Manual_vod';
    }

    get showComments() {
        return this.eventAction.Allow_Comments_vod__c;
    }

    get commentsLabel() {
        return this.eventHistoryDescribe.data.fields[COMMENTS.fieldApiName].label;
    }

    //Warning and Errors
    set showApproverWarning(value) {
        this.addOrRemoveAlert(this.warnings, 'approverRequired', value);
    }

    set showCancelWarning(value) {
        this.addOrRemoveAlert(this.warnings, 'cancelRelatedEvents', value);
    }

    set showChildWarning(value) {
        this.addOrRemoveAlert(this.warnings, 'rescheduleRelatedEvents', value);
    }

    set showBudgetWarning(value) {
        this.addOrRemoveAlert(this.warnings, 'budgetWarning', value);
    }

    set showConfigError(value) {
        this.addOrRemoveAlert(this.errors, 'noEventConfig', value);
    }

    set showEndTimeError(value) {
        this.addOrRemoveAlert(this.errors, 'endTimeError', value);
    }

    set showResponseError(value) {
        this.addOrRemoveAlert(this.errors, 'responseError', value);
    }

    get hasWarnings() {
        return this.warnings.length > 0;
    }

    get hasErrors() {
        return this.errors.length > 0;
    }

    get disableButton() {
        return this.hasErrors || 
            (this.showApproverLookup && !this.model[EmEventConstant.APPROVER_ID]) ||  //empty approver lookup
            this.pageCtrl.page.requests.length > 0;
    }

    //styles
    get rescheduleInputClass() {
        let css = '';
        if (this.hasErrors) {
            css += 'slds-has-error';
        }
        return css;
    }

    get modalContentClass() {
        let css = 'slds-p-around_medium';
        if (this.showReschedule) {
            css += ' reschedule-slot-height';
        }
        return css;
    }
}