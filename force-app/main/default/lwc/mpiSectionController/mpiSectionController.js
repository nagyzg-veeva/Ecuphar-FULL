import VeevaSectionController from 'c/veevaSectionController';
import template from './mpiSectionController.html';
import getMedInqsByGroupId from '@salesforce/apex/MedInqController.getMedInqsByGroupId'
import VeevaLayoutService from 'c/veevaLayoutService';
import VeevaUtils from 'c/veevaUtils';
import MedInqConstant from 'c/medInqConstant';
import VeevaConstant from "c/veevaConstant";

export default class MpiSectionController extends VeevaSectionController {
    _records;
    
    initTemplate() {
        this.template = template;
        return this;
    }

    async getRecords() {
        if (!this._records) {
            let record = this.pageCtrl.record;
            if (!record.id) {
                record.assignRandomId();
            }
            
            this._records = [];
            this.pageCtrl.setMpiInfo(this._records, this.getUniqueFields());

            // fetch other inquires of the same group
            let groupId = record.rawValue(MedInqConstant.GROUP_IDENTIFIER);
            if (groupId) {
                let ids = await getMedInqsByGroupId({ groupId: groupId });
                if (ids.length) {
                    let fields = this.pageCtrl.getQueryFields(this.getUniqueFields());
                    let records = await this.pageCtrl.uiApi.getBatchRecords(ids, fields);
                    records.forEach(x => {
                        if (x.id === record.id || x.id === record.cloneFromId){
                            //recordUpdateFlag does is not updating the mpi sections
                            this.getUniqueFields().forEach(fldName=> {
                                //so, we should ensure that the first section is up to date with the recently queried record
                                record.fields[fldName] = x.fields[fldName];
                            });
                            if (x.fields.Status_vod__c && x.fields.Status_vod__c.value) {
                                //pageCtrl record's Status might be stale, needs to be updated
                                record.fields.Status_vod__c = x.fields.Status_vod__c;
                            }
                            this._records.push(record);
                        }
                        else {
                            const mpiRecord = this.pageCtrl.toVeevaRecord(x);
                            if (this.pageCtrl.isClone) {
                                mpiRecord.assignRandomId();

                                //clear clone skip fields
                                mpiRecord.setFieldValue(MedInqConstant.GROUP_IDENTIFIER, null);
                                this.clearCloneSkipFields(mpiRecord);
                            } 
                            this._records.push(mpiRecord);
                        }
                    });
                }
                if (this.pageCtrl.isClone) {
                    record.setFieldValue(MedInqConstant.GROUP_IDENTIFIER, null);
                }
            }
            else {
                this._records.push(record);
            }
        }
        return [...this._records];
    }

    clearCloneSkipFields(record){
        MedInqConstant.CLONE_SKIP_FIELDS.forEach(doNotClone => {
            record.setFieldValue(doNotClone, null);
        })
    }

    async addInquiry() {
        const record = VeevaUtils.clone(this.pageCtrl.record);
        record.assignRandomId();
        const fields = await this.getDefaults();
        record.fields = Object.assign({}, record.fields);
        this.getUniqueAndCloneExcludedFields().forEach(x => {
            if (fields[x] && fields[x].value) {
                record.fields[x] = Object.assign({}, fields[x]);
            } else if (x !== MedInqConstant.ACCOUNT) {
                record.fields[x] = {}; // clear
                const fldsMeta = this.pageCtrl.objectInfo.fields;
                const fldMeta = fldsMeta && fldsMeta[x];
                if (fldMeta && fldMeta.dataType === 'Reference' && fldMeta.relationshipName) {
                    record.fields[fldMeta.relationshipName] = {}; // clear lookup
                }
            }
        });
        this._setDeleted(record, false);
        this._records.push(record);
        return record;
    }

