({
    navigateToURL: function(component, event, helper) {
        var params = event.getParams().arguments;
        helper.navigateToURL(params.url);
    },
    navigateToURLWithCurrentPageReference: function(component, event, helper) {
        var params = event.getParams().arguments;
        helper.navigateToURLWithCurrentPageReference(params.url, params.navService, params.currentPageRef);
    },
    redirectToLgtnEdit: function(component, event, helper) {
        var params = event.getParams().arguments;
        helper.redirectToLgtnEdit(params.navService, params.recordId, params.recordTypeId);
    },
    redirectToLgtnEditWithCurrentPageReference: function(component, event, helper) {
        var params = event.getParams().arguments;
        helper.redirectToLgtnEditWithCurrentPageReference(params.navService, params.currentPageRef, params.recordId, params.recordTypeId);
    },
    redirectToLgtnNewWithCurrentPageReference: function(component, event, helper) {
        var params = event.getParams().arguments;
        helper.redirectToLgtnNewWithCurrentPageReference(params.navService, params.currentPageRef, params.objectInformation, params.defaultFieldValues, component);
    },
    showErrorToast: function(component, event, helper) {
        var params = event.getParams().arguments;
        helper.showErrorToast(params.response);
    },
    getCurrentPageReference: function(component, event, helper) {
        var params = event.getParams().arguments;
        return helper.getCurrentPageReference(params.pageRef, params.recordId);
    },
    getRecordTypeId: function(component, event, helper) {
        var params = event.getParams().arguments;
        return helper.getRecordTypeId(params.pageRef);
    }
})