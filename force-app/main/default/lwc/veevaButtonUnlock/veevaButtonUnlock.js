import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import VeevaToastEvent from 'c/veevaToastEvent';

export default class VeevaButtonUnlock extends NavigationMixin(LightningElement) {
    @api pageCtrl;
    @api meta;
    @track label;

    async connectedCallback() {
        this.label = await this.pageCtrl.getMessageWithDefault('UNLOCK', 'Common', 'Unlock');
    }

    handleClick() {
        this.pageCtrl.unlock().then(() => {
                // only redirect to another page reference if defined in child pageController,
                // otherwise rely on new wired object details to update the page
                let pageRef = this.pageCtrl.getPageRefForUnlock();
                if (pageRef) {
                    this[NavigationMixin.Navigate](pageRef);
                }
            }) 
            .catch(error => {
                let message = error;
                if (error.recordErrors && error.recordErrors.length > 0){
                    message = error.recordErrors[0];
                }
                this.dispatchEvent(VeevaToastEvent.error({ message }));
            });
    }

    get isMenu() {
        return this.meta.menu;
    }
}