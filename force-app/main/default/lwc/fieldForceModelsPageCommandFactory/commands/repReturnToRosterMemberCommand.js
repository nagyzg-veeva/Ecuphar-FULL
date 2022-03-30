import { AlignError } from "c/territoryFeedbackErrors";
import TerritoryModelRecord from "c/territoryModelRecord";
import FieldForceModelsPageCommand from "./fieldForceModelsPageCommand";

export default class RepReturnToRosterMemberCommand extends FieldForceModelsPageCommand {
    constructor(fieldForceModelsPage, targetTerritoryModel, label) {
        super(fieldForceModelsPage, targetTerritoryModel, label);
    }

    async modalBody() {
        const areYouSureMessage = await this.messageService.getMessageWithDefault('ARE_YOU_SURE', 'Common', 'Are you sure?');
        return [areYouSureMessage];
    }

    modalType() {
        return 'confirmation';
    }

    execute() {
        this.showModal( async () => {
            this.fieldForceModelsPage.clearModal();
            this.fieldForceModelsPage.showLoadingSpinner();
            await this.returnToRosterMember();
            this.fieldForceModelsPage.hideLoadingSpinner();
        });
    }

    async returnToRosterMember() {
        const response = await this.fieldForceModelsPage.territoryFeedbackService.moveToLifecycleState(
            this.targetTerritoryModel.id, TerritoryModelRecord.FEEDBACK_STATE, false
        );

        if (response.status !== 'SUCCESS') {
            throw new AlignError(response.message);
        }

        this.fieldForceModelsPage.updateTerritoryModels(response.territoryModelIds, null, response.availableLifecycleActions, false, true, response.canReview);
        this.fieldForceModelsPage.refreshTable();
    }
}