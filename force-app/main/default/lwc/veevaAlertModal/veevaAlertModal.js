import { api, LightningElement } from 'lwc';
import { getPageController } from 'c/veevaPageControllerFactory';

export default class VeevaAlertModal extends LightningElement {
  @api title;
  @api show;
  @api size = 'small';
  @api messages;
  @api messageHorizontalAlign = 'center';
  @api okayLabel;

  defaultOkayLabel = 'Okay';

  get okayButtonLabel() {
    // Perform a "falsy" check on okayLabel which checks for not null and not empty string
    return this.okayLabel || this.defaultOkayLabel;
  }

  get hasHeader() {
    return !this.title;
  }

  connectedCallback() {
    this.loadDefaultVeevaMessages();
  }

  async loadDefaultVeevaMessages() {
    const veevaMessageService = getPageController('messageSvc');
    this.defaultOkayLabel = await veevaMessageService.getMessageWithDefault('OK', 'Common', this.defaultOkayLabel);
  }

  /**
   * This method is called whenever the user clicks on a button that closes the modal.
   */
  handleModalClose() {
    this.close();
  }

  /**
   * This method is called whenever the user clicks the confirmation/okay button on the alert.
   *
   * Note since this is a alert modal we will still emit the same onclose event if the user clicks the close icon or "Okay"
   */
  handleModalConfirm() {
    this.close();
  }

  close() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}