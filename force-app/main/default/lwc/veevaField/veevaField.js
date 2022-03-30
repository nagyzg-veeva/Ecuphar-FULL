import { LightningElement, api } from "lwc";

export default class VeevaField extends LightningElement {
  @api ctrl;

  @api checkValidity() {
    let errors = [...this.template.querySelectorAll("[data-validity]")].filter(
      item => item.checkValidity && item.checkValidity() === false);
    return !errors.length;
  }

  handleChange(event) {
    const changedEvent = new CustomEvent("fieldchange", { detail: event.detail });
    this.dispatchEvent(changedEvent);
  }

  get isLookup() {
    return this.ctrl.veevaFieldReference && this.ctrl.editable;
  }

  get isPreview() {
    return this.ctrl.veevaFieldReference && this.ctrl.readonly;
  }
}