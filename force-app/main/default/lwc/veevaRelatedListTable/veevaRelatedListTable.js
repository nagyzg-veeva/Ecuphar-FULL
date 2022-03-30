import { api, track, LightningElement, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from "lightning/navigation";
import VeevaUtils from "c/veevaUtils";
import getRelatedRecords from "@salesforce/apex/VeevaRelatedObjectController.getRelatedRecords"
import ControllerFactory from 'c/controllerFactory';
import VeevaToastEvent from "c/veevaToastEvent";

const INITIAL_OFFSET = 0;
const INITIAL_LIMIT = 20;
const INFINITE_SCROLL_INCREMENTS = 10;

export default class VeevaRelatedListTable extends NavigationMixin(LightningElement) {

    @api parentId;
    @api meta;
    @api pageCtrl;
    @track buttons = [];
    @track records = [];
    showDeleteModal = false;
    isDeleting = false;
    msgCancel;
    msgDelete;
    deleteModalBody;
    deleteModalHeader;
    recordToDelete;
    columns = [];
    ctrl;
    hasMoreData = true;

    @wire(getObjectInfo, { objectApiName: '$objectApiName'})
    wireObjectInfo(result) {
        const data = result.data;
        if (data && this.ctrl) {
            this.ctrl.objectDescribe = data;
            this.ctrl.getButtons().then(buttons => { this.buttons = buttons; });
            this.ctrl.getColumns().then(columns => { this.columns = columns; });
            this.initRecords();
            this.initDeleteModal();
        }
    }

    get recordsLength() {
        let num = 0;
        if (this.records) {
            num = this.records.length;
        }
        return num;
    }

    get numRecords() {
        let numRecords = this.recordsLength;
        if (numRecords > 10) {
            numRecords = '10+';
        }
        return numRecords;
    }

    get iconName() {
        let icon = 'standard:default';
        if (this.objectApiName) {
            icon = VeevaUtils.getIcon(this.objectApiName);
        }
        return icon;
    }

    get objectApiName() {
        return this.meta.objectApiName;
    }

    get hasData() {
        return this.recordsLength > 0;
    }

    get columnsString() {
        return this.meta.columns.map(column => column.name).join(',');
    }

    get dataTableClass() {
        let css = 'slds-border_top';
        if (this.recordsLength > 10) {
            css += ' related-list-table';
        }
        return css;
    }

    initRecords() {
        getRelatedRecords({ 
            fields: this.columnsString, 
            objectApiName: this.objectApiName, 
            relationField: this.meta.field, 
            id: this.parentId,
            qlimit: INITIAL_LIMIT,
            offset: INITIAL_OFFSET
        }).then(records => {
            this.records = this.ctrl.processRecords(records);

            this.hasMoreData = this.recordsLength >= INITIAL_LIMIT;
        });
    }

    async initDeleteModal() {
        const [msgConfirm, msgDelete, msgCancel] = await Promise.all([
            this.pageCtrl.getMessageWithDefault('GENERIC_DELETE_BODY', 'Common', 'Are you sure you want to delete this {0}?'),
            this.pageCtrl.getMessageWithDefault('DELETE', 'Common', 'Delete'),
            this.pageCtrl.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
        ]);

        this.msgDelete = msgDelete;
        this.msgCancel = msgCancel;
        this.deleteModalBody = msgConfirm.replace('{0}', this.ctrl.objectDescribe.label);
        this.deleteModalHeader = `${msgDelete} ${this.ctrl.objectDescribe.label}`;
    }

    @api resetRecords() {
        if (this.recordsLength > INITIAL_LIMIT) {
            this.records = [];
            this.initRecords();
            this.hasMoreData = true;
        }
    }

    connectedCallback() {
        this.ctrl = ControllerFactory.relatedListController(this.meta, this.pageCtrl);
    }

    deleteRecord(id) {
        let newList = this.records.filter(row => row.Id !== id);
        this.records = newList;
    }

    handleButton(event) {
        const button = event.target;
        switch(button.name) {
            case 'new':
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: this.objectApiName,
                        actionName: 'new'
                    }, 
                    state: {
                        useRecordTypeCheck: true,
                        inContextOfRef: window.btoa(JSON.stringify(this.ctrl.getInContextOfRefForNew())),
                    },
                });
                break;
            default:
                //non standard button
                this.ctrl.handleButton(button.name);
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch(action.name) {
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                      recordId: row.Id,
                      objectApiName: this.objectApiName,
                      actionName: "edit"
                    }
                  });
                break;
            case 'delete':
                this.recordToDelete = row.Id;
                this.isDeleting = false;
                this.showDeleteModal = true;
                break;
            default:
                //non standard action
                this.ctrl.handleRowAction(action, row);
        }
    }

    handleDelete() {
        this.isDeleting = true;
        this.ctrl.deleteRow(this.recordToDelete)
            .then(async () => {
                // successful delete
                this.deleteRecord(this.recordToDelete);
                let toast = await VeevaToastEvent.recordDeleted();
                this.dispatchEvent(toast);
            })
            .catch(error => {
                // delete error
                let message = error;
                if (error.recordErrors && error.recordErrors.length > 0) {
                    message = error.recordErrors[0];
                }
                this.dispatchEvent(
                    VeevaToastEvent.error({ message: message })
                );
            })
            .finally(() => {
                this.showDeleteModal = false;
                this.isDeleting = false;
            });
    }

    handleCancel() {
        this.recordToDelete = null;
        this.showDeleteModal = false;
    }

    async loadMoreData(event) {
        if (!this.hasMoreData) {
            return;
        }

        const table = event.target;
        try {
            table.isLoading = true;
            let data = await getRelatedRecords({ 
                fields: this.columnsString, 
                objectApiName: this.objectApiName, 
                relationField: this.meta.field, 
                id: this.parentId,
                qlimit: INFINITE_SCROLL_INCREMENTS,
                offset: this.recordsLength
            });
            
            if (data.length > 0) {
                this.records = this.records.concat(this.ctrl.processRecords(data));
            } else {
                // assume that there are no more data to be fetched
                this.hasMoreData = false;
            }
        } finally {
            table.isLoading = false;
        }
    }
}