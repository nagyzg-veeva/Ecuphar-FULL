import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import VeevaToastEvent from "c/veevaToastEvent";

export default class VeevaButtonDelete extends NavigationMixin(LightningElement) {
  @api meta;
  @api pageCtrl;
  @track show;
  @track isDeleting;

  async connectedCallback() {
    const [msgConfirm, msgDel, msgCancel] = await Promise.all([
      this.pageCtrl.getMessageWithDefault('GENERIC_DELETE_BODY', 'Common', 'Are you sure you want to delete this {0}?'),
      this.pageCtrl.getMessageWithDefault('DELETE', 'Common', 'Delete'),
      this.pageCtrl.getMessageWithDefault('CANCEL', 'Common', 'Cancel')
    ]);

    this.msgDelete = msgDel;
    this.msgCancel = msgCancel;
    this.confirm = msgConfirm.replace('{0}', this.pageCtrl.objectLabel);
    this.header = `${msgDel} ${this.pageCtrl.objectLabel}`;
  }

  handleDelete() {
    this.isDeleting = true;
    this.pageCtrl.delete()
      .then(() => {
          this[NavigationMixin.Navigate](this.pageCtrl.getPageRefForDelete());
          // this.dispatchEvent(
          //   VeevaToastEvent.successMessage("Record is deleted"));
        })
        .catch(error => {
          let message = error;
          if (error.recordErrors && error.recordErrors.length > 0) {
            message = error.recordErrors[0];
          }

          this.dispatchEvent(VeevaToastEvent.error({ message: message }));
          this.isDeleting = false;
        })
        .finally(() => {
          this.show = false;
        });
  }

  handleClick() {
    this.show = true;
  }

  handleCancel() {
    this.show = false;
  }

  get isMenu() {
    return this.meta.menu;
  }
}