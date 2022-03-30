import { api, LightningElement } from 'lwc';
import { getPageController } from 'c/veevaPageControllerFactory';
import getParentAccounts from '@salesforce/apex/VeevaGlobalAccountSearchController.getParentAccounts';
import getUserAccessibleAddressFields from '@salesforce/apex/VeevaGlobalAccountSearchController.getUserAccessibleAddressFields';
import getUserTerritories from '@salesforce/apex/VeevaGlobalAccountSearchController.getUserTerritories';
import assignAccountsToTerritories from '@salesforce/apex/VeevaGlobalAccountSearchController.assignAccountsToTerritories';
import { loadStyle } from 'lightning/platformResourceLoader';
import gasToastMsgStyles from '@salesforce/resourceUrl/gasToastMsgStyles';

export default class GasAddTerritoryModal extends LightningElement {
  @api
  get accountId() {
    return this._accountId;
  }

  set accountId(value) {
    this._accountId = value;
    this.init();
  }

  parentAccounts = [];
  userTerritories = [];

  selectedTerritories = [];
  selectedParents = [];
  showAddTerritoryParentSelect = false;
  showAddTerritoryOptions = false;

  // Assignment Messages using Veeva Messages
  territoryAssignmentSuccess = 'Territory assignment successful.';
  territoryAssignmentFailed = 'Territory assignment failed.';
  noTerritoryAssignedMsg = 'Unable to assign to a territory because the user is not aligned to any territories.';

  async init() {
    await Promise.all([this.loadParentAccounts(), this.loadUserTerritories()]);
    if (this.parentAccounts && this.parentAccounts.length > 0) {
      this.showAddTerritoryParentSelect = true;
      this.showAddTerritoryOptions = false;
    } else {
      this.showTerrSelectModal();
    }
  }

  async connectedCallback() {
    const veevaMessageService = getPageController('messageSvc');
    await this.loadLabels(veevaMessageService);
    await loadStyle(this, gasToastMsgStyles);
  }

  get hasMoreThanOneTerritory() {
    return this.userTerritories.length > 1;
  }

  async loadParentAccounts() {
    try {
      // Retrieve Address Fields accessible to the user to display
      const addressFieldDisplayOrder = await getUserAccessibleAddressFields();
      const parentAccounts = await getParentAccounts({ accountId: this.accountId });
      this.parentAccounts = parentAccounts.map(parentAccount => {
        const addressInfo = getAddressInfo(parentAccount, addressFieldDisplayOrder);
        const label = getParentAccountLabel(parentAccount, addressInfo);
        return {
          value: parentAccount.Id,
          label,
        };
      });
    } catch (error) {
      console.error(error);
    }
  }

  async loadUserTerritories() {
    try {
      this.userTerritories = await getUserTerritories();
      if (!this.userTerritories.length) {
        this.dispatchToastEventAndCloseModal('error', this.noTerritoryAssignedMsg);
      } else if (this.userTerritories.length === 1) {
        this.selectedTerritories = this.userTerritories.map(userTerritory => userTerritory.value);
      }
    } catch (error) {
      console.error(error);
    }
  }

  async loadLabels(veevaMessageService) {
    [this.territoryAssignmentSuccess, this.territoryAssignmentFailed, this.noTerritoryAssignedMsg] = await Promise.all([
      veevaMessageService.getMessageWithDefault('GAS_ASSIGNMENT_SUCCESSFUL', 'Global Account Search', this.territoryAssignmentSuccess),
      veevaMessageService.getMessageWithDefault('GAS_ASSIGNMENT_ERROR', 'Global Account Search', this.territoryAssignmentFailed),
      veevaMessageService.getMessageWithDefault('GAS_NO_TERRITORY_ALIGNED_ERROR', 'Global Account Search', this.noTerritoryAssignedMsg),
    ]);
  }

  closeAddTerritoryModal() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  async addTerritory(event) {
    if (event && event.detail) {
      this.selectedTerritories = event.detail.selectedTerritories;
    }
    const territoryAssignmentsResult = await assignAccountsToTerritories({
      accountIds: [this.accountId, ...this.selectedParents],
      territoryIds: [...this.selectedTerritories],
    });
    if (territoryAssignmentsResult.success) {
      this.dispatchEvent(new CustomEvent('success', { detail: { accountId: this.accountId } }));
      this.dispatchToastEventAndCloseModal('success', this.territoryAssignmentSuccess);
    } else {
      let errorMessage = this.territoryAssignmentFailed;
      if (territoryAssignmentsResult.errorMessage) {
        errorMessage += `\n${territoryAssignmentsResult.errorMessage}`;
      }
      this.dispatchToastEventAndCloseModal('error', errorMessage);
    }
  }

  closeAddTerritoryParentsModal() {
    this.showAddTerritoryParentSelect = false;
    this.dispatchEvent(new CustomEvent('close'));
  }

  closeAddTerritoryOptionsModal() {
    this.showAddTerritoryOptions = false;
    this.dispatchEvent(new CustomEvent('close'));
  }

  showTerrSelectModal(event) {
    if (event && event.detail) {
      this.selectedParents = event.detail.parentAccountsSelected;
    }
    if (this.selectedTerritories && this.selectedTerritories.length > 0) {
      this.addTerritory();
    } else {
      this.showAddTerritoryParentSelect = false;
      this.showAddTerritoryOptions = true;
    }
  }

  dispatchToastEventAndCloseModal(toastVariant, msg) {
    this.dispatchEvent(
      new CustomEvent('toast', {
        detail: {
          message: msg,
          variant: toastVariant,
        },
      })
    );
    this.dispatchEvent(new CustomEvent('close'));
  }
}

function getParentAccountLabel(parentAccount, addressInfo) {
  // Check to make sure that addressInfo is not blank
  return addressInfo.trim().length === 0 ? parentAccount.Name : `${parentAccount.Name} (${addressInfo})`;
}

function getAddressInfo(parentAccount, addressFieldDisplayOrder) {
  let addressInfo = '';
  const addressFieldSet = new Set(addressFieldDisplayOrder);
  if (addressFieldDisplayOrder.length > 0 && parentAccount.Address_vod__r?.length > 0) {
    // We want to retrieve only Address fields that the Address has populated
    // We will also ignore the Zip field and since we have special formatting around the zip code
    const availableAddressFieldsOrdered = addressFieldDisplayOrder
      // Check to see if Address fields are populated and not just spaces and no text
      .filter(addressField => parentAccount.Address_vod__r[0][addressField]?.trim() && addressField !== 'Zip_vod__c')
      .map(addressField => parentAccount.Address_vod__r[0][addressField]);

    // We will place commas between all fields except the address Zip field
    addressInfo = availableAddressFieldsOrdered.join(', ');
    const addressZip = parentAccount.Address_vod__r[0]?.Zip_vod__c ?? '';
    if (addressFieldSet.has('Zip_vod__c') && addressZip) {
      // If the zip field should be displayed we will place a space between this and the prior field
      addressInfo += ` ${addressZip}`;
    }
  }
  return addressInfo;
}