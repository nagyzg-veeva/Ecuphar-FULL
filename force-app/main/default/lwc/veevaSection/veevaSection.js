import { LightningElement, api, track } from "lwc";
import SectionTemplate from './veevaSection.html';

export default class VeevaSection extends LightningElement {
  @api pageCtrl;
  @api section;
  @api variant;
  @api open;
  @api first;
  @track ctrl;

  @api 
  get recordUpdateFlag(){
    return this._recordUpdateFlag;
  }
  
  set recordUpdateFlag(value){    
    this._recordUpdateFlag = value;
    this.ctrl = this.pageCtrl.getSectionController(this.section);
  }

  render() {
    return this.ctrl.template || SectionTemplate;
  }

  @api checkValidity() {
    if (this.pageCtrl.deleted && !this.ctrl.template) {
      return true; // skip validation for deletion
    }
    let errors = [...this.template.querySelectorAll("[data-validity]")].filter(
      item => item.checkValidity && item.checkValidity() === false);
    return !errors.length;
  }
}