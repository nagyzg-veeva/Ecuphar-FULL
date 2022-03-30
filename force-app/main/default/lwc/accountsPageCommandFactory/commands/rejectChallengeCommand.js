import AccountsPageCommand from "./accountsPageCommand";
import { CHALLENGE_STATUSES } from "c/territoryFeedbackConstants";

export default class RejectChallengeCommand extends AccountsPageCommand {
    constructor(accountsPage, accounts) {
        super(accountsPage, accounts);
    }

    get shouldApprove() {
        return false;
    }

    get filter() {
        return null;
    }

    get updatedChallengeStatus() {
        return CHALLENGE_STATUSES.REJECTED;
    }

    get updatedTargetChallengeStatus() {
        return CHALLENGE_STATUSES.REJECTED;
    }

    async execute() {
        await this.approveOrRejectChallenges();
    }
}