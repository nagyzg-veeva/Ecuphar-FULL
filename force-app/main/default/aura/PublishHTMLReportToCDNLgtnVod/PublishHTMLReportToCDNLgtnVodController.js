({
    init: function(component) {
        var action = component.get("c.getMessage");
        action.setCallback(this, function(response) {
             component.set("v.spinner", false); 
             component.set('v.message', response.getReturnValue());
        });
        var action2 = component.get("c.publishToCDN");
        action2.setParams({htmlReportId: component.get("v.recordId")});
    	$A.enqueueAction(action);
        $A.enqueueAction(action2);
    },
	handleCancelClick : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})