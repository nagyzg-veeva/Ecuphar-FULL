import { LightningElement, api, track } from "lwc";
import VeevaItemTemplate from "./veevaItem.html";

export default class VeevaItem extends LightningElement {
  @api pageCtrl;
  @api record;
  @api item;
  @track hasBeenUpdated = false;
  @track classUndo = '';
  @track ctrl = {};
  @api initialValue;

  @api 
  get recordUpdateFlag(){
    return this._recordUpdateFlag;
  }

  set recordUpdateFlag(value){
    this._recordUpdateFlag = value;
    this.ctrl = this.pageCtrl.getItemController(this.item, this.record);
    this.initialValue = this.ctrl.rawValue;
  }

  shouldDisplayHighlighting(event){
    //Checks whether the field change was caused by a controlling field change
    if (event.detail === "ControllingFieldChanged"){
      //Highlighting should not display if the field's value did not change
      if ((this.initialValue === this.ctrl.rawValue) || (!this.initialValue && !this.ctrl.rawValue)){
        return false
      }
    }
    return true;
  }

  handleFieldChange(event) {
    //Adds undo button + highlighting
    if (this.shouldDisplayHighlighting(event)){
      this.hasBeenUpdated = true;
      this.classUndo = 'undo';
    }
  
    if(event.detail === "UndoClick"){
      this.handleUndoClick(); 
    }
  }

  handleUndoClick() {
    //SetFieldValue pushes the initialValue to the record
    this.ctrl.setFieldValue(this.initialValue, null, "UndoClick");
    //Removes undo button + highlighting
    this.hasBeenUpdated = false;
    this.classUndo = '';

    //Resetting the itemController to trigger a component refresh of this field 
    //LWC does not properly watch tracked components when initialized with new
    this.ctrl = this.pageCtrl.getItemController(this.item, this.record);
  }

  @api checkValidity() {
    return [...this.template.querySelectorAll("[data-validity]")].every(
      item => !item.checkValidity || item.checkValidity()
    );
  }

  render() {
    return (this.ctrl && this.ctrl.template) || VeevaItemTemplate;
  }

}