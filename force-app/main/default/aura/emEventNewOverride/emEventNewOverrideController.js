({
    init: function(component) {
        // Find the component which aura:id is "flowData"
        var flow = component.find("flowData");
        var inputVariables = [
            { name: "objectApiName", type: "String", value: "EM_Event_vod__c" }
        ];
        flow.startFlow("VeevaNewEmEventFlow", inputVariables);
    },

    reInit: function(component) {
        if (Number.parseInt(component.get("v.pageReference").state.count) > 1) {
            $A.get("e.force:refreshView").fire();
        }
    },

    handleStatusChange: function(component, event) {
        if (event.getParam("status") === "FINISHED") {
            var result = JSON.parse(
                JSON.stringify(component.get("v.pageReference"))
            );
            // Decode parent context
            var base64Context = result.state.inContextOfRef;
            if (base64Context) {
                if (base64Context.startsWith("1.")) {
                    base64Context = base64Context.substring(2);
                }
                result.state.inContextOfRef = JSON.parse(
                    window.atob(base64Context)
                );
            }
            const inContextOfRef = result.state.inContextOfRef;
            if (inContextOfRef) {
                const navService = component.find("navService");
                navService.navigate(inContextOfRef);
            }
        }
    }
});