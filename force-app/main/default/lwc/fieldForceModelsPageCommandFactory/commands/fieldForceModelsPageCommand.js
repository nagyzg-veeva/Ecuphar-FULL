export default class FieldForceModelsPageCommand {
    constructor(fieldForceModelsPage, targetTerritoryModel, label) {
        this.fieldForceModelsPage = fieldForceModelsPage;
        this.targetTerritoryModel = targetTerritoryModel;
        this.commandLabel = label;
    }

    get messageService() {
        return this.fieldForceModelsPage.messageService;
    }

    modalTitle() {
        return this.commandLabel;
    }

    modalBody() {
        return [];
    }

    modalType() {
        return null;
    }

    async showModal(onConfirmCallback) {
        this.fieldForceModelsPage.showModal({
            type: this.modalType(),
            title: this.modalTitle(),
            body: await this.modalBody()
        }, onConfirmCallback);
    }

    async execute() {
        // To be implemented by subclasses
    }
}