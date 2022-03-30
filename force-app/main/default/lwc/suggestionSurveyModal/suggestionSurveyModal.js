import { track } from "lwc";
import SurveyQuestion from "c/surveyQuestion";
import { publish } from "lightning/messageService"
import myInsightsModalChannel from "@salesforce/messageChannel/MyInsights_Modal__c";
import MyInsightsBaseModal from "c/myInsightsBaseModal"

export default class SuggestionSurveyModal extends MyInsightsBaseModal {

    @track modal = {
        show: false,
        title: null,
        labels: {}
    };

    @track surveyQuestions = [];

    hasExpectedMessage(type, data, htmlReportId, htmlReportUUID) {
        return type === "suggestionSurveyModal" && data && htmlReportId === this.htmlReportId && htmlReportUUID === this.htmlReportUuid;
    }

    updateModal(data) {
        if (data) {
            const labels = data.labels || {};
            const survey = data.survey || { surveyQuestions: [] };
            this.modal.show = true;
            this.modal.title = data.title;
            this.modal.labels = labels;
            this.surveyQuestions = this.getSurveyQuestions(survey);
        }
    }

    clearModal() {
        this.modal.show = false;
        this.modal.title = null;
        this.modal.labels = null;
        this.surveyQuestions = [];
    }

    getSurveyQuestions(survey) {
        const surveyQuestions = [];
        let questionNumber = 1;
        survey.surveyQuestions.forEach(question => {
            const surveyQuestion = new SurveyQuestion(question);
            if (!surveyQuestion.isDescription) {
                surveyQuestion.number = questionNumber;
                questionNumber++;
            }
            surveyQuestions.push(surveyQuestion);
        });
        return surveyQuestions;
    }

    handleModalSubmitted() {
        // We will check for survey questions that are falsy and required
        const requiredQuestionsWithNoValue = this.surveyQuestions
            .filter(question => question.required && !question.value);
        if (requiredQuestionsWithNoValue.length === 0) {
            // Check for "truthy" values, this means non-null, not undefined and not empty
            const populatedSurveyQuestions = this.surveyQuestions
                .filter(question => question.value)
                .map(question => ({
                    id: question.id,
                    value: question.value
                }));
            this.clearModal();
            publish(this.messageContext, myInsightsModalChannel, {
                htmlReportId: this.htmlReportId,
                htmlReportUUID: this.htmlReportUuid,
                type: "modalClosed",
                data: {
                    result: "submit",
                    populatedSurveyQuestions: populatedSurveyQuestions
                }
            });
        }
    }

    handleQuestionUpdate(event) {
        const { questionId, value } = event.detail;
        const matchingQuestion = this.surveyQuestions.find(question => question.id === questionId);
        matchingQuestion.value = value;
    }
}