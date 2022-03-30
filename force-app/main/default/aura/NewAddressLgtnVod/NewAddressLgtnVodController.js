({
    render: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var actionHasDCRForAccountNewAddress = component.get('c.hasDCRForAccount');
        var navService = component.find("navService");
        var vodService = component.find("vodService");
        var pageRef = component.get("v.pageReference");
        var currentPageReference = vodService.getCurrentPageReference(pageRef, recordId);
        var accountRecordId = currentPageReference.attributes.recordId;
        var objectInformation = {
            objectApiName: pageRef.attributes.objectApiName,
            recordTypeId: vodService.getRecordTypeId(pageRef)
        };
        actionHasDCRForAccountNewAddress.setParams({
            accountId: accountRecordId,
            auraComp: true
        })
        actionHasDCRForAccountNewAddress.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                if (response.getReturnValue()) {
                    //DCR Enabled, redirect to Address DCR VF page
                    var newDCRUrl = "/apex/New_Address_DCR_vod?id=" + accountRecordId;
                    if (objectInformation.recordTypeId) {
                        newDCRUrl += "&RecordType=" + objectInformation.recordTypeId;
                    }
                    vodService.navigateToURLWithCurrentPageReference(newDCRUrl, navService, currentPageReference);
                } else {
                    //DCR Not Enabled, redirect to Standard New page
                    var defaultFieldValues;
                    if (accountRecordId) {
                        defaultFieldValues = {
                            Account_vod__c: accountRecordId
                        };
                    }
                    vodService.redirectToLgtnNewWithCurrentPageReference(navService, currentPageReference, objectInformation, defaultFieldValues);
                }
            } else if (response.getState() == "ERROR") {
                vodService.showErrorToast(response);
            }
        });

        $A.enqueueAction(actionHasDCRForAccountNewAddress);
    }
})