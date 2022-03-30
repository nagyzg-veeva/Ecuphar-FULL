import { LightningElement,api } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";
export default class GasHeader extends LightningElement {
  @api resultcount;
  @api accountobjectname;
  @api hideNewAccount;
  @api disableNewAccount;
  @api enableAddTerritory = false;
  @api userFilterToggled;

  title;
  newButtonLabel;
  accountTypeOptions;
  accountTypeFilter;
  accountSearchString;
  addressSearchString;
  accountSearchBoxValidationMsg;
  addToTerritoryLabel;
  accountSearchPlaceholderText;
  locationSearchPlaceholderText;
  searchBtnLabel;
  itemsLabel;

  get disableAddToTerritory() {
    return !this.enableAddTerritory;
  }

  async connectedCallback(){
    this.accountSearchBoxValidationMsg = "Please enter at least 2 characters";
    const veevaMessageService = getPageController('messageSvc');
    this.accountTypeFilter = 'ALL';
    await this.loadVeevaMessages(veevaMessageService);
  }

  handleAccountTypeChange(event){
      this.accountTypeFilter = event.target.value;
      this.dispatchEvent(new CustomEvent('searchmodified'));
  }

  updateAccountSearchText(event){
    this.accountSearchString = event.target.value;
      this.dispatchEvent(new CustomEvent('searchmodified'));
  }

  updateAddressSearchText(event){
      this.addressSearchString = event.target.value;
      this.dispatchEvent(new CustomEvent('searchmodified'));
  }
  
  @api
  handleSearchWithUserFilters(userFilters) {
    if (!this.checkValidity()) {
      return;
    }
    this.dispatchEvent(
      new CustomEvent("search", {
        detail: {
          accountSearchText: this.accountSearchString,
          addressSearchText: this.addressSearchString,
          accountType: this.accountTypeFilter,
          userFilters: userFilters
        },
        bubbles: true, composed: true
      })
    );
  }

  handleSearch(){
      this.handleSearchWithUserFilters([]);
  }

  createNewAccount(){
    this.dispatchEvent(new CustomEvent('newaccount'));
  }

  async loadVeevaMessages(veevaMessageService) {
    [this.title, this.accountSearchBoxValidationMsg, this.newButtonLabel, this.addToTerritoryLabel, this.itemsLabel] = await Promise.all([
        veevaMessageService.getMessageWithDefault('GAS_TITLE', 'Global Account Search', 'Global Account Search'),
        veevaMessageService.getMessageWithDefault('GAS_SEARCH_CRITERIA_MINIMUM', 'Global Account Search', 'Enter at least 2 characters'),
        veevaMessageService.getMessageWithDefault('NEWACCT_SUBTITLE', 'AccountSoundex', 'New Account'),
        veevaMessageService.getMessageWithDefault('GAS_ADD_TO_TERRITORY', 'Global Account Search', 'Add to Territory'),
        veevaMessageService.getMessageWithDefault('GAS_ITEMS', 'Global Account Search', 'Items')
    ]);

    [this.accountSearchPlaceholderText, this.locationSearchPlaceholderText, this.searchBtnLabel] = await Promise.all([
      veevaMessageService.getMessageWithDefault('NAS_SEARCH_TERMS_CAPTION', 'NETWORK', 'Search Terms'),
      veevaMessageService.getMessageWithDefault('GAS_SEARCH_LOCATION_FIELD', 'Global Account Search', 'Enter Location'),
      veevaMessageService.getMessageWithDefault('SEARCH', 'Common', 'Search')
    ]);

    const [accountTypeAll, accountTypeHCP, accountTypeHCO] = await Promise.all([
        veevaMessageService.getMessageWithDefault('ALL', 'Common', 'All Accounts'),
        veevaMessageService.getMessageWithDefault('HCP', 'NETWORK', 'HCP'),
        veevaMessageService.getMessageWithDefault('HCO', 'NETWORK', 'HCO')
    ]);

    const accountTypes = new Map();
    accountTypes.set('ALL', accountTypeAll);
    accountTypes.set('HCP', accountTypeHCP);
    accountTypes.set('HCO', accountTypeHCO);
    this.setAccountTypePicklistOptions(accountTypes);
  }

  setAccountTypePicklistOptions(accountTypes){
    const accountTypesArr = [];
    accountTypes.forEach((labelMsg, key) => {
        accountTypesArr.push({ label : labelMsg, value : key});
    });
    this.accountTypeOptions = accountTypesArr;
  }

  checkValidity(){
    const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
        }, true);
    return allValid;
  }

  handleKeyUp(event) {
    if (event.key === 'Enter') {
      this.handleSearch();
    }
  }

  handleAddToTerritory() {
    this.dispatchEvent(new CustomEvent('addterritory'));
  }
  
  toggleFilter() {
    this.dispatchEvent(new CustomEvent('togglefilter'));
  }

}