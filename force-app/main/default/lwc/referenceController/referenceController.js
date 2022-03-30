import FieldController from "c/fieldController";
import VeevaUtils from "c/veevaUtils";
import VeevaLayoutService from "c/veevaLayoutService";

const soqlFieldPattern = /^(toLabel\()?(([^().]+)(\.Name)?)\)?$/;

export default class ReferenceController extends FieldController {
    initTemplate() {
        this.veevaFieldReference = true;
        return this;
    }

    get selected() {
        let ref = this.data.reference(this.field);
        return ref.apiName ? { ...ref, icon: VeevaUtils.getIcon(ref.apiName) } : ref;
    }

    // TODO Salesforce fields might have more than one referenceToInfo, i.e. Task.WhoId or Task.WhatId.
    // We might need to support that in the future.
    get targetSObject() {
        return this.field.referenceToInfos[0].apiName;
    }

    get relationshipName() {
        return this.field.relationshipName;
    }

    get nameField() {
        let nameField = 'Name';
        if (this.field.referenceToInfos[0] && this.field.referenceToInfos[0].nameFields.indexOf(nameField) < 0) {
            nameField = this.field.referenceToInfos[0].nameFields[0];
        }
        return nameField;
    }

    async getColumns() {
        if (!this._columns) {
            const [searchLayoutResponse, objectInfo] = await Promise.all([
                this.pageCtrl.uiApi.searchLayout(this.targetSObject), this.getTargetObjectInfo()
            ]);
            this._columns = VeevaLayoutService.toSearchLayoutColumns(searchLayoutResponse, objectInfo, this.targetSObject);
        }
        return this._columns;
    }

    async getTargetObjectInfo() {
        if (!this.referenceTo) {
            this.referenceTo = await this.pageCtrl.uiApi.objectInfo(this.targetSObject);
        }
        return this.referenceTo;
    }

    async searchWithColumns(term, nextPageUrl) {
        const response = await this.search(term, nextPageUrl);
        response.records = await this.parseForColumns(response.records);
        return response;
    }

    async search(term, nextPageUrl) {
        const response = await this.pageCtrl.uiApi.search(this.objectApiName, this.field.apiName, this.targetSObject, term, this.getDependentValues(), nextPageUrl);
        response.records = response.records.map(record => this.toSearchRecord(record));
        return response;
    }

    toSearchRecord(record) {
        let result = { id: record.id, apiName: record.apiName, icon: VeevaUtils.getIcon(record.apiName) };
        Object.entries(record.fields).forEach(([fldName, valueObj]) => {
            result[fldName] = valueObj.displayValue || valueObj.value;
        });
        result.name = result.Name || '';
        return result;
    }

    async parseForColumns(respRecords) {
        const records = respRecords;
        if (records && records.length > 0) {
            const queriedFlds = Object.keys(records[0]);
            const columns = await this.getColumns();
            const missingColFld = columns && columns.some(col=>
                !queriedFlds.includes(col.fieldName));
            if (missingColFld) {
                const respIds = records.map(record=>record.id);
                const colFlds = columns.map(col=>col.queryFld);
                const newRecords = await this.pageCtrl.uiApi.getBatchRecords(respIds, colFlds);
                if (newRecords) {
                    const idToNewFields = newRecords.reduce((tempMap, record)=>{
                        tempMap[record.id] = record.fields;
                        return tempMap;
                    }, {});
                    records.forEach(record => {
                        const fields = idToNewFields[record.id];
                        if (fields) {
                            Object.entries(fields).forEach(([fldName, fldObj])=>{
                                record[fldName] = fldObj.displayValue || fldObj.value;
                            });
                        }
                    });
                }
            }
        }
        return records;
    }

    async searchTerm(term) {
        const msg = await this.pageCtrl.getMessageWithDefault('SHOW_ALL_RESULTS', 'Lightning', 'Show all results for {0}');
        return msg.replace('{0}', term);
    }

    getControllingFields() {
        if (!this._controllingFields) {
            this._controllingFields = [];
            let filter = this.field.filteredLookupInfo;
            if (filter && filter.dependent && !filter.optionalFilter) {
                this._controllingFields = filter.controllingFields;
            }
        }
        return this._controllingFields;
    }

    getDependentValues() {
        let fields = this.getControllingFields();
        if (fields.length) {
            let result = {};
            fields.forEach(x => { result[x] = this.data.rawValue(x) });
            return result;
        }
        return null;
    }

    // Display Salesforce System fields such as CreatedById
    get extra() {
        if (this.meta.layoutComponents && this.meta.layoutComponents.length > 1) {
            let extra = this.meta.layoutComponents.find(x => x.componentType === 'Field' && x.apiName !== this.fieldApiName);
            if (extra) {
                let extraValue = this.data.displayValue(extra.apiName);
                if (extraValue) {
                    return `, ${extraValue}`;
                }
            }
        }
        return null;
    }
}