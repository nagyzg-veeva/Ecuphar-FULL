import { LightningElement,api } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";

export default class GasAddTerritoryOptionsModal extends LightningElement {
    @api userTerritories;
    selectedTerritories = [];

    // Labels using Veeva Messages
    addToTerritoryLabel = 'Add to Territory';
    cancelButtonLabel = 'Cancel';
    okayButtonLabel = 'OK';
    selectTerritoryLabel = 'Select Territories';

    async connectedCallback() {
        const veevaMessageService = getPageController('messageSvc');
        await Promise.all([
            this.loadLabels(veevaMessageService)
        ]);
    }

    get canNotPressOkay() {
        return this.selectedTerritories.length === 0;
    }

    async loadLabels(veevaMessageService) {
        const veevaMessages = await Promise.all([
            veevaMessageService.getMessageWithDefault('GAS_ADD_TO_TERRITORY', 'Global Account Search', this.addToTerritoryLabel),
            veevaMessageService.getMessageWithDefault('CANCEL', 'Common', this.cancelButtonLabel),
            veevaMessageService.getMessageWithDefault('OK', 'Common', this.okayButtonLabel),
            veevaMessageService.getMessageWithDefault('GAS_SELECT_TERRITORIES', 'Global Account Search', this.selectTerritoryLabel),
        ]);
        this.addToTerritoryLabel = veevaMessages[0];
        this.cancelButtonLabel = veevaMessages[1];
        this.okayButtonLabel = veevaMessages[2];
        this.selectTerritoryLabel = veevaMessages[3];
    }

    closeAddTerritoryOptionsModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    updateSelectedTerritories(event) {
        this.selectedTerritories = event.detail.value;
    }

    handleAddTerritories(){
        this.dispatchEvent(new CustomEvent("addterritories", {
            detail: {
              selectedTerritories: this.selectedTerritories,
            },
            bubbles: true, composed: true
          })
      );
    }
}