    copyInquiry(id) {
        let newRecord = null;
        let fromRecord = this._records.find(x => x.id === id);
        if (fromRecord) {
            newRecord = VeevaUtils.clone(fromRecord);
            let skips = [...MedInqConstant.SKIP_MPI_COPY];
            newRecord.fields = fromRecord.getDataForClone(this.pageCtrl.objectInfo, skips);
            newRecord.assignRandomId();
            newRecord.isMPICopy = true;
            this._records.push(newRecord);
        }
        return newRecord;
    }

    deleteInquiry(id) {
        const from = this._records.find(x => x.id === id);
        if (from) {
            if (from.isNew) {
                this._records.splice(this._records.indexOf(from), 1);
            } else {
                this._setDeleted(from, true);
            }
        }
        return from;
    }

    _setDeleted(record, deleted) {
        if (record === this.pageCtrl.record) {
            if (deleted) {
                this.pageCtrl.toDelete();
            } else {
                this.pageCtrl.undelete();
            }
        } else {
            record.Deleted = deleted;
        }
    }

    async getDefaults() {
        if (!this._defaults) {
            let defaults = await this.pageCtrl.uiApi.getCreateDefaults(MedInqConstant.MEDICAL_INQUERY, this.pageCtrl.record.recordTypeId);
            this._defaults = Object.fromEntries(Object.entries(defaults.record.fields).filter(([key]) => this.getUniqueFields().includes(key)));
        }
        return this._defaults || {};
    }

    // find fields in MPI section
    getUniqueFields() {
        if (!this._fields) {
            let mpiSectionFields = VeevaLayoutService.getSectionItems(this.meta).map(x => x.field);
            let index = mpiSectionFields.indexOf(MedInqConstant.ZVOD_DELIVERY_METHOD);
            if (index >= 0) {
                mpiSectionFields.splice(index, 1);
                Object.values(MedInqConstant.NEW_FIELDS).forEach(x => {mpiSectionFields = [...mpiSectionFields, ...x];});
            }
            this._fields = ['Id', ...mpiSectionFields];
            if (!this._fields.includes(VeevaConstant.FLD_MOBILE_ID_VOD) && this.pageCtrl.objectInfo.getFieldInfo(VeevaConstant.FLD_MOBILE_ID_VOD)){
                this._fields = [...this._fields, VeevaConstant.FLD_MOBILE_ID_VOD];
            }
        }
        return this._fields;
    }

    saveCheckpoint() {
        if (this._records) {
            let sharedForNew;
            let sharedForUpdate;

            let lines = this._records.map((record) => {
                let change = record.getChanges(this.pageCtrl.objectInfo);
                if (record!==this.pageCtrl.record) {
                    if (record.isNew) {
                        sharedForNew = sharedForNew || this.getSharedForNew();
                        Object.assign(change, sharedForNew);
                    }
                    else {
                        sharedForUpdate = sharedForUpdate || this.getSharedForUpdate();
                        Object.assign(change, sharedForUpdate);
                    }
                }
                if (!record.isNew && !record.Deleted) {
                    change.type = MedInqConstant.MEDICAL_INQUERY;
                    change.Id = record.id;
                    let groupId = record.rawValue(MedInqConstant.GROUP_IDENTIFIER);
                    if (groupId) {
                        change[MedInqConstant.GROUP_IDENTIFIER] = groupId;
                    }
                }
                return change;
            });
            this.pageCtrl.setMpiChanges(lines);
        }
    }

    getSharedForNew() {
        let shared = this.pageCtrl.record.getCreatableValues(this.pageCtrl.objectInfo);
        //filter to exclude fields not to be copied
        return Object.fromEntries(Object.entries(shared).filter(([key]) => !this.getUniqueAndCloneExcludedFields().includes(key)));
    }

    getSharedForUpdate() {
        let shared = this.pageCtrl.record.getUpdatableValues(this.pageCtrl.objectInfo);
        return Object.fromEntries(Object.entries(shared).filter(([key]) => !this.getUniqueFields().includes(key)));
    }

    getUniqueAndCloneExcludedFields(){
        return [...this.getUniqueFields(), ...MedInqConstant.SKIP_MPI_COPY.filter((key) => this.getUniqueFields().indexOf(key) === -1)];
    }
}