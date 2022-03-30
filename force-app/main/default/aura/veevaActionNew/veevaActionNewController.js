({
    doInit: function(component, event, helper) {
        helper.setNewPageProperties(component);
    },

    onPageReferenceChange: function(component, event, helper) {
        if (component.get('v.pageRefSetInternally')) {
            component.set('v.pageRefSetInternally', false);
        } else {
            helper.setNewPageProperties(component);
        }
    },

    handleCloseEvent: function(component, event, helper) {
        const availableActions = component.get('v.availableActions');
        const pageRef = event.getParam('pageRef');
        const useFlowNavAfterNew = event.getParam('useFlowNavAfterNew');
        if ((useFlowNavAfterNew || !helper.shouldSkipFlowNavigation(pageRef))
            && availableActions 
            && availableActions.length) {
            const navigate = component.get('v.navigateFlow');
            if (availableActions.indexOf('NEXT') >= 0) {
                navigate('NEXT');
            } else if (availableActions.indexOf('FINISH') >= 0) {
                navigate('FINISH');
            }
        } else {
            if (typeof(sforce) !== 'undefined' && sforce.one) {
                sforce.one.navigateToURL(helper.getPageRefUrl(pageRef));
            } else {
                var navService = component.find("navService");
                navService.navigate(pageRef);
            }
        }
    },
})