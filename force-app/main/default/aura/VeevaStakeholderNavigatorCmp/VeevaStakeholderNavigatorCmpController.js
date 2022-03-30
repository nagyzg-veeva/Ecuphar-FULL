({
    handleMessage: function(component, message, helper) {
        helper.handleMessage(component, message);
    },
    toggleAffiliations : function(component, event, helper) {
        helper.sendMessage(component, "toggleAffiliations", {});
    },
    onPageReferenceChange: function(component, event, helper) {
        var newPageRef = component.get("v.pageReference");
        if (newPageRef.state.c__id !== component.get("v.rootId")) {
            $A.get('e.force:refreshView').fire();
        }
    },
    init: function(component, event, helper) {
    	var myPageRef = component.get("v.pageReference");
    	var id = myPageRef.state.c__id;
    	component.set("v.rootId", id);
	}
})