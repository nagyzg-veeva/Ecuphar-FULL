import ApproveChallengeCommand from "./commands/approveChallengeCommand";
import ApproveAddAccountOnlyCommand from "./commands/approveAddAccountOnlyCommand";
import ApproveKeepAccountOnlyCommand from "./commands/approveKeepAccountOnlyCommand";
import ApproveRemoveTargetOnlyCommand from "./commands/approveRemoveTargetOnlyCommand";
import RejectChallengeCommand from "./commands/rejectChallengeCommand";

export default class AccountsPageCommandFactory {
    static APPROVE = 'approve';
    static APPROVE_ADD_ACCOUNT_ONLY = 'approveAddAccountOnly';
    static APPROVE_KEEP_ACCOUNT_ONLY = 'approveKeepAccountOnly';
    static APPROVE_REMOVE_TARGET_ONLY = 'approveRemoveTargetOnly';
    static REJECT = 'reject';

    static getInstance(accountsPage, commandName, accounts) {
        switch(commandName) {
            case AccountsPageCommandFactory.APPROVE:
                return new ApproveChallengeCommand(accountsPage, accounts);

            case AccountsPageCommandFactory.APPROVE_ADD_ACCOUNT_ONLY:
                return new ApproveAddAccountOnlyCommand(accountsPage, accounts);

            case AccountsPageCommandFactory.APPROVE_KEEP_ACCOUNT_ONLY:
                return new ApproveKeepAccountOnlyCommand(accountsPage, accounts);

            case AccountsPageCommandFactory.APPROVE_REMOVE_TARGET_ONLY:
                return new ApproveRemoveTargetOnlyCommand(accountsPage, accounts);

            case AccountsPageCommandFactory.REJECT:
                return new RejectChallengeCommand(accountsPage, accounts);
                
            default:
                return null;
        }
    }
}