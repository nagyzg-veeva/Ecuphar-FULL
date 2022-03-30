({
    refreshView: function (component, event) {
        // console.log("refresh");
        $A.get("e.force:refreshView").fire();
    }
});