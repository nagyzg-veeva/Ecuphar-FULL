({
    render: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var actionHasDCRForAddress = component.get('c.hasDCRForAddress');
        var navService = component.find("navService");
        var vodService = component.find("vodService");
        var pageRef = component.get("v.pageReference");
        var currentPageReference = vodService.getCurrentPageReference(pageRef, recordId);
        var recordTypeId = vodService.getRecordTypeId(pageRef);
        actionHasDCRForAddress.setParams({
            addressId: recordId,
            auraComp: true
        })
        actionHasDCRForAddress.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                if (response.getReturnValue()) {
                    //DCR Enabled, redirect to Address DCR VF page
                    var editDCRUrl = "/apex/Edit_Address_DCR_vod?id=" + recordId;
                    if (recordTypeId) {
                        editDCRUrl += "&RecordType=" + recordTypeId;
                    }
                    vodService.navigateToURLWithCurrentPageReference(editDCRUrl, navService, currentPageReference);
                } else {
                    //DCR Not Enabled, redirect to Standard Edit page
                    vodService.redirectToLgtnEditWithCurrentPageReference(navService, currentPageReference, recordId, recordTypeId);
                }
            } else if (response.getState() == "ERROR") {
                vodService.showErrorToast(response);
            }
        });

        $A.enqueueAction(actionHasDCRForAddress);
    }
})