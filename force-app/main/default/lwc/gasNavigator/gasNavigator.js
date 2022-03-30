import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class GasNavigator extends NavigationMixin(LightningElement) {

    @api
    navigateToNewAccountWizard() {
        this.navigateToUrl('/apex/NewAccountWithRecordTypeLgtnVod');
    }

    @api
    navigateToViewAccount(accountId) {
        this.navigateToRecordPage('view', 'Account', accountId);
    }

    navigateToUrl(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    navigateToRecordPage(actionName, objectApiName, recordId) {
        // References https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.reference_page_reference_type
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                actionName: actionName,
                recordId: recordId,
                objectApiName: objectApiName
            }
        });
    }
}