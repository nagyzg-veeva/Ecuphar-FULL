import { AlignError, AsyncProcessRunningError } from "c/territoryFeedbackErrors";
import FieldForceModelsPageCommand from "./fieldForceModelsPageCommand";
import LOCALE from '@salesforce/i18n/locale';

export default class ManagerMoveAllToLifecycleStateCommand extends FieldForceModelsPageCommand {
    constructor(fieldForceModelsPage, targetTerritoryModel, label, lifecycleStateName) {
        super(fieldForceModelsPage, targetTerritoryModel, label);
        this.lifecycleStateName = lifecycleStateName;
        this.numChildrenThatCanTransition = targetTerritoryModel.getChildrenThatCanTransition(lifecycleStateName).length;
        this.numChildrenThatCannotTransition = targetTerritoryModel.repLevelChildTerritories.length - this.numChildrenThatCanTransition;
    }

    get shouldRenderPendingChallengesModal() {
        return this.targetTerritoryModel.numPendingChallenges && this.lifecycleStateName !== 'change_state_to_draft__c';
    }

    _modalBody;
    _modalType;

    modalBody() {
        return this._modalBody;
    }

    modalType() {
        return this._modalType;
    }

    async execute() {
        if (!this.numChildrenThatCannotTransition && !this.shouldRenderPendingChallengesModal) {
            await this.displayConfirmationModal();
        } else if (this.numChildrenThatCannotTransition) {
            await this.displayMovePartialChildrenModal();
        } else {
            await this.displayPendingChallengesModal();
        }
    }

    async displayConfirmationModal() {
        this._modalBody = await Promise.all([
            this.messageService.getMessageWithDefault('APPLY_TO_SUBORDINATE_TERRITORIES', 'Feedback', 'This will apply to all subordinate territories.'),
            this.messageService.getMessageWithDefault('ARE_YOU_SURE', 'Common', 'Are you sure?')
        ]);
        this._modalType = "confirmation";

        this.showModal( async () => {
            this.fieldForceModelsPage.clearModal();
            this.fieldForceModelsPage.showLoadingSpinner();
            await this.moveAllToLifecycleState();
            this.fieldForceModelsPage.hideLoadingSpinner();
        });
    }

    async displayMovePartialChildrenModal() {
        const [subMessage, remainingMessage] = await Promise.all([
            this.messageService.getMessageWithDefault('SUB_TERRS_CANNOT_BE_MOVED', 'Feedback', '{0} of the subordinate territories are not in a state that can be moved to the requested state.'),
            this.messageService.getMessageWithDefault('PROCEED_WITH_REMAINING_TERRS', 'Feedback', 'Proceed with the remaining territories?')
        ]);

        const formattedNumChildren = new Intl.NumberFormat(LOCALE).format(this.numChildrenThatCannotTransition);

        this._modalBody = [
            subMessage.replace('{0}', formattedNumChildren),
            remainingMessage
        ];
        this._modalType = "confirmation";

        this.showModal( async () => {
            if (this.shouldRenderPendingChallengesModal) {
                await this.displayPendingChallengesModal();
            } else {
                this.fieldForceModelsPage.clearModal();
                this.fieldForceModelsPage.showLoadingSpinner();
                await this.moveAllToLifecycleState();
                this.fieldForceModelsPage.hideLoadingSpinner();
            }
        });
    }

    async displayPendingChallengesModal() {
        const [pendingMessage, approveOrRejectMessage] = await Promise.all([
            this.messageService.getMessageWithDefault('CHALLENGES_STILL_PENDING', 'Feedback', '{0} challenges are still pending.'),
            this.messageService.getMessageWithDefault('CHALLENGES_MUST_BE_APPROVED', 'Feedback', 'Challenges must be approved or rejected before submitting.')
        ]);

        const formattedNumPendingChallenges = new Intl.NumberFormat(LOCALE).format(this.targetTerritoryModel.numPendingChallenges);

        this._modalBody = [
            pendingMessage.replace('{0}', formattedNumPendingChallenges),
            approveOrRejectMessage
        ];
        this._modalType = "pendingChallenges";

        this.showModal( async userAction => {
            this.fieldForceModelsPage.clearModal();
            this.fieldForceModelsPage.showLoadingSpinner();
            await this.approveOrRejectPendingChallenges(userAction);
            await this.moveAllToLifecycleState();
            this.fieldForceModelsPage.hideLoadingSpinner();
        });
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

    async moveAllToLifecycleState() {
        const runAsynchronously = this.numChildrenThatCanTransition >= 100;

        const response = await this.fieldForceModelsPage.territoryFeedbackService.moveToLifecycleState(
            this.targetTerritoryModel.id, this.lifecycleStateName, runAsynchronously
        );

        // For MVP we want to stop user from proceeding until async process has finished
        if (runAsynchronously) {
            throw new AsyncProcessRunningError('An asynchronous process is running against this user\'s data.');
        } else if (response.status !== 'SUCCESS') {
            throw new AlignError(response.message);
        }

        const isFeedbackComplete = this.lifecycleStateName === 'change_state_to_feedback_complete__c';
        this.fieldForceModelsPage.updateTerritoryModels(
            response.territoryModelIds, response.lifecycleState, response.availableLifecycleActions, isFeedbackComplete, false, response.canReview);
        this.fieldForceModelsPage.refreshTable();
    }
}