import AdminTableDataService from "c/adminTableDataService";
import VeevaMessageService from "c/veevaMessageService";
import VeevaSessionService from "c/veevaSessionService";
import { LightningElement, api, track } from "lwc";

export default class AdminTable extends LightningElement {
    @api product;
    @api rowsDisplayed;
    @api hasDateColumn;
    @api tableTitle;
    @api tableTitleMessage;
    @api tableTitleCategory;
    @api tableDateColumn;
    @api tableResourceFieldName;
    @api tableResourceParamName;
    @api tableResourceTypeName;
    @api columns = [];
    @api displayedTableData = [];
    @api tableData = [];
    @api enableInfiniteLoading;
    @api initialLoad;
    @api waiting;

    async initComponent() {
        let sessionSvc = new VeevaSessionService();
        let messageSvc = new VeevaMessageService();
        this.dataSvc = new AdminTableDataService(sessionSvc, messageSvc, 'Common');
        this.tableTitle = await this.dataSvc.getTableTitle(this.tableTitleMessage, this.tableTitleCategory, this.tableTitle);
    }

    async connectedCallback() {
        this.initialLoad = true;
        this.waiting = true;
        this.initComponent();
        await Promise.all([this.getTableColumns(), this.getTableData()]);
        this.enableInfiniteLoading = true;
        this.waiting = false;
    }

    async getTableColumns() {
        this.columns = await this.dataSvc.getTableColumns(this.product);
    }

    async getTableData() {
        this.tableData = await this.dataSvc.getTableData(this.product);
        if (this.tableData && this.tableData !== undefined) {
            this.optionallySortByDate();
            this.displayedTableData = this.displayData();
        }
    }

    optionallySortByDate() {
        if (this.hasDateColumn) {
            this.tableData.sort((a, b) => {
                if (a[this.tableDateColumn] === undefined && b[this.tableDateColumn] === undefined) {
                    return 0;
                }else if (a[this.tableDateColumn] === undefined) {
                    return -1;
                } else if (b[this.tableDateColumn] === undefined) {
                    return 1;
                } else {
                    return Date.parse(b[this.tableDateColumn]) - Date.parse(a[this.tableDateColumn]);
                }
            });
        }
    }

    displayData() {
        return this.rowsDisplayed > this.tableData.length ? this.tableData : this.tableData.slice(0, this.rowsDisplayed);
    }

    async loadMoreData() {
        if (!this.initialLoad) {
            this.enableInfiniteLoading = false;
            let nextArraySize = this.displayedTableData.length + this.rowsDisplayed;
            if (nextArraySize < this.tableData.length) {
                this.enableInfiniteLoading = true;
                this.displayedTableData = this.tableData.slice(0, nextArraySize);
            } else {
                this.displayedTableData = this.tableData;
            }
        } else {
            this.initialLoad = false;
        }
    }

    saveBlob(blob, filename) {
        var a = document.createElement('a');
        a.href = window.URL.createObjectURL(blob);
        a.download = filename;
        a.dispatchEvent(new MouseEvent('click'));
    }

    async handleRowAction(event) {
        const action = event.detail.action;
        const actionName = action.name;
        const fileParam = action[this.tableResourceParamName];
        const fileType = action[this.tableResourceTypeName];
        const row = event.detail.row;

        const disabled = row.disabled === null ? false : event.detail.row.disabled;
        const resourceId = row[this.tableResourceFieldName];

        if (!disabled && actionName === "download") {
            this.waiting = true;
            let fileInfo = await this.dataSvc.getFileData(this.product, resourceId, fileParam, fileType);
            this.saveBlob(fileInfo[0], fileInfo[1]);
            this.waiting = false;
        }
    }
}