({
    navigateToURL: function(url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    navigateToURLWithCurrentPageReference: function(url, navService, currentPageRef) {
        //by navigating to the current page reference first, any window.back navigation
        //is preserved on the next page
        navService.navigate(currentPageRef);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    redirectToLgtnEdit: function(navService, recordId, recordTypeId) {
        //navigate to a standard edit modal with background context as the view page of the same object
        var viewPageReference = this.createEditPageReference("view", recordId);
        var editPageReference = this.createEditPageReference("edit", recordId, recordTypeId);
        this.doRedirectWithBackgroundContext(navService, editPageReference, viewPageReference);
    },
    redirectToLgtnEditWithCurrentPageReference: function(navService, currentPageRef, recordId, recordTypeId) {
        //navigate to a standard edit modal with the background context set by currentPageRef
        var editPageReference = this.createEditPageReference("edit", recordId, recordTypeId);
        this.doRedirectWithBackgroundContext(navService, editPageReference, currentPageRef);
    },
    redirectToLgtnNewWithCurrentPageReference: function(navService, currentPageRef, objectInformation, defaultFieldValues, component) {
        //navigate to a standard record creation modal with the background context set by currentPageRef
        var newPageReference = this.createNewPageReference("new", objectInformation, defaultFieldValues, component);
        this.doRedirectWithBackgroundContext(navService, newPageReference, currentPageRef);
    },
    doRedirectWithBackgroundContext: function(navService, editPageReference, backgroundReference) {
        //the only way to get an edit modal with the correct backgroundContext
        // is to use this iframe redirect "trick"
        Promise.all([navService.generateUrl(backgroundReference), navService.generateUrl(editPageReference)])
            .then(values => {
                var backgroundReferenceUrl = values[0];
                var editPageRefUrl = values[1];
                var baseUrl = document.location.origin;
                var editUrlWithBackgroundContext = baseUrl + editPageRefUrl + "&backgroundContext=" +  encodeURIComponent(backgroundReferenceUrl);
                var frame = document.createElement("iframe");
                frame.src = editUrlWithBackgroundContext;
                document.body.appendChild(frame);
            });
    },
    showErrorToast: function(response) {
        var errorMsg = response.getError()[0].message;
        var toastParams = {
            title: "Error",
            message: errorMsg, // Default error message
            type: "error"
        };
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
        var closeEvent = $A.get("e.force:closeQuickAction");
        closeEvent.fire();
    },
    getCurrentPageReference: function(pageRef, recordId) {
        var currentPageReference = this.getPageReferenceFromState(pageRef);
        if (currentPageReference == null) {
            //fallback case: use View page reference
            currentPageReference = this.createEditPageReference("view", recordId);
        }
        return currentPageReference;
    },
    getRecordTypeId: function(pageRef) {
        var recordTypeId = null;
        if (pageRef && pageRef.state && pageRef.state.recordTypeId) {
            recordTypeId = pageRef.state.recordTypeId;
        }
        return recordTypeId;
    },
    //Create Page References documentation: https://developer.salesforce.com/docs/atlas.en-us.232.0.lightning.meta/lightning/components_navigation_page_definitions.htm
    createEditPageReference: function(mode, recordId, recordTypeId) {
        var pageReference = {
            "type": "standard__recordPage",
            "attributes": {
                "recordId": recordId,
                "actionName": mode
            },
            "state":{
                "nooverride":"1"
            }
        };
        if (recordTypeId) {
            pageReference.state.recordTypeId = recordTypeId;
        }
        return pageReference;
    },
    createNewPageReference: function(mode, objectInformation, defaultFieldValues, component) {
        var pageReference = {
            "type": "standard__objectPage",
            "attributes": {
                "objectApiName": objectInformation.objectApiName,
                "actionName": mode,
            },
            "state":{
                "nooverride": "1"
            }
        };
        pageReference.state.defaultFieldValues = component.find("pageRefUtils").encodeDefaultFieldValues(defaultFieldValues);
        if (objectInformation.recordTypeId) {
            pageReference.state.recordTypeId = objectInformation.recordTypeId;
        }
        return pageReference;
    },
    getPageReferenceFromState: function(pageRef) {
        //get page reference from the state of another page reference
        var stateReference = null;
        if (pageRef != null) {
            var state = pageRef.state; // state holds any query params
            var base64Context = state.inContextOfRef;
            if (base64Context) {
                // ignore the first two characters "1.<rest>"
                // then we can get the original page reference if it exists
                stateReference = JSON.parse(atob(base64Context.substring(2)));
            }
        }
        return stateReference;
    }
})