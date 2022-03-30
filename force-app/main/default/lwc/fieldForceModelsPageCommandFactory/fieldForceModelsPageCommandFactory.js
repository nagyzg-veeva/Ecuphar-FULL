import ApproveOrRejectPendingChallengesCommand from './commands/approveOrRejectPendingChallengesCommand';
import RepMoveToLifecycleStateCommand from './commands/repMoveToLifecycleStateCommand';
import RepReturnToRosterMemberCommand from './commands/repReturnToRosterMemberCommand';
import ManagerMoveAllToLifecycleStateCommand from './commands/managerMoveAllToLifecycleStateCommand';
import ManagerReturnAllToRosterMembersCommand from './commands/managerReturnAllToRosterMembersCommand';
export default class FieldForceModelsPageCommandFactory {
    static getInstance(fieldForceModelsPage, targetTerritoryModel, commandName, label) {
        switch(commandName) {
            case 'approve_pending_challenges':
                return new ApproveOrRejectPendingChallengesCommand(fieldForceModelsPage, targetTerritoryModel, label, true);
            case 'reject_pending_challenges':
                return new ApproveOrRejectPendingChallengesCommand(fieldForceModelsPage, targetTerritoryModel, label, false);
            case 'return_to_roster_member':
                return new RepReturnToRosterMemberCommand(fieldForceModelsPage, targetTerritoryModel, label);
            case 'return_all_to_roster_members':
                return new ManagerReturnAllToRosterMembersCommand(fieldForceModelsPage, targetTerritoryModel, label);
            default:
                return getLifecycleStateCommand(fieldForceModelsPage, targetTerritoryModel, label, commandName);
        }
    }
}

function getLifecycleStateCommand(fieldForceModelsPage, targetTerritoryModel, label, commandName) {
    if (targetTerritoryModel.isRepLevelTerritoryModel) {
        return new RepMoveToLifecycleStateCommand(fieldForceModelsPage, targetTerritoryModel, label, commandName);
    } else {
        return new ManagerMoveAllToLifecycleStateCommand(fieldForceModelsPage, targetTerritoryModel, label, commandName);
    }
}