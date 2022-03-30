import AccountsPageCommandFactory from 'c/accountsPageCommandFactory';
import { CHALLENGE_STATUSES } from 'c/territoryFeedbackConstants';

const CHALLENGE_TYPES = {
    ADD_ACCOUNT: 'AddAccount',
    ADD_TARGET: 'AddTarget',
    REMOVE_ACCOUNT: 'RemoveAccount',
    REMOVE_TARGET: 'RemoveTarget',
    EDIT_GOAL: 'EditGoal',
    KEEP_ACCOUNT: 'KeepAccount',
    GOAL_EDIT: 'GoalEdit'
};

export const COLUMN_PREFIXES = {
    GOAL : 'goal',
    DETAIL : 'detail',
    METRIC : 'metric',
    SEGMENT : 'segment'
};

export default class AccountRecord {
    constructor(account) {
        this._id = account.id;
        this._name = account.formattedName ?? account.name;
        this._target = account.target;
        this._change = account.change;
        this._challengeType = account.challengeType;
        this._challengeStatus = account.challengeStatus;
        this._challengeReasons = account.challengeReasons ?? [];
        this._targetChallengeType = account.targetChallengeType;
        this._targetChallengeStatus = account.targetChallengeStatus;
        this._targetChallengeReasons = account.targetChallengeReasons ?? [];
        this._accountDetails = account.accountDetails ?? [];
        this._productMetricDetails = account.productMetricDetails ?? [];
        this._goalDetails = account.goalDetails ?? [];
        this._segmentDetails = account.segmentDetails ?? [];
    }

    get id() {
        return this._id;
    }

    get name() {
        return this._name;
    }

    get target() {
        return this._target;
    }

    get change() {
        return this._change;
    }

    get challengeType() {
        return this._challengeType;
    }

    get challengeStatus() {
        return this._challengeStatus;
    }

    set challengeStatus(challengeStatus) {
        this._challengeStatus = challengeStatus;
    }

    get challengeReasons() {
        return this._challengeReasons;
    }

    get targetChallengeType() {
        return this._targetChallengeType;
    }

    get targetChallengeStatus() {
        return this._targetChallengeStatus;
    }

    set targetChallengeStatus(targetChallengeStatus) {
        this._targetChallengeStatus = targetChallengeStatus;
    }

    get targetChallengeReasons() {
        return this._targetChallengeReasons;
    }

    get accountDetails() {
        return this._accountDetails;
    }

    get productMetricDetails() {
        return this._productMetricDetails;
    }

    get goalDetails() {
        return this._goalDetails;
    }

    get segmentDetails() {
        return this._segmentDetails;
    }

    get iconName() {
        // Even if no change, insert dash icon so that we can hide it to preserve spacing
        return this.change === 'ADDED' ? 'utility:add' : 'utility:dash';
    }

    get iconClass() {
        return (this.change === 'ADDED' || this.change === 'DROPPED') ? 'slds-p-right_x-small' : 'slds-p-right_x-small slds-hidden';
    }

    get challengeTypeDisplay() {
        return this._challengeTypeDisplay;
    }

    get availableActions() {
        return this._availableActions;
    }

    get challengeStatusDisplay() {
        return this._challengeStatusDisplay;
    }

    get reasonsDisplay() {
        if (!this.challengeReasons.length && !this.targetChallengeReasons.length) {
            return '-';
        } else {
            const reasonSet = new Set();
            this.challengeReasons?.forEach(reason => reasonSet.add(reason.label));
            this.targetChallengeReasons?.forEach(reason => reasonSet.add(reason.label));
            return [...reasonSet].join(', ');
        }
    }

    get moreActionsMenuClass() {
        return !this.availableActions.length ? 'hide-more-actions' : '';
    }

    get hasChallenge() {
        return this.challengeType || this.targetChallengeType;
    }

    get shouldAllowApprove() {
        return (this.challengeType && this.challengeStatus !== CHALLENGE_STATUSES.APPROVED)
            || (this.targetChallengeType && this.targetChallengeStatus !== CHALLENGE_STATUSES.APPROVED)
    }

