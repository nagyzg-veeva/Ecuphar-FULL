import { LightningElement, api } from 'lwc';

const USER_VOD = 'User_vod';
const GROUP_VOD = 'Group_vod';
const WRITE_IN_VOD = 'Write_In_vod';

export default class DynamicTeamMemberTypeField extends LightningElement {

    @api ctrl;
    @api recordUpdateFlag;
    @api hasBeenUpdated;

    get classUndo() {
        return this.hasBeenUpdated ? 'undo' : '';
    }

    selectedOption;

    get isUser() {
        return this.selectedOption === USER_VOD;
    }

    get isGroup() {
        return this.selectedOption === GROUP_VOD;
    }

    get isWriteIn() {
        return this.selectedOption === WRITE_IN_VOD;
    }

    connectedCallback() {
        this.selectedOption = this.ctrl?.selected;
        this.ctrl?.pageCtrl.track(this.ctrl.fieldApiName, this, "updateSelected");
    }

    updateSelected(value, source) {
        this.ctrl?.clearFields();
        this.selectedOption = value;
    }

    handleFieldChange() {
        const fieldChangeEvent = new CustomEvent("fieldchange");
        this.dispatchEvent(fieldChangeEvent);
    }

    handleUndoClick() {
        const undoClickEvent = new CustomEvent("undoclick");
        this.dispatchEvent(undoClickEvent);
    }

    @api checkValidity() {
        let errors = [...this.template.querySelectorAll('[data-validity]')].filter(item => item.checkValidity() === false);
        return !errors.length;
    }
}