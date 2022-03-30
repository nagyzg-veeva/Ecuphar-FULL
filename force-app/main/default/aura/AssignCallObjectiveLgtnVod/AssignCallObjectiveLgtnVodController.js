({
    doInit: function(component) {
        var action = component.get("c.getObjectives");
        action.setParams({ tacticId: component.get("v.recordId")});
        action.setCallback(this, function(response) {
            component.set('v.objectiveList', response.getReturnValue() );
            component.set('v.displayObjectiveList', response.getReturnValue() );
        });
        var action2 = component.get("c.getFieldNames");
        action2.setCallback(this, function(response) {
            console.log(response.getReturnValue());
            component.set('v.fieldNames', response.getReturnValue() );
        });
        $A.enqueueAction(action);
        $A.enqueueAction(action2);
    },

    assignToTactic: function(component, event, helper) {
        var idx = event.target.id;
        var action = component.get("c.assignToObjective");
        action.setParams({ tacticId: component.get("v.recordId"), objectiveId: idx });
        action.setCallback(this, function(response) {
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
    },

    doSearch: function(component, event, helper) {
        var searchText = component.get('v.searchText');
        var fullList = component.get('v.objectiveList');
        if (!searchText) {
            // display all values, need a backup copy of all values
            component.set('v.displayObjectiveList', fullList );
        } else {
            // case insensitive filter
            var newDisplayList = [];
            for (var i = 0; i < fullList.length; i++) {
                if (fullList[i].Name_vod__c.toLowerCase().indexOf(searchText.toLowerCase()) > -1) {
                    newDisplayList.push(fullList[i]);
                }
            }
            component.set('v.displayObjectiveList', newDisplayList);
        }
    },

    handleCancelClick: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})