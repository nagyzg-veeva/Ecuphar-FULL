import { LightningElement, api } from 'lwc';

export default class FieldPlanInfoPanel extends LightningElement {
    @api messageService;

    type;
    header;

    geoInfo;

    cycleDates;
    dueDate;
    instructions;

    @api
    get isGeoChangePanel() {
        return this.type === 'geoChange';
    }

    get isInfoPanel() {
        return this.type === 'info';
    }

    get hasGeoChanges() {
        return this.geoInfo?.some(info => info.geos.length);
    }

    async connectedCallback() {
        await this.loadVeevaMessages();
    }

    @api
    populateGeoChangePanel(panelConfig) {
        this.type = 'geoChange';
        this.header = panelConfig.header;
        this.geoInfo = [
            { header: this.addedHeader, geos: panelConfig.geoAdded.sort() },
            { header: this.droppedHeader, geos: panelConfig.geoDropped.sort() }
        ];
    }

    @api
    populateInfoPanel(panelConfig) {
        this.type = 'info';
        this.header = panelConfig.header;

        this.geoInfo = [
            { header: this.addedHeader, geos: panelConfig.geoAdded.sort() },
            { header: this.droppedHeader, geos: panelConfig.geoDropped.sort() }
        ];

        this.cycleDates = [
            { label: this.startLabel, date: panelConfig.startDate },
            { label: this.endLabel, date: panelConfig.endDate }
        ];
        this.dueDate = panelConfig.dueDate;
        this.instructions = panelConfig.instructions;
    }

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async loadVeevaMessages() {
        [this.addedHeader, this.droppedHeader, this.noneLabel, this.startLabel, this.endLabel, this.dueLabel, this.instructionsHeader, this.geoChangesHeader] = await Promise.all([
            this.messageService.getMessageWithDefault('Added', 'Common', 'Added'),
            this.messageService.getMessageWithDefault('Dropped', 'Common', 'Dropped'),
            this.messageService.getMessageWithDefault('NONE_NO_DASH', 'Common', 'None'),
            this.messageService.getMessageWithDefault('START', 'Feedback', 'Start'),
            this.messageService.getMessageWithDefault('END', 'Feedback', 'End'),
            this.messageService.getMessageWithDefault('DUE', 'Feedback', 'Due'),
            this.messageService.getMessageWithDefault('INSTRUCTIONS', 'Feedback', 'Instructions'),
            this.messageService.getMessageWithDefault('GEO_CHANGES', 'Feedback', 'Geo Changes')
        ]);
    }
}