import { LightningElement, api } from 'lwc';

export default class FieldPlanDates extends LightningElement {
    @api cycleDates;
    @api dueDate;
    @api dueLabel;
}