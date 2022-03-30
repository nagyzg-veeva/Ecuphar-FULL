export default class SurveyQuestion {
    constructor(questionFromSurveySuggestion, noneLabel) {
        this._questionFromSurveySuggestion = questionFromSurveySuggestion;
        // we need this to be set as we do not know the ordering
        this._number = null;
        this._value = null;
        this._noneLabel = noneLabel;
    }

    get id() {
        return this._questionFromSurveySuggestion.Id;
    }

    get text() {
        return this._questionFromSurveySuggestion.questionText;
    }

    get number() {
        return this._number;
    }

    set number(value) {
        this._number = value;
    }

    get value() {
        return this._value;
    }

    set value(value) {
        this._value = value;
    }

    get options() {
        const questionPicklistValues = this._questionFromSurveySuggestion.fieldMetadata.picklist || [];
        const baseOptions = this.getBaseOptions();
        const options = questionPicklistValues.map(option => ({
            label: option.label,
            value: option.value,
            defaultValue: option.defaultValue
        }));
        return baseOptions.concat(options);
    }

    get required() {
        return this._questionFromSurveySuggestion.required;
    }

    get isText() {
        return this._questionFromSurveySuggestion.recordTypeName === "Text_vod";
    }

    get isLongText() {
        return this._questionFromSurveySuggestion.recordTypeName === "Long_Text_vod";
    }

    get isNumber() {
        return this._questionFromSurveySuggestion.recordTypeName === "Number_vod";
    }

    get isDate() {
        return this._questionFromSurveySuggestion.recordTypeName === "Date_vod";
    }

    get isDatetime() {
        return this._questionFromSurveySuggestion.recordTypeName === "Datetime_vod";
    }

    get isRadio() {
        return this._questionFromSurveySuggestion.recordTypeName === "Radio_vod";
    }

    get isMultiselect() {
        return this._questionFromSurveySuggestion.recordTypeName === "Multiselect_vod";
    }

    get isPicklist() {
        return this._questionFromSurveySuggestion.recordTypeName === "Picklist_vod";
    }

    get isDescription() {
        return this._questionFromSurveySuggestion.recordTypeName === "Description_vod";
    }

    getBaseOptions() {
        const baseOptions = [];
        if (!this.required && this.isPicklist || this.isRadio) {
            // An empty string as the value will count as "falsy"
            baseOptions.push({
                label: this._noneLabel ? this._noneLabel : "--None--",
                value: ""
            });
        }
        return baseOptions;
    }
}