    get shouldAllowReject() {
        return (this.challengeType && this.challengeStatus !== CHALLENGE_STATUSES.REJECTED)
            || (this.targetChallengeType && this.targetChallengeStatus !== CHALLENGE_STATUSES.REJECTED)
    }

    get shouldAllowApproveAddAccountOnly() {
        return this.challengeType === CHALLENGE_TYPES.ADD_ACCOUNT
            && this.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET
            && !(this.challengeStatus === CHALLENGE_STATUSES.APPROVED && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED);
    }

    get shouldAllowApproveKeepAccountOnly() {
        return this.challengeType === CHALLENGE_TYPES.KEEP_ACCOUNT
            && this.targetChallengeType === CHALLENGE_TYPES.ADD_TARGET
            && !(this.challengeStatus === CHALLENGE_STATUSES.APPROVED && this.targetChallengeStatus === CHALLENGE_STATUSES.REJECTED);
    }

    get shouldAllowApproveRemoveTargetOnly() {
        return this.challengeType === CHALLENGE_TYPES.REMOVE_ACCOUNT
            && this.targetChallengeType === CHALLENGE_TYPES.REMOVE_TARGET
            && !(this.challengeStatus === CHALLENGE_STATUSES.REJECTED && this.targetChallengeStatus === CHALLENGE_STATUSES.APPROVED);
    }

    async format(messageService, shouldFormatActions) {
        await AccountRecord._populateMessageMaps(messageService);

        this._challengeTypeDisplay = this.formatChallengeTypeDisplay();
        this._challengeStatusDisplay = this.formatChallengeStatusDisplay();
        if (shouldFormatActions) {
            this._availableActions = this.getTranslatedActions();
        }
    }

    formatChallengeTypeDisplay() {
        const translatedAccountType = AccountRecord._typeMessageMap.get(this.challengeType);
        const translatedTargetType = AccountRecord._typeMessageMap.get(this.targetChallengeType);

        let challengeText;
        if (translatedAccountType && translatedTargetType) {
            challengeText = `${translatedAccountType}, ${translatedTargetType}`;
        } else if (translatedAccountType) {
            challengeText = translatedAccountType;
        } else if (translatedTargetType) {
            challengeText = translatedTargetType;
        } else {
            challengeText = '-';
        }
        return challengeText;
    }

    formatChallengeStatusDisplay() {
        const translatedAccountStatus = AccountRecord._statusMessageMap.get(this.challengeStatus);
        const translatedTargetStatus = AccountRecord._statusMessageMap.get(this.targetChallengeStatus);

        let challengeText;
        if (translatedAccountStatus && translatedTargetStatus && (translatedAccountStatus !== translatedTargetStatus)) {
            challengeText = `${translatedAccountStatus}, ${translatedTargetStatus}`;
        } else if (translatedAccountStatus) {
            challengeText = translatedAccountStatus;
        } else if (translatedTargetStatus) {
            challengeText = translatedTargetStatus;
        } else {
            challengeText = '-';
        }
        return challengeText;
    }

    getTranslatedActions() {
        const availableActions = [];

        if (this.shouldAllowApprove) {
            availableActions.push({
                label: AccountRecord._actionsMessageMap.get(AccountsPageCommandFactory.APPROVE),
                name: AccountsPageCommandFactory.APPROVE
            });
        }

        // A single Account could render both Approve and Reject, but can only render 1 of the following:
        if (this.shouldAllowApproveAddAccountOnly) {
            availableActions.push({
                label: AccountRecord._actionsMessageMap.get(AccountsPageCommandFactory.APPROVE_ADD_ACCOUNT_ONLY),
                name: AccountsPageCommandFactory.APPROVE_ADD_ACCOUNT_ONLY
            });
        } else if (this.shouldAllowApproveKeepAccountOnly) {
            availableActions.push({
                label: AccountRecord._actionsMessageMap.get(AccountsPageCommandFactory.APPROVE_KEEP_ACCOUNT_ONLY),
                name: AccountsPageCommandFactory.APPROVE_KEEP_ACCOUNT_ONLY
            });
        } else if (this.shouldAllowApproveRemoveTargetOnly) {
            availableActions.push({
                label: AccountRecord._actionsMessageMap.get(AccountsPageCommandFactory.APPROVE_REMOVE_TARGET_ONLY),
                name: AccountsPageCommandFactory.APPROVE_REMOVE_TARGET_ONLY
            });
        }
        
        if (this.shouldAllowReject) {
            availableActions.push({
                label: AccountRecord._actionsMessageMap.get(AccountsPageCommandFactory.REJECT),
                name: AccountsPageCommandFactory.REJECT
            });
        }

        return availableActions;
    }

    setGoalValues(goalMetadata) {
        if (!this.target) {
            this.nullifyGoalFields(goalMetadata);
        } else {
            this.goalDetails.forEach((channelGoalDetails, channelIndex) => {
                const channelFieldName = `${COLUMN_PREFIXES.GOAL}${channelIndex}`;
                this.setGoalFields(channelFieldName, channelGoalDetails.feedbackChannelGoal, channelGoalDetails.channelGoal);
    
                channelGoalDetails.productGoals.forEach((productGoalDetails, productIndex) => {
                    const productFieldName = `${COLUMN_PREFIXES.GOAL}${channelIndex}_${productIndex}`;
                    this.setGoalFields(productFieldName, productGoalDetails.feedbackProductGoal, productGoalDetails.productGoal);
                });
            });
        }
    }

    nullifyGoalFields(goalMetadata) {
        goalMetadata.forEach((channel, channelIndex) => {
            const channelFieldName = `${COLUMN_PREFIXES.GOAL}${channelIndex}`;
            this.setGoalFields(channelFieldName, null, null);

            channel.products.forEach((_, productIndex) => {
                const productFieldName = `${COLUMN_PREFIXES.GOAL}${channelIndex}_${productIndex}`;
                this.setGoalFields(productFieldName, null, null);
            });
        });
    }

    setGoalFields(baseFieldName, feedbackGoal, goal) {
        if (!this.target) {
            this[baseFieldName] = null;
            this[`${baseFieldName}_isNull`] = true;
        } else if (feedbackGoal === undefined || feedbackGoal === null) {
            this[baseFieldName] = goal;
            this[`${baseFieldName}_isNull`] = !goal;
        } else {
            const difference = feedbackGoal - goal;
            this[baseFieldName] = feedbackGoal;
            this[`${baseFieldName}_difference`] = difference;
            this[`${baseFieldName}_differenceIsPositive`] = difference >= 0;
        }
    }

    setAccountAndAddressValues() {
        this.accountDetails.forEach((detail, detailIndex) => {
            const fieldName = `${COLUMN_PREFIXES.DETAIL}${detailIndex}`;
            this[fieldName] = detail;
        });
    }

    setProductMetricsValues() {
        this.productMetricDetails.forEach((productMetricDetail, productMetricIndex) => {
            productMetricDetail.productValues.forEach((productValue, productIndex) => {
                const fieldName = `${COLUMN_PREFIXES.METRIC}${productMetricIndex}_${productIndex}`;
                this[fieldName] = productValue;
            });
        });
    }

    setSegmentValues(segmentMetadata) {
        if (!this.target) {
            this.nullifySegmentFields(segmentMetadata);
        } else {
            this.segmentDetails.forEach((segmentDetail, segmentDetailIndex) => {
                const segmentFieldName = `${COLUMN_PREFIXES.SEGMENT}${segmentDetailIndex}`;
                this[segmentFieldName] = segmentDetail.channelSegmentation;
    
                segmentDetail.productSegmentations.forEach((productSegmentation, productSegmentationIndex) => {
                    const productFieldName = `${COLUMN_PREFIXES.SEGMENT}${segmentDetailIndex}_${productSegmentationIndex}`;
                    this[productFieldName] = productSegmentation;
                });
            });
        }
    }

    nullifySegmentFields(segmentMetadata) {
        segmentMetadata.forEach((channel, channelIndex) => {
            const segmentFieldName = `${COLUMN_PREFIXES.SEGMENT}${channelIndex}`;
            this[segmentFieldName] = '';

            channel.products.forEach((_, productIndex) => {
                const productFieldName = `${COLUMN_PREFIXES.SEGMENT}${channelIndex}_${productIndex}`;
                this[productFieldName] = '';
            });
        });
    }

    static async _populateMessageMaps(messageService) {
        if (!AccountRecord._typeMessageMap) {
            await this._setTypeMessageMap(messageService);
        }

        if (!AccountRecord._statusMessageMap) {
            await AccountRecord._setStatusMessageMap(messageService);
        }

        if (!AccountRecord._actionsMessageMap) {
            await AccountRecord._setActionsMessageMap(messageService);
        }
    }

    static async _setTypeMessageMap(messageService) {
        const [addAccountMsg, addTargetMsg, removeAccountMsg, removeTargetMsg, editGoalMsg, keepAccountMsg] = await Promise.all([
            messageService.getMessageWithDefault('ADD_ACCOUNT', 'Feedback', 'Add Account'),
            messageService.getMessageWithDefault('ADD_TARGET_1', 'Feedback', 'Add Target'),
            messageService.getMessageWithDefault('REMOVE_ACCOUNT', 'Feedback', 'Remove Account'),
            messageService.getMessageWithDefault('REMOVE_TARGET_1', 'Feedback', 'Remove Target'),
            messageService.getMessageWithDefault('EDIT_GOAL', 'Feedback', 'Edit Goal'),
            messageService.getMessageWithDefault('KEEP_ACCOUNT', 'Feedback', 'Keep Account')
        ]);

        AccountRecord._typeMessageMap = new Map([
            [CHALLENGE_TYPES.ADD_ACCOUNT, addAccountMsg],
            [CHALLENGE_TYPES.ADD_TARGET, addTargetMsg],
            [CHALLENGE_TYPES.REMOVE_ACCOUNT, removeAccountMsg],
            [CHALLENGE_TYPES.REMOVE_TARGET, removeTargetMsg],
            [CHALLENGE_TYPES.EDIT_GOAL, editGoalMsg],
            [CHALLENGE_TYPES.KEEP_ACCOUNT, keepAccountMsg],
            [CHALLENGE_TYPES.GOAL_EDIT, editGoalMsg]
        ]);
    }

    static async _setStatusMessageMap(messageService) {
        const [approvedMsg, rejectedMsg, pendingMsg] = await Promise.all([
            messageService.getMessageWithDefault('APPROVED', 'Feedback', 'Approved'),
            messageService.getMessageWithDefault('REJECTED', 'Feedback', 'Rejected'),
            messageService.getMessageWithDefault('PENDING', 'Feedback', 'Pending')
        ]);

        AccountRecord._statusMessageMap = new Map([
            [CHALLENGE_STATUSES.APPROVED, approvedMsg],
            [CHALLENGE_STATUSES.REJECTED, rejectedMsg],
            [CHALLENGE_STATUSES.CHALLENGED, pendingMsg]
        ]);
    }

    static async _setActionsMessageMap(messageService) {
        const [approveMsg, addAccountOnlyMsg, keepAccountOnlyMsg, removeTargetOnlyMsg, rejectMsg] = await Promise.all([
            messageService.getMessageWithDefault('APPROVE', 'Common', 'Approve'),
            messageService.getMessageWithDefault('APPROVE_ADD_ACCOUNT_ONLY', 'Feedback', 'Approve "Add Account" Only'),
            messageService.getMessageWithDefault('APPROVE_KEEP_ACCOUNT_ONLY', 'Feedback', 'Approve "Keep Account" Only'),
            messageService.getMessageWithDefault('APPROVE_REMOVE_TARGET_ONLY', 'Feedback', 'Approve "Remove Target" Only'),
            messageService.getMessageWithDefault('REJECT', 'Common', 'Reject')
        ]);

        AccountRecord._actionsMessageMap = new Map([
            [AccountsPageCommandFactory.APPROVE, approveMsg],
            [AccountsPageCommandFactory.APPROVE_ADD_ACCOUNT_ONLY, addAccountOnlyMsg],
            [AccountsPageCommandFactory.APPROVE_KEEP_ACCOUNT_ONLY, keepAccountOnlyMsg],
            [AccountsPageCommandFactory.APPROVE_REMOVE_TARGET_ONLY, removeTargetOnlyMsg],
            [AccountsPageCommandFactory.REJECT, rejectMsg]
        ]);
    }
}