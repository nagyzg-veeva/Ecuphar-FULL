({
    runReport: function(selectedReports, analyticsFiles, vodInfo) {

        var url = vodInfo.veevaServer + "/api/v1/analytics/reports";
        var id = analyticsFiles.Id;
        var name = analyticsFiles.Type_vod__c;
        var status = analyticsFiles.Status_vod__c;
        var fname = analyticsFiles.File_Name_vod__c;
        var mkt = analyticsFiles.Market_vod__c;
        if (mkt === null || mkt === undefined) {
            mkt = "";
        }
        var body = {
            status: status,
            fileName: fname,
            url: "",
            dmname: name,
            market: mkt,
            Id: id,
            brkrpt: false,
            actrpt: false,
            terrpt: false,
            pyrrpt: false,
            dtcl: false,
            ziprpt: false,
            ctlrpt: false,
            mktrpt: false,
            prdrpt: false
        };
        for (var i = 0; i < selectedReports.length; i++) {
            body[selectedReports[i]] = true;
        }
        var xhttp = new XMLHttpRequest();
        xhttp.onreadystatechange = function() {
            if (this.readyState === 4) {
                if (this.status === 200) {
                    console.log("Success");
                } else {
                    console.log("Failure");
                }
            }
        };

        xhttp.open("POST", url);
        xhttp.setRequestHeader("sfSession", vodInfo.sfSession);
        xhttp.setRequestHeader("sfEndpoint", vodInfo.sfEndpoint);
        xhttp.setRequestHeader('Content-Type', 'application/json');
        xhttp.send(JSON.stringify(body));

    }
})