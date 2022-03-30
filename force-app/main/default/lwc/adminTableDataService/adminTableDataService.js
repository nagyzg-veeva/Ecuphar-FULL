import VeevaDataService from "c/veevaDataService";
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class AdminTableDataService extends VeevaDataService {
    constructor(sessionSvc, messageSvc, msgCategory) {
        super(sessionSvc, []);
        this.sessionSvc = sessionSvc;
        this.messageSvc = messageSvc;
        this.messageSvc.loadVeevaMessageCategories([msgCategory]);
    }

    async getTableColumns(product) {
        let request = await this.initMcRequest();
        request.url += `/api/v1/admin-table/${product}/metadata`;
        request.method = "GET";

        try {
            let response = await this.request(request, 'getAdminTableMetadata');
            let columns = response.data;

            await Promise.all(columns.map(async (column) => {
                column.label = await this.messageSvc.getMessageWithDefault(column.veevaMessage, column.veevaMessageCategory, column.label); 
            }));
            // Set time zone for columns based on user's SFDC time zone (LGT defaults to user's system time zone)
            this.setSFDCTimeZone(columns);

            return columns;
        } catch(err) {
            return [];
        }
    }

    async getTableData(product) {
        let request = await this.initMcRequest();
        request.url += `/api/v1/admin-table/${product}/data`
        request.method = "GET";

        try {
            let response = await this.request(request, 'getAdminTableData');
            return response.data;
        } catch(err) {
            return [];
        }
    }

    async getFileData(product, resourceId, fileParam, fileType) {
        const request = await this.getDownloadRequest(product, resourceId, fileParam, fileType);
        return new Promise((resolve, reject) => {
            let filename = "";
            let blob = {};

            let xhr = new XMLHttpRequest();
            xhr.open("GET", request.url, true);
            xhr.setRequestHeader("sfEndpoint", request.headers.sfEndpoint);
            xhr.setRequestHeader("sfSession", request.headers.sfSession);
            xhr.responseType = "blob";
            let _this = this;
            xhr.onload = (e) => {
                // Must set the MIME type to a whitelisted value: https://salesforce.stackexchange.com/questions/231829/unsupported-mime-type-when-creating-blob-instance-into-lightning-community
                blob = new Blob([e.currentTarget.response], {type: "text/plain"});
                var contentDisposition = e.currentTarget.getResponseHeader("Content-Disposition");
                if (contentDisposition) {
                    filename = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/)[1];
                } else {
                    filename = _this.getDefaultFilename(resourceId, fileParam, fileType);
                }
                resolve([blob, filename]);
            };
            xhr.send();
        });
    }

    async getDownloadRequest(product, resourceId, fileParam, fileType) {
        let request = await this.initMcRequest();
        request.headers["Content-Type"] = "text/plain";
        request.url += `/api/v1/admin-table/${product}/files/${resourceId}`;
        request.url += `?fileParams=type=${fileParam}&fileType=${fileType}`;
        return request;
    }

    async getTableTitle(titleMsg, titleCategory, defaultMsg) {
        return await this.messageSvc.getMessageWithDefault(titleMsg, titleCategory, defaultMsg);
    }

    getDefaultFilename(fileId, fileParam, fileType) {
        return fileParam ? `${fileId}_${fileParam}.${fileType}` : `${fileId}.${fileType}`;
    }

    setSFDCTimeZone(columns) {
        for (var i in columns) {
            if (columns[i].type === 'date' && columns[i].typeAttributes.timeZone === undefined) {
                columns[i].typeAttributes.timeZone = TIME_ZONE;
            }
        }
    }
}