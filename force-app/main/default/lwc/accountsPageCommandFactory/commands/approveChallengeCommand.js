import AccountsPageCommand from "./accountsPageCommand";
import { CHALLENGE_STATUSES } from "c/territoryFeedbackConstants";

export default class ApproveChallengeCommand extends AccountsPageCommand {
    constructor(accountsPage, accounts) {
        super(accountsPage, accounts);
    }

    get shouldApprove() {
        return true;
    }

    get filter() {
        return null;
    }

    get updatedChallengeStatus() {
        return CHALLENGE_STATUSES.APPROVED;
    }

    get updatedTargetChallengeStatus() {
        return CHALLENGE_STATUSES.APPROVED;
    }

    async execute() {
        await this.approveOrRejectChallenges();
    }
}