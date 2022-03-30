import { LightningElement, api } from 'lwc';

export default class GeoChangeBadges extends LightningElement {
    @api geoInfo;
    @api noneLabel;
}