import { LightningElement, api } from 'lwc';

export default class TerritoryFeedbackModal extends LightningElement {
    modalType;
    modalTitle;
    modalMessages;

    get displayModal() {
        return this.showConfirmationModal || this.showPendingChallengesModal;
    }

    get showConfirmationModal() {
        return this.modalType === 'confirmation';
    }

    get showPendingChallengesModal() {
        return this.modalType === 'pendingChallenges' || this.modalType === 'pendingChallengesWithReview';
    }

    get showReviewButton() {
        return this.modalType === 'pendingChallengesWithReview';
    }

    async connectedCallback() {
        await this.loadVeevaMessages();
    }

    @api messageService;

    @api
    showModal(modalConfig) {
        ({type: this.modalType, title: this.modalTitle, body: this.modalMessages} = modalConfig);
    }

    @api
    clearModal() {
        this.modalType = this.modalTitle = this.modalMessages = null;
    }

    handleConfirmCommand(event) {
        this.dispatchEvent(new CustomEvent('confirm', {
            detail: {
                selectedButton: event.target.name
            }
        }));
    }

    handleCancelCommand() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    async loadVeevaMessages() {
        [this.yesMessage, this.noMessage, this.cancelMessage, this.approveAllMessage, this.rejectAllMessage, this.reviewMessage] = await Promise.all([
            this.messageService.getMessageWithDefault('YES', 'Common', 'Yes'),
            this.messageService.getMessageWithDefault('NO', 'Common', 'No'),
            this.messageService.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
            this.messageService.getMessageWithDefault('APPROVE_ALL', 'Feedback', 'Approve All'),
            this.messageService.getMessageWithDefault('REJECT_ALL', 'Feedback', 'Reject All'),
            this.messageService.getMessageWithDefault('REVIEW', 'Feedback', 'Review')
        ]);
    }
}