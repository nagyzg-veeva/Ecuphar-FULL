import { LightningElement, api } from "lwc";
import getMsgWithDefault from "@salesforce/apex/VeevaMessageController.getMsgWithDefault";

const BASE_Z_INDEX = 9000;

export default class VeevaModal extends LightningElement {
  static openModals = 0;

  @api size = "small";
  @api close = "close";
  @api maxHeight = false;
  @api composed = false;
  @api overrideOverflow = false;
  @api hideHeader = false;
  @api hideFooter = false;

  _modalIndex;

  closeWindowLabel;

  async connectedCallback() {
      this._modalIndex = VeevaModal.openModals;
      VeevaModal.openModals += 1;
      this.closeWindowLabel = await getMsgWithDefault({
          key: "LTNG_CLOSE_WINDOW",
          category: "Lightning",
          defaultMessage: "Close this window"
      });
  }

  renderedCallback() {
      const additionalZ = (this._modalIndex) * 2;

      const backdrop = this.template.childNodes[1];
      const modal = this.template.childNodes[0];
      backdrop.style['z-index'] = BASE_Z_INDEX + additionalZ;
      modal.style['z-index'] = BASE_Z_INDEX + 1 + additionalZ;
  }

  disconnectedCallback() {
    VeevaModal.openModals -= 1;
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent(this.close, { bubbles: true, composed: this.composed }));
  }

  @api get modal() {
    const baseCss = "slds-modal slds-fade-in-open";
    let myCss;
    if (this.size.indexOf("veeva-") === 0) {
      // outer modal shouldn't get the veeva size, default to small
      myCss = baseCss + " slds-modal_small";
    } else {
      // use the salesforce-provided size
      myCss = baseCss + " slds-modal_" + this.size;
    }
    return myCss;
  }

  get veevaModalSize() {
    let myCss = "slds-modal__container";
    if (this.size.indexOf("veeva-") === 0) {
      // tack on our override sizing
      myCss += " veeva-modal__container--" + this.size;
    }
    return myCss;
  }

  @api get contentClass() {
    let css = "slds-modal__content slds-p-horizontal--medium";
    if (this.maxHeight) css += " max-height-content";
    if (this.overrideOverflow) css += " override-overflow";
    return css;
  }

  get headerClass() {
    return this.hideHeader
        ? "slds-modal__header slds-modal__header_empty"
        : "slds-modal__header"
  }

  get footerClass() {
    return this.hideFooter
        ? "slds-modal__footer slds-hide"
        : "slds-modal__footer"
  }
}