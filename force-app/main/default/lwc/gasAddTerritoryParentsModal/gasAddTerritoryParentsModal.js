import { LightningElement, api } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";

export default class GasAddTerritoryParentsModal extends LightningElement {
    @api parentAccounts;
    @api hasMoreThanOneTerritory;
    selectedParents = [];

    // Labels using Veeva Messages
    addToTerritoryLabel = 'Add to Territory';
    cancelButtonLabel = 'Cancel';
    okayButtonLabel = 'OK';
    nextButtonLabel = 'Next';
    selectParentAccountLabel = 'Select Parent Accounts (Optional)';

    async connectedCallback() {
        const veevaMessageService = getPageController('messageSvc');
        await Promise.all([
            this.loadLabels(veevaMessageService)
        ]);
    }

    async loadLabels(veevaMessageService) {
        const veevaMessages = await Promise.all([
            veevaMessageService.getMessageWithDefault('GAS_ADD_TO_TERRITORY', 'Global Account Search', this.addToTerritoryLabel),
            veevaMessageService.getMessageWithDefault('CANCEL', 'Common', this.cancelButtonLabel),
            veevaMessageService.getMessageWithDefault('OK', 'Common', this.okayButtonLabel),
            veevaMessageService.getMessageWithDefault('NEXT', 'View', this.nextButtonLabel),
            veevaMessageService.getMessageWithDefault('GAS_SELECT_PARENT_ACCOUNTS', 'Global Account Search', this.selectParentAccountLabel),
        ]);
        this.addToTerritoryLabel = veevaMessages[0];
        this.cancelButtonLabel = veevaMessages[1];
        this.okayButtonLabel = veevaMessages[2];
        this.nextButtonLabel = veevaMessages[3];
        this.selectParentAccountLabel = veevaMessages[4];
    }

    closeAddTerritoryModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    updateSelectedParents(event) {
        this.selectedParents = event.detail.value;
    }

    navigateToTerritoryOptions(){
        this.dispatchEvent(new CustomEvent("navigatetoterrselect", {
            detail: {
              parentAccountsSelected: this.selectedParents,
            },
            bubbles: true, composed: true
          })
      );
    }

    get actionButtonLabel(){
        let buttonLabel = this.nextButtonLabel;
        if (!this.hasMoreThanOneTerritory){
            buttonLabel = this.okayButtonLabel;
        }
        return buttonLabel;
    }
}