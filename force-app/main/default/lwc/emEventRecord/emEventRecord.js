import VeevaRecord from "c/veevaRecord";
import EmEventConstant from "c/emEventConstant";

export default class EmEventRecord extends VeevaRecord {
    updateCountryNameLabel(displayValue) {
        if (this.fields[EmEventConstant.COUNTRY_LOOKUP]) {
            this.fields[EmEventConstant.COUNTRY_LOOKUP].displayValue = displayValue;
        } else {
            this.fields[EmEventConstant.COUNTRY_LOOKUP] = {
                displayValue: displayValue,
                value: null
            };
        }
    }

    reference(field) {
        if (field && field.apiName === EmEventConstant.COUNTRY) {
            const ref = {
                name: this.fields[EmEventConstant.COUNTRY_LOOKUP].displayValue,
                id: this.fields[EmEventConstant.COUNTRY].value,
                apiName: EmEventConstant.COUNTRY
            }
            return ref;
        } else {
            return super.reference(field);
        }
    }
}