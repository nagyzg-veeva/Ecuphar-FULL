import { LightningElement, api } from 'lwc';

export default class FieldPlanInstructions extends LightningElement {
    @api instructions;
    @api instructionsHeader;
}