import { LightningElement, api } from 'lwc';

export default class VeevaPageHeader extends LightningElement {
    @api iconName;
    @api title;
    @api subtitle;
}