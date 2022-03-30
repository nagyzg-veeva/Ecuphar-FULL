({
    init : function(component, event, helper) {
        var id = component.get("v.recordId");
        helper.checkPermissions(component, id);
    }
})