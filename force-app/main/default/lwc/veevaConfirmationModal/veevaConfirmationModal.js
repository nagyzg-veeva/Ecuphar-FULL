import { api, LightningElement } from 'lwc';
import { getPageController } from 'c/veevaPageControllerFactory';

export default class VeevaConfirmationModal extends LightningElement {
  @api title;
  @api show;
  @api size = 'small';
  @api messages;
  @api messageHorizontalAlign = 'center';
  @api confirmLabel;
  @api cancelLabel;

  defaultConfirmLabel = 'Okay';
  defaultCancelLabel = 'Cancel';

  get confirmButtonLabel() {
    // Perform a "falsy" check on confirmLabel which checks for not null and not empty string
    return this.confirmLabel || this.defaultConfirmLabel;
  }

  get cancelButtonLabel() {
    // Perform a "falsy" check on cancelLabel which checks for not null and not empty string
    return this.cancelLabel || this.defaultCancelLabel;
  }

  get hasHeader() {
    return !this.title;
  }

  connectedCallback() {
    this.loadDefaultVeevaMessages();
  }

  async loadDefaultVeevaMessages() {
    const veevaMessageService = getPageController('messageSvc');
    [this.defaultConfirmLabel, this.defaultCancelLabel] = await Promise.all([
      veevaMessageService.getMessageWithDefault('OK', 'Common', this.defaultConfirmLabel),
      veevaMessageService.getMessageWithDefault('CANCEL', 'Common', this.defaultCancelLabel),
    ]);
  }

  /**
   * This method is called whenever the user clicks on the confirmation button on the modal.
   */
  handleModalConfirm() {
    this.dispatchEvent(new CustomEvent('confirm'));
  }

  /**
   * This method is called whenever the user clicks on a button that intends to cancel the confirmation modal.
   */
  handleModalCancel() {
    this.dispatchEvent(new CustomEvent('cancel'));
  }
}