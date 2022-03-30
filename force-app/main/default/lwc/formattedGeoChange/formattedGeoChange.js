import { LightningElement, api } from 'lwc';

export default class FormattedGeoChange extends LightningElement {
    @api numGeosAdded;
    @api numGeosDropped;
    @api noChangeLabel;

    get hasAddedAndDroppedGeos() {
        return this.numGeosAdded && this.numGeosDropped;
    }

    get hasNoChange() {
        return !this.numGeosAdded && !this.numGeosDropped;
    }
}