import { AlignError } from "c/territoryFeedbackErrors";
import FieldForceModelsPageCommand from "./fieldForceModelsPageCommand";
import TerritoryFeedbackConstants from 'c/territoryFeedbackConstants';
import LOCALE from '@salesforce/i18n/locale';

export default class RepMoveToLifecycleStateCommand extends FieldForceModelsPageCommand {
    constructor(fieldForceModelsPage, targetTerritoryModel, label, lifecycleStateName) {
        super(fieldForceModelsPage, targetTerritoryModel, label);
        this.lifecycleStateName = lifecycleStateName;
    }

    get shouldRenderPendingChallengesModal() {
        return this.targetTerritoryModel.numPendingChallenges && this.lifecycleStateName !== 'change_state_to_draft__c';
    }

    async modalBody() {
        const [pendingMsg, approveOrRejectMsg] = await Promise.all([
            this.messageService.getMessageWithDefault('CHALLENGES_STILL_PENDING', 'Feedback', '{0} challenges are still pending.'),
            this.messageService.getMessageWithDefault('CHALLENGES_MUST_BE_APPROVED', 'Feedback', 'Challenges must be approved or rejected before submitting.')
        ]);

        const formattedNumPendingChallenges = new Intl.NumberFormat(LOCALE).format(this.targetTerritoryModel.numPendingChallenges);

        return [pendingMsg.replace('{0}', formattedNumPendingChallenges), approveOrRejectMsg];
    }

    modalType() {
        return 'pendingChallengesWithReview';
    }

    async execute() {
        if (this.shouldRenderPendingChallengesModal) {
            await this.showModal( async userAction => {
                this.fieldForceModelsPage.showLoadingSpinner();
                if (userAction === 'review') {
                    this.navigateToAccountsScreen();
                } else {
                    await this.approveOrRejectPendingChallenges(userAction);
                    await this.moveToLifecycleState();
                }
                this.fieldForceModelsPage.hideLoadingSpinner();
            });
        } else {
            await this.moveToLifecycleState();
        }
    }

    navigateToAccountsScreen() {
        this.fieldForceModelsPage.navigateToAccountsScreen(this.targetTerritoryModel.id, TerritoryFeedbackConstants.PENDING_CHALLENGES);
    }

    async approveOrRejectPendingChallenges(shouldApprove) {
        const response = await this.fieldForceModelsPage.territoryFeedbackService.bulkApproveOrRejectPendingChallenges(
            this.targetTerritoryModel.id, shouldApprove === 'approve'
        );

        if (response.status !== 'SUCCESS') {
            throw new AlignError(response.message);
        }

        this.fieldForceModelsPage.updatePendingChallenges(this.targetTerritoryModel.id);
    }

    async moveToLifecycleState() {
        const response = await this.fieldForceModelsPage.territoryFeedbackService.moveToLifecycleState(
            this.targetTerritoryModel.id, this.lifecycleStateName, false
        );

        if (response.status !== 'SUCCESS') {
            throw new AlignError(response.message);
        }

        const isFeedbackComplete = this.lifecycleStateName === 'change_state_to_feedback_complete__c';
        this.fieldForceModelsPage.updateTerritoryModels(
            response.territoryModelIds, response.lifecycleState, response.availableLifecycleActions, isFeedbackComplete, false, response.canReview);
        this.fieldForceModelsPage.refreshTable();
        this.fieldForceModelsPage.clearModal();
    }
}