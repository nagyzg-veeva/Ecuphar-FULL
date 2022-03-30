import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getMsgWithDefault from "@salesforce/apex/VeevaMessageController.getMsgWithDefault";

const MSG_DELIMITER = '; ';

export default class VeevaToastEvent {

  static error(obj, mode) {
    return new ShowToastEvent({
      message: (obj.body ? obj.body.message : getErrorsFromMessage(obj.message)) || obj.statusText,
      variant: "error",
      mode: mode ? mode : 'dismissible'
    });

    function getErrorsFromMessage(message) {
        let errMsg = message;
        if (typeof errMsg !== 'string') {
            const fldErrs = Object.entries(message.fieldErrors || {}).map(([key, value]) => {
                return `${key}: ${value}`;
            });
            const msgArr = fldErrs.concat(message.recordErrors || []);
            errMsg = msgArr.join(MSG_DELIMITER);
        }
        return errMsg;
    }
  }

  static successMessage(msg) {
    return new ShowToastEvent({
      message: msg,
      variant: "success"
    });
  }

  // TODO: new Veeva Message if not available from Salesforce
  static async recordSaved() {
    let msg = await getMsgWithDefault({
      key: "RecordSaved",
      category: "Common",
      defaultMessage: "Record is saved"
    });
    return new ShowToastEvent({
      message: msg,
      variant: "success"
    });
  }

  static async recordDeleted() {
    let msg = await getMsgWithDefault({
      key: "RecordDeleted",
      category: "Common",
      defaultMessage: "Record is deleted"
    });
    return new ShowToastEvent({
      message: msg,
      variant: "success"
    });
  }

  static async recordCreated() {
    let msg = await getMsgWithDefault({
      key: "RecordCreated",
      category: "Common",
      defaultMessage: "Record is created"
    });
    return new ShowToastEvent({
      message: msg,
      variant: "success"
    });
  }

  static async notAllowedToEdit() {
    let message = await getMsgWithDefault({
      key: "NOT_ALLOWED_TO_EDIT",
      category: "Common",
      defaultMessage: "You do not have permission to edit this record."
    });

    return new ShowToastEvent({
      message,
      variant: 'error'
    });
  }
}