import { LightningElement, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { MessageContext, subscribe, unsubscribe } from "lightning/messageService";
import myInsightsNavigationChannel from "@salesforce/messageChannel/MyInsights_Navigation__c";


export default class MyInsightsLightningNavigator extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference)
    pageReference;

    @wire(MessageContext)
    messageContext;

    subscription;

    connectedCallback() {
        this.subscribeToNavigationChannel();
    }

    disconnectedCallback() {
        this.unsubscribeFromNavigationChannel();
    }

    subscribeToNavigationChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                myInsightsNavigationChannel,
                (message) => this.handleNavigationMessage(message)
            )
        }
    }

    unsubscribeFromNavigationChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleNavigationMessage(message) {
        if (message.viewRecord) {
            this.navigateToViewRecordPage(message.viewRecord);
        } else if (message.urlInfo) {
            this.navigateToUrl(message.urlInfo);
        } else if (message.recordTypeSelector) {
            this.navigateToRecordTypeSelector(message.recordTypeSelector);
        }
    }

    navigateToViewRecordPage(viewRecordPageInfo) {
        const { object, recordId } = viewRecordPageInfo;
        if (object && recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: object,
                    actionName: "view",
                    recordId: recordId
                }
            });
        }
    }

    navigateToUrl(urlInfo) {
        const { url } = urlInfo;
        if (url) {
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: url
                }
            });
        }
    }

    async navigateToRecordTypeSelector(recordTypeSelector) {
        const { object, fields } = recordTypeSelector;
        if (object) {
            const pageRefState = {
                c__flowName: "VeevaRecordTypeSelectorFlow",
                c__flowVariables: JSON.stringify(this.createFlowVariables(object, fields)),
                c__inContextOfRef: JSON.stringify(this.pageReference)
            };

            this[NavigationMixin.Navigate]({
                type: "standard__component",
                attributes: {
                    componentName: "c__veevaLgtnFlowLauncher"
                },
                state: pageRefState
            });
        }
    }

    createFlowVariables(object, fields) {
        const flowVariables = [{
            name: "objectApiName",
            value: object,
            type: "String"
        }];
        if (fields) {
            flowVariables.push({
                name: "defaultFieldValues",
                value: this.formatFields(fields),
                type: "String"
            });
        }
        return flowVariables;
    }

    formatFields(fields) {
        const formattedFields = {};
        Object.entries(fields).forEach(([key, value]) => {
            formattedFields[key] = {
                displayValue: null,
                value: value
            };
        });
        return formattedFields;
    }
}