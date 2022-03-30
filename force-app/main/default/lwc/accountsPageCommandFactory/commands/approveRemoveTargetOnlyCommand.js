import AccountsPageCommand from "./accountsPageCommand";
import { CHALLENGE_STATUSES } from "c/territoryFeedbackConstants";

export default class ApproveRemoveTargetOnlyCommand extends AccountsPageCommand {
    constructor(accountsPage, accounts) {
        super(accountsPage, accounts);
    }

    get shouldApprove() {
        return true;
    }

    get filter() {
        return 'REMOVE_TARGET_ONLY';
    }

    get updatedChallengeStatus() {
        return CHALLENGE_STATUSES.REJECTED;
    }

    get updatedTargetChallengeStatus() {
        return CHALLENGE_STATUSES.APPROVED;
    }

    async execute() {
        await this.approveOrRejectChallenges();
    }
}