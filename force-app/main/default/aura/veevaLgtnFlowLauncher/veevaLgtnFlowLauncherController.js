({
	doInit : function(component, event, helper) {
        helper.startFlow(component, component.find('flow'));
    },

    handleMessage : function(component, message, helper) {
        helper.processMessageParams(component, message);
        const flowName = message.getParam('flowName');
        if (flowName) {
            $A.createComponent(
                "lightning:flow",
                {
                    "aura:id": "messageFlow",
                    "onstatuschange": component.getReference("c.handleFlowStatusChange")
                },
                function(flowComponent, status, errorMessage){
                    if (status === "SUCCESS") {
                        const body = component.get("v.body");
                        body.push(flowComponent);
                        component.set("v.body", body);
                        
                        helper.startFlow(component, flowComponent);
                    } else if (status === "INCOMPLETE") {
                        helper.showErrorToast(component, 'messageFlow');
                        console.warn(`flow creation was incomplete: ${errorMessage}`);
                    } else if (status === "ERROR") {
                        helper.showErrorToast(component, 'messageFlow');
                        console.error(`Flow Creation Error: ${errorMessage}`);
                    }
                }
            )
        }
    },

	handleFlowStatusChange : function(component, event, helper) {
        if (event.getParam('status') === "FINISHED") {
            const componentInContextOfRef =  component.get('v.inContextOfRef');
            const navService = component.find("navService");
            if (componentInContextOfRef) {
                if (typeof sforce !== 'undefined' && sforce.one) {
                    sforce.one.navigateToURL(helper.getPageRefUrl(componentInContextOfRef));
                } else {
                    navService.navigate(componentInContextOfRef);
                }
            }
            
            const msgFlow = component.find('messageFlow');
            // It's also possible that we have inContextOfRef set in our state
            const stateInContextOfRef = helper.getInContextOfRefFromState(component);
            if (!componentInContextOfRef && stateInContextOfRef) {
                navService.navigate(stateInContextOfRef, true);
            } else if (msgFlow) {
                msgFlow.destroy();
            } else {
                // We cannot destroy component when we navigate to this Aura Component from a LWC.
                // This is because the component does not get re-initialized when the user cancels
                // and navigates back to this component. Only a LWC will set pageReference.state.c__inContextOfRef
                // so we can destroy the component in other cases.
                component.destroy();
            }
        }
    }
})