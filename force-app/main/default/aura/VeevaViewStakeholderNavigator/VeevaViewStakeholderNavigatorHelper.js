({
    checkPermissions : function(component, id) {
        var action = component.get("c.checkPermissions");
        action.setParam("id", id);
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var errorMessage = response.getReturnValue();
                if (errorMessage === "") {
                    this.redirectToStakeholderNavigator(component, id);
                } else {
                    component.set("v.errorMessage", errorMessage);
                }
            }
            else {
                var errors = response.getError();
                if (errors[0] && errors[0].message)
                component.set("v.errorMessage", errors[0].message);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    redirectToStakeholderNavigator : function(component, id) {
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__VeevaStakeholderNavigatorCmp',
            },
            state: {
                "c__id": id
            }
        };
        var navService = component.find("navService");
        navService.navigate(pageReference);
    }
})