import { LightningElement, wire } from 'lwc';
import { getPageController } from 'c/veevaPageControllerFactory';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import GasImplicitFilterAccess from 'c/gasImplicitFilterAccess';
import IMPLICIT_FILTER_OBJECT from '@salesforce/schema/Implicit_Filter_vod__c';
import IMPLICIT_FILTER_CONDITION_OBJECT from '@salesforce/schema/Implicit_Filter_Condition_vod__c';

export default class GlobalAccountSearchAdminTab extends LightningElement {

    objectNames = [IMPLICIT_FILTER_OBJECT, IMPLICIT_FILTER_CONDITION_OBJECT];
    implicitFiltersVisible = false;
    accessDenied = false;

    title = 'Global Account Search Configuration';
    accessDeniedLabel = 'Access Denied';

    @wire(getObjectInfos, { objectApiNames: '$objectNames' })
    wiredObjectInfos({ error, data }) {
        if (data) {
            const objectInfos = data.results;
            const implicitFilterObjectInfo = objectInfos[0].result;
            const implicitFilterConditionObjectInfo = objectInfos[1].result;
            this.implicitFiltersVisible = this.isAbleToViewImplicitFilters(implicitFilterObjectInfo, implicitFilterConditionObjectInfo);
            this.accessDenied = !this.implicitFiltersVisible;
        } else if (error) {
            this.setError(error);
        }
    }

    async connectedCallback() {
        const veevaMessageService = getPageController('messageSvc');
        await this.loadVeevaMessages(veevaMessageService);
    }

    async loadVeevaMessages(veevaMessageService) {
        [this.title, this.accessDeniedLabel] = await Promise.all([
            veevaMessageService.getMessageWithDefault('GAS_CONFIGURATION', 'Global Account Search', this.title),
            veevaMessageService.getMessageWithDefault('ACCESS_DENIED', 'Common', this.accessDeniedLabel)
        ]);
    }

    isAbleToViewImplicitFilters(implicitFilterObjectInfo, implicitFilterConditionObjectInfo) {
        return GasImplicitFilterAccess.hasImplicitFilterAccess(implicitFilterObjectInfo, implicitFilterConditionObjectInfo);
    }

    setError(e){
        const errMsg = (e.body && e.body.message) ? e.body.message : this.errorMessage;
        const error = { message: errMsg};
        this.dispatchEvent(VeevaToastEvent.error(error, "sticky"));
    }
}