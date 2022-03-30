({  
    startFlow: function(component, flowComponent) {
        const flowName = component.get('v.flowName');
        if (flowComponent && flowName) {
            const flow = component.find('flow');
            const vars = component.get('v.flowVariables');
            if (vars) {
                flowComponent.startFlow(flowName, vars);
            } else {
                flowComponent.startFlow(flowName);
            }
        }
    },
    processMessageParams : function(component, message) {
        ['flowName', 'flowVariables', 'inContextOfRef'].forEach(param => {
            const paramVal = message.getParam(param);
            if (paramVal) {
                component.set(`v.${param}`, paramVal);
            }
        });
    },
    getPageRefUrl : function(pageRef) {
        let url = '';
        let params = ''
        if (pageRef) {
            if (pageRef.type === 'standard__recordPage') {
                const attrs = pageRef.attributes;
                url = `${url}lightning/r/${attrs.objectApiName}/${attrs.recordId}/${attrs.actionName}`;
            }
            if (pageRef.state) {
                for (const param in pageRef.state) {
                    if (pageRef.state.hasOwnProperty(param)) {
                        params = `${params}${param}=${pageRef.state[param]}&`
                    }
                }
            }
        }
        return `/${url}?${params}`;
    },
    showErrorToast: function(component, errorItem) {
        const messageAction = component.get('c.getMsgWithDefault');
        messageAction.setParams({ 
            key : 'CHILD_CALL_ERROR',
            category: 'CallReport',
            defaultMessage: 'There are errors for {0}'
        });
        action.setCallback(this, function(response) {
            let errorMessage = 'There are errors for {0}';
            var state = response.getState();
            if (state === "SUCCESS") {
                errorMessage = response.getReturnValue();
            } else if (state === "INCOMPLETE") {
                console.warn('Error Veeva Message request incomplete; using default');
            } else if (state === "ERROR") {
                console.warn(`Error Veeva Message request failed; using default. Reason: ${response.getError()}`);
            }
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": errorMessage.replace('{0}', errorItem)
            });
            toastEvent.fire();
        });
    },
    getFlowName: function(component) {
        const pageRef = component.get('v.pageReference');
        let flowName = component.get('v.flowName');
        if (!flowName && pageRef && pageRef.state) {
            flowName = pageRef.state.c__flowName;
        }
        return flowName;
    },
    getFlowVariables: function(component) {
        const pageRef = component.get('v.pageReference');
        let flowVariables = component.get('v.flowVariables');
        if (!flowVariables && pageRef && pageRef.state) {
            flowVariables = JSON.parse(pageRef.state.c__flowVariables);
            const defaultFieldValues = flowVariables.find(variable => variable.name === "defaultFieldValues");
            if (defaultFieldValues) {
                // We will pass defaultFieldValues to a Lightning flow so we will need to make it a string
                defaultFieldValues.value = JSON.stringify(defaultFieldValues.value);
            }
        }
        return flowVariables;
    },
    getInContextOfRefFromState: function(component) {
        const pageRef = component.get('v.pageReference');
        if (pageRef && pageRef.state && pageRef.state.c__inContextOfRef) {
            return JSON.parse(pageRef.state.c__inContextOfRef)
        } else {
            return null;
        }
    }
})