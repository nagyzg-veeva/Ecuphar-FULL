import AccountsPageCommand from "./accountsPageCommand";
import { CHALLENGE_STATUSES } from "c/territoryFeedbackConstants";

export default class ApproveAddAccountOnlyCommand extends AccountsPageCommand {
    constructor(accountsPage, accounts) {
        super(accountsPage, accounts);
    }

    get shouldApprove() {
        return true;
    }

    get filter() {
        return 'ADD_ACCOUNT_ONLY';
    }

    get updatedChallengeStatus() {
        return CHALLENGE_STATUSES.APPROVED;
    }

    get updatedTargetChallengeStatus() {
        return CHALLENGE_STATUSES.REJECTED;
    }

    async execute() {
        await this.approveOrRejectChallenges();
    }
}