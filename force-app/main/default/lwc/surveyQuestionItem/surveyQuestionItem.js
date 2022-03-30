import { api, LightningElement } from "lwc";

const LIGHTNING_INPUT_SUPPORTED_TYPES = {
    text: surveyQuestion => surveyQuestion.isText,
    number: surveyQuestion => surveyQuestion.isNumber,
    date: surveyQuestion => surveyQuestion.isDate,
    datetime: surveyQuestion => surveyQuestion.isDatetime
};

export default class SurveyQuestionItem extends LightningElement {
    @api question;

    get inputType() {
        return Object.keys(LIGHTNING_INPUT_SUPPORTED_TYPES)
                .find(lightningInputType => LIGHTNING_INPUT_SUPPORTED_TYPES[lightningInputType](this.question));
    }

    handleChange(event) {
        const newValue = event.detail.value;
        this.dispatchEvent(new CustomEvent("update", {
            detail: {
                questionId: this.question.id,
                value: newValue
            }
        }));
    }

    get surveyQuestionLabel() {
        if (this.question.isDescription) {
            return this.question.text;
        }
        return `${this.question.number}. ${this.question.text}`;
    }
}