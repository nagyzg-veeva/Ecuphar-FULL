import { LightningElement, api } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
export default class VeevaButtonEdit extends NavigationMixin(LightningElement) {
  @api pageCtrl;
  @api meta;

  handleClick() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.pageCtrl.id,
        objectApiName: this.pageCtrl.objectApiName,
        actionName: "edit"
      }
    });
  }

  get isMenu() {
    return this.meta.menu;
  }

}