import { AlignError, NotImplementedError } from "c/territoryFeedbackErrors";
export default class AccountsPageCommand {
    constructor(accountsPage, accounts) {
        this.accountsPage = accountsPage;
        this.accounts = accounts;
    }

    get accountIds() {
        return this.accounts.map(account => account.id);
    }

    get shouldApprove() {
        // Implemented in subclasses
        return null;
    }

    get filter() {
        // Implemented in subclasses
        return null;
    }

    get updatedChallengeStatus() {
        // Implemented in subclasses
        return null;
    }

    get updatedTargetChallengeStatus() {
        // Implemented in subclasses
        return null;
    }

    async execute() {
        // Implemented in subclasses
        throw new NotImplementedError('execute() is not implemented in accountsPageCommand superclass');
    }
    
    async approveOrRejectChallenges() {
        this.accountsPage.loading = true;

        const response = await this.accountsPage.territoryFeedbackService.approveOrRejectChallenges(
            this.accountsPage.selectedTerritoryModelId, this.accountIds, this.shouldApprove, this.filter);

        if (response.status !== 'SUCCESS') {
            throw new AlignError(response.message);
        }

        await this.updateTable();
        this.accountsPage.loading = false;
    }

    async updateTable() {
        await this.accountsPage.updateChallengeStatusDisplay(this.accounts, this.updatedChallengeStatus, this.updatedTargetChallengeStatus);
        this.accountsPage.refreshTable();
        this.accountsPage.unselectRows();
    }
}