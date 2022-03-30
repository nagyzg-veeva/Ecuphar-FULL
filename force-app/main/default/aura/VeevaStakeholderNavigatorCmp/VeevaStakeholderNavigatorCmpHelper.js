({
    handleMessage: function(component, message) {     
        var params = message.getParams();
        if (!params) {
            return;
        }
        var payload = params.payload;
        var command = payload.command;

        switch(command) {
            case "initGraph":
                this.initializeGraph(component, component.get("v.pageReference").state.c__id);
                break;

            case "redirect":
                var page = payload.page;
                var id = payload.id;
                if (page === "timeline") {
                    this.redirectToTimeline(id);
                } else if (page === "detail") {
                    this.redirectToAccountDetail(id);
                }
                break;

            case "loadInitialHierarchy":
                this.loadInitialHierarchy(component, payload.rootId);
                break;

            case "loadHierarchy":
                this.loadHierarchy(component, payload.ids);
                break;

            case "loadParentHierarchy":
                this.loadParentHierarchy(component, payload.childId);
                break;

            case "loadAccountBatch":
                this.loadAccountBatch(component, payload.batchId, payload.accounts);
                break;

            case "updateNumberAccounts":
                component.set("v.numAcctLoaded", payload.numberAccounts);
                break;

            case "ping":
                this.sendMessage(component, "ping", "");
                break;
        }
    },

    sendMessage : function(component, command, messageToSend) {
        var msg = {
            command: command,
            data: messageToSend
        };
        component.find("NavigatorChart").message(msg);
    },

    initializeGraph : function(component, id) {
        var action = component.get("c.initializeGraph");
        action.setParam("rootId", id);
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                var snMessage = returnValue.veevaMessages.STAKEHOLDER_NAVIGATOR_PAGE_NAME;
                var toggleAffMessage = returnValue.veevaMessages.TOGGLE_AFFILIATIONS;
                if (snMessage) {
                    component.set("v.snMessage", snMessage);
                }
                if (toggleAffMessage) {
                    component.set("v.toggleAffMessage", toggleAffMessage);
                }
                this.sendMessage(component, "initGraph", returnValue);
            }
            else {
                var errors = response.getError();
                //default message in case Salesforce does not provide one
                var errorMessage = "An unexpected error occurred.";
                if (errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                this.sendMessage(component, "error", errorMessage);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    loadInitialHierarchy : function(component, id) {
        var action = component.get("c.loadInitialHierarchy");
        action.setParam("rootId", id);

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                this.sendMessage(component, "loadInitialHierarchy", returnValue);
            }
            else {
                var errors = response.getError();
                //default message in case Salesforce does not provide one
                var errorMessage = "An unexpected error occurred.";
                if (errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                this.sendMessage(component, "error", errorMessage);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    loadHierarchy : function(component, ids) {
        var action = component.get("c.loadHierarchy");
        action.setParam("ids", ids);

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                this.sendMessage(component, "loadHierarchy", returnValue);
            }
            else {
                var errors = response.getError();
                //default message in case Salesforce does not provide one
                var errorMessage = "An unexpected error occurred.";
                if (errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                this.sendMessage(component, "error", errorMessage);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    loadParentHierarchy : function(component, id) {
        var action = component.get("c.loadParentHierarchy");
        action.setParam("childId", id);

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                this.sendMessage(component, "loadParentHierarchy", returnValue);
            }
            else {
                var errors = response.getError();
                //default message in case Salesforce does not provide one
                var errorMessage = "An unexpected error occurred.";
                if (errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                this.sendMessage(component, "error", errorMessage);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    loadAccountBatch : function(component, batchId, accounts) {
        var action = component.get("c.loadAccountBatch");
        action.setParams({"batchId": batchId, "accounts": accounts});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                this.sendMessage(component, "loadAccountBatch", returnValue);
            }
            else {
                var errors = response.getError();
                //default message in case Salesforce does not provide one
                var errorMessage = "An unexpected error occurred.";
                if (errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                this.sendMessage(component, "error", errorMessage);
            }
        });
        $A.getCallback(function() {
            $A.enqueueAction(action);
        })();
    },

    redirectToTimeline: function(id) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/apex/Account_Overview_vod?id=" + id
        });
        urlEvent.fire();
    },

    redirectToAccountDetail: function(id) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": id
        });
        navEvt.fire();
    }
})