export default class VeevaRelatedListController {

    LINK_NAME_COLUMN = { 
        label: '', 
        fieldName: 'linkName', 
        type: 'url', 
        typeAttributes: { 
            label: { fieldName: 'Name', target: '_blank'} 
        }, 
        hideDefaultActions: true 
    };
    
    ACTION_COLUMN_WIDTH = 80;
    ACTION_LINKS_COLUMN = { 
        label: '', 
        fieldName: 'actionLinks', 
        type: 'action', 
        typeAttributes: {}, 
        hideDefaultActions: true, 
        fixedWidth: this.ACTION_COLUMN_WIDTH 
    };
    
    constructor(meta, pageCtrl) {
        this.meta = meta;
        this.pageCtrl = pageCtrl;
        this.objectDescribe = {};
    }

    get creatable() {
        let createPermission = true;
        if (this.objectDescribe) {
            createPermission = this.objectDescribe.createable;
        }
        return createPermission;
    }

    async getButtons() {
        let buttons = [];
        if (this.creatable) {
            const newMessage = await this.pageCtrl.getMessageWithDefault('NEW', 'Common', 'New');
            buttons.push({
                label: newMessage,
                name: 'new'
            });
        }
        return buttons;
    }

    DATE_TYPES = {
        'date': {
            typeAttributes: {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            },
        },
        'datetime': {
            typeAttributes: {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: 'numeric',
                minute: '2-digit'
            }
        },
        'time': {
            typeAttributes: {
                hour: 'numeric',
                minute: '2-digit'
            }
        }
    }

    async getColumns() {
        let columnsList = [];
        for (const col of this.meta.columns) {
            if (col.name === 'Name') {
                this.LINK_NAME_COLUMN.label = col.label;
                columnsList.push(this.LINK_NAME_COLUMN);
                continue;
            }
            let column = {
                label: col.label,
                fieldName: col.name,
                type: this.getColumnType(col.name),
                hideDefaultActions: true,
                cellAttributes: { alignment: 'left' },
            };

            if(Object.keys(this.DATE_TYPES).includes(column.type)) {
                column.typeAttributes = this.DATE_TYPES[column.type].typeAttributes;
                column.type = 'date';
            }
            
            columnsList.push(column);
        }
        this.ACTION_LINKS_COLUMN.typeAttributes.rowActions = this.getRowActions; 
        columnsList.push(this.ACTION_LINKS_COLUMN);
        return columnsList;
    }

    async deleteRow(rowId) {
        try {
            let response = await this.pageCtrl.dataSvc.save({
                Deleted: "true",
                Id: rowId,
                type: this.objectDescribe.apiName
            });
            return response;
        } catch (error) {
            return Promise.reject({
                recordErrors: error.data.recordErrors
            });
        }
    }

    knownTypes = [ 'Boolean', 'Currency', 'Email', 'Location', 'Number', 'Percent', 'Phone', 'Url', 'Date', 'DateTime', 'Time' ];

    getColumnType(fieldName) {
        const field = this.objectDescribe 
                && this.objectDescribe.fields 
                && this.objectDescribe.fields[fieldName];

        let dataType = field && field.dataType;
        let type = '';

        if (this.knownTypes.includes(dataType)) {
            type = dataType.toLowerCase();
        }
        else {
            type = 'text';
        }

        return type;
    }

    async getRowActions(row, doneCallback) {
        let actions = [];
        if (row.isUpdateable) {
            const editMessage = await row.ctrl.pageCtrl.getMessageWithDefault('Edit', 'Common', 'Edit');
            actions.push({ label: editMessage, name: 'edit' });
        }
        if (row.isDeletable) {
            const deleteMessage = await row.ctrl.pageCtrl.getMessageWithDefault('DELETE', 'Common', 'Delete');
            actions.push({ label: deleteMessage, name: 'delete' });
        }
        doneCallback(actions);
    }

    getColumnsWithRelatedFields() {
        const columnsWithRelatedFields = this.meta.columns.filter(column => 
            column.name.includes('.')).map(column => column.name);
        return columnsWithRelatedFields;
    }

    getRelatedFields() {
        let relatedFields = [];
        const columnsWithRelatedFields = this.getColumnsWithRelatedFields();
        columnsWithRelatedFields.forEach(column => {
            const [parentFieldName, childFieldName] = column.split('.');
            relatedFields.push({parentFieldName, childFieldName});
        });

        return relatedFields;
    }

    addRelatedFieldValuesToRecord(record, relatedFields) {
        relatedFields.forEach(relatedField => {
            const { parentFieldName, childFieldName } = relatedField;
            if (record?.[parentFieldName]?.[childFieldName]) {
              record[`${parentFieldName}.${childFieldName}`] = record[parentFieldName][childFieldName];
            }
          });
    }
    
    processRecords(data) {
        let newRecords = [];
        if (data && data.length > 0) {

            const relatedFields = this.getRelatedFields();

            data.forEach(record => {
                let temp = Object.assign({}, record);
                temp.linkName = '/' + record.Id;
                if (this.objectDescribe) {
                    temp.isUpdateable = this.objectDescribe.updateable;
                    temp.isDeletable = this.objectDescribe.deletable;
                }

                this.addRelatedFieldValuesToRecord(temp, relatedFields);

                newRecords.push(this.processRecord(temp));
            });
        }
        return newRecords;
    }

    processRecord(record) {
        record.ctrl = this;
        return record;
    }

    getInContextOfRefForNew() {
        return {
            type: 'standard__recordPage',
            attributes: {
                objectApiName: this.pageCtrl.objectApiName,
                recordId: this.pageCtrl.recordId,
                actionName: 'view',
            },
        };
    }
}