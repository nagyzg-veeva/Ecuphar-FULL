import getAccountAddresses from "@salesforce/apex/MedInqController.getAccountAddresses";
import getAccountEmails from "@salesforce/apex/MedInqController.getAccountEmails";
import getAccountPhones from "@salesforce/apex/MedInqController.getAccountPhones";
import getAccountFaxes from "@salesforce/apex/MedInqController.getAccountFaxes";
import { getUIRecordAddress } from "c/addressVod";
import MedInqConstant from "c/medInqConstant";
import VeevaUtils from 'c/veevaUtils';

const FIELD_MAP = {
    name: "Address_Line_1_vod__c",
    line2: "Address_Line_2_vod__c",
    city: "City_vod__c",
    state: "State_vod__c",
    zip: "Zip_vod__c",
    country: "Country_vod__c"
};

const DeliveryService = {
    selectedDelivery: function (signal, stateFld, countryFld) {
        let fieldDisplayValue = "";
        switch (signal) {
            case "eom":
                let address = getUIRecordAddress(this.fields, FIELD_MAP, stateFld, countryFld);
                return address;
            case "eop":
                fieldDisplayValue = this.displayValue(MedInqConstant.PHONE);
                break;
            case "eof":
                fieldDisplayValue = this.displayValue(MedInqConstant.FAX);
                break;
            case "eoe":
                fieldDisplayValue = this.displayValue(MedInqConstant.EMAIL);
                break;
            default:
                fieldDisplayValue = "";
        }
        return { "value": fieldDisplayValue, "label": fieldDisplayValue};
    },

    deliveryOptions: function (signal) {
        let accountId = this.rawValue("Account_vod__c");
        if (VeevaUtils.validSfdcId(accountId)) {
            switch (signal) {
                case "eom":
                    return getAccountAddresses({ accountId: accountId }).then(data => {
                        // console.log(JSON.stringify(data, null, 2));
                        return JSON.parse(JSON.stringify(data));
                    });
                case "eoe":
                    return getAccountEmails({ accountId: accountId }).then(data => {
                        // console.log(JSON.stringify(data, null, 2));
                        return JSON.parse(JSON.stringify(data));
                    });
                case "eof":
                    return getAccountFaxes({ accountId: accountId }).then(data => {
                        // console.log(JSON.stringify(data, null, 2));
                        return JSON.parse(JSON.stringify(data));
                    });
                case "eop":
                    return getAccountPhones({ accountId: accountId }).then(data => {
                        // console.log(JSON.stringify(data, null, 2));
                        return JSON.parse(JSON.stringify(data));
                    });
                default:
                    break;
            }
        }
        return [];
    },

    stampMethodFields: function (values, method) {
        let fields = MedInqConstant.NEW_FIELDS[MedInqConstant.SIGNALS_MAP[method]];
        if (method === 'eom') {
            fields.forEach(key => this.setFieldValue(key, values[key]));
        }
        else {
            this.setFieldValue(fields[0], values.value);
        }
    },

    clear: function (fields) {
        fields.forEach(field => this.setFieldValue(field, null));
    }
}

export { DeliveryService };