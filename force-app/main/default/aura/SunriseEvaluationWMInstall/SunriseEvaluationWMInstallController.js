({
    onNavigateToURL: function(component, event, helper) {
        component.find("vodService").navigateToURL("/apex/WinMod_Install_vod?sunrise=true");
    }
})