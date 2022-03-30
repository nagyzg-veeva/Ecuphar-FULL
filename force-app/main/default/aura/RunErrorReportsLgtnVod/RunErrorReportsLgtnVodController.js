({
    doInit: function(component) {
        var action = component.get("c.getDataMapList");
        action.setParams({ analyticFileId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var checkboxList = [];
            var reportList = [{ id: "Zip_vod__c", label: "Zip Error Report", shortId: "ziprpt" }, { id: "Brick_vod__c", label: "Brick Error Report", shortId: "brkrpt" },
                { id: "Data_Channel_vod__c", label: "Data Channel Error Report", shortId: "dtcl" }, { id: "Market_vod__c", label: "Market Error Report", shortId: "mktrpt" },
                { id: "Payer_Id_vod__c", label: "Payer Error Report", shortId: "pyrrpt" }, { id: "Product_Group_vod__c", label: "Product Error Report", shortId: "prdrpt" },
                { id: "Territory_Name_vod__c", label: "Territory Error Report", shortId: "terrpt" }
            ];
            if (state === "SUCCESS") {
                var retMap = response.getReturnValue();

                if ("Id_vod__c" in retMap) {
                    checkboxList.push({label: "Account Error Report", value: "actrpt" });
                    checkboxList.push({label: "Control Totals Report", value: "ctlrpt"});
                }
                for (var i = 0; i < reportList.length; i++) {
                    if (reportList[i].id in retMap) {
                        checkboxList.push({label: reportList[i].label, value: reportList[i].shortId});
                    }
                }
                component.set('v.checkboxList', checkboxList);
            }
        });
        $A.enqueueAction(action);
    },
    handleRunClick: function(component, event, helper) {
        var reportsCheckboxGroup = component.find("reportsCheckboxGroup");
        var selectedReports = reportsCheckboxGroup.get("v.value");
        if (reportsCheckboxGroup.reportValidity()) {
            var action = component.get("c.getAnalyticsFile");
            action.setParams({ analyticFileId: component.get("v.recordId") });
            action.setCallback(this, function(response) {
                var analyticsFile = response.getReturnValue();
                var action2 = component.get("c.getVodInfo");
                action2.setCallback(this, function(response) {
                    helper.runReport(selectedReports, analyticsFile, response.getReturnValue());
                    $A.get("e.force:closeQuickAction").fire();
                });
                $A.enqueueAction(action2);
            });
            $A.enqueueAction(action);
        }
    },
    handleCancelClick: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})