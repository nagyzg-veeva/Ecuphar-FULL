({
    setNewPageProperties: function(component) {
        setPageReference(component);
        setObjectApiName(component);

        function setPageReference(component) {
            let refToSet;
            
            const origRef = component.get('v.pageReference');
            if (!origRef) {
                refToSet = {
                    "attributes": {
                        "objectApiName": component.get('v.objectApiName'),
                        "actionName": "new"
                    },
                    "state": {
                        "recordTypeId": component.get('v.rtId'),
                        "defaultFieldValues": component.get('v.defaultFieldValues')
                    }
                };
                let inContextOfRef = component.get('v.inContextOfRef');
                if (!inContextOfRef) {
                    const flowContext = component.get('v.flowContext');
                    if (flowContext && typeof flowContext === 'string') {
                        inContextOfRef = JSON.parse(flowContext);
                    }
                }
                if (inContextOfRef) {
                    refToSet.state.inContextOfRef = inContextOfRef;
                }
            } else if (origRef.type === 'standard__component') {
                const clonedRef = JSON.parse(JSON.stringify(origRef));
                clonedRef.actionName = 'new';
                const clonedState = clonedRef.state;
                if (clonedState) {
                    if (clonedState.c__objectApiName) {
                        clonedRef.attributes.objectApiName = clonedState.c__objectApiName;
                        delete clonedState.c__objectApiName;
                    }
                    if (clonedState.c__inContextOfRef){
                        let clonedContext = clonedState.c__inContextOfRef;
                        if(typeof clonedContext === 'string'){
                            try {
                                clonedContext = JSON.parse(clonedContext);
                            } catch (e) {
                                console.log('could not parse inContextOfRef; using raw value instead');
                            }
                        }
                        clonedState.inContextOfRef = clonedContext;

                        delete clonedState.c__inContextOfRef;
                    }
                    ['rtId', 'defaultFieldValues', 'inContextOfRef'].forEach(attr => {
                        if (clonedState[`c__${attr}`]) {
                            clonedState[attr] = clonedState[`c__${attr}`];
                            delete clonedState[`c__${attr}`];
                        }
                    });
                }
                refToSet = clonedRef;    
            }
            if (refToSet) {
                component.set('v.pageRefSetInternally', true);
                component.set('v.pageReference', refToSet);
            }
        }

        function setObjectApiName(component) {
            if (!component.get('v.objectApiName')) {
                const pageRef = component.get('v.pageReference');
                if (pageRef && pageRef.attributes) {
                    component.set('v.objectApiName', pageRef.attributes.objectApiName);
                }
            }
        }
    },

    getPageRefUrl : function(pageRef) {
        let url = '';
        let params = ''
        if (pageRef) {
            if (pageRef.type === 'standard__recordPage') {
                const attrs = pageRef.attributes;
                url = `${url}lightning/r/${attrs.objectApiName}/${attrs.recordId}/${attrs.actionName}`;
            } else if (pageRef.type === 'standard__objectPage') {
                const attrs = pageRef.attributes;
                url = `${url}lightning/o/${attrs.objectApiName}/${attrs.actionName}`;
            } else if (pageRef.type === 'standard__component') {
                const attrs = pageRef.attributes;
                url = `${url}lightning/cmp/${attrs.componentName}`;
            }
            if (pageRef.state) {
                for (const param in pageRef.state) {
                    if (pageRef.state.hasOwnProperty(param)) {
                        if(typeof pageRef.state[param] ==='object'){
                            params = `${params}${param}=${JSON.stringify(pageRef.state[param])}&`
                        } else {
                            params = `${params}${param}=${pageRef.state[param]}&`
                        }
                        
                    }
                }
            }
        }
        return `/${url}?${params}`;
    },

    shouldSkipFlowNavigation : function(pageRef) {
        let shouldSkipFlowNavigation = false;

        if (pageRef.type === 'standard__recordPage') {
            // skip flow navigation if we specified a record to navigate to
            shouldSkipFlowNavigation = true;
        } else if (pageRef.type === 'standard__objectPage' && pageRef.attributes.actionName === 'new') {
            // skio flow navigation if we are creating another record.
            shouldSkipFlowNavigation = true;
        }

        return shouldSkipFlowNavigation;
    }
})