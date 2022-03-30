import { AlignError } from "c/territoryFeedbackErrors";
import FieldForceModelsPageCommand from "./fieldForceModelsPageCommand";
import LOCALE from '@salesforce/i18n/locale';

export default class ApproveOrRejectPendingChallengesCommand extends FieldForceModelsPageCommand {
    constructor(fieldForceModelsPage, targetTerritoryModel, label, shouldApprove) {
        super(fieldForceModelsPage, targetTerritoryModel, label);
        this.shouldApprove = shouldApprove;
    }

    async modalBody() {
        const approveOrRejectMessage = this.shouldApprove ?
            await this.messageService.getMessageWithDefault('APPROVE_ALL_PENDING_CHALLENGES', 'Feedback', 'Approve all {0} pending challenges?') :
            await this.messageService.getMessageWithDefault('REJECT_ALL_PENDING_CHALLENGES', 'Feedback', 'Reject all {0} pending challenges?');

        const formattedNumPendingChallenges = new Intl.NumberFormat(LOCALE).format(this.targetTerritoryModel.numPendingChallenges);
        
        return [approveOrRejectMessage.replace('{0}', formattedNumPendingChallenges)];
    }

    modalType() {
        return 'confirmation';
    }

    async execute() {
        await this.showModal( async () => {
            this.fieldForceModelsPage.clearModal();
            this.fieldForceModelsPage.showLoadingSpinner();
            await this.approveOrRejectPendingChallenges();
            this.fieldForceModelsPage.hideLoadingSpinner();
        });
    }

    async approveOrRejectPendingChallenges() {
        const response = await this.fieldForceModelsPage.territoryFeedbackService.bulkApproveOrRejectPendingChallenges(
            this.targetTerritoryModel.id, this.shouldApprove
        );

        if (response.status !== 'SUCCESS') {
            throw new AlignError(response.message);
        }

        this.fieldForceModelsPage.updatePendingChallenges(this.targetTerritoryModel.id);
        this.fieldForceModelsPage.refreshTable();
    }
}