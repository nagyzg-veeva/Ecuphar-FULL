import VeevaPageController from "c/veevaPageController";
import { fireEvent } from 'c/pubsub';
import EmEventConstant from "c/emEventConstant";
import EmPageReference from "c/emPageReference";

export default class EmController extends VeevaPageController {

    layoutFields;

    constructor(dataSvc, userInterface, messageSvc, emPageLayoutEngineSvc) {
        super(dataSvc, userInterface, messageSvc);

        this.emPageLayoutEngineSvc = emPageLayoutEngineSvc;
        this.emPageLayoutEngineSvcParams = {};
    }

    async initPageLayout() {
        this.page.layout = { sections: [] }; //reset layout
        let layout = await this.emPageLayoutEngineSvc.getPageLayout(this.objectInfo.apiName, this.page.action, this.id, this.emPageLayoutEngineSvcParams);
        if (layout.relatedLists) {
            fireEvent(this, EmEventConstant.POPULATE_RELATED_LIST_TABS, { relatedLists : layout.relatedLists, pageCtrl: this });
        }
        this.page.layout = await this.processLayout(layout);
        this.setButtons();
    }

    get canEdit() { 
        const hasEditButton = this.getHeaderButtons().some(button => button.name === 'Edit')

        return super.canEdit && hasEditButton;
    }

    processLayout(layout) {
        if (layout.sections) {
            this.layoutFields = {};
            layout.sections.forEach(section => {
                section.layoutRows.forEach(row => {
                    row.layoutItems.forEach(item => {
                        this.layoutFields[item.field] = item;
                    });
                });
            });
        }
        if (this.record.isNew) {
            this.filterDefaultFields();
        }

        return layout;
    }

    isFieldOnLayout(fieldName) {
        return Boolean(this.layoutFields[fieldName]);
    }

    filterDefaultFields() {
        // Filter fields not part of the layout
        this.record.fields = Object.fromEntries(
            Object.entries(this.record.fields).filter(
                ([key, value]) =>
                    this.layoutFields[key] ||
                    !key.endsWith("__c") ||
                    this.emPageLayoutEngineSvcParams[key]
            )
        );
    }

    async initRecordCreateBase(pageRef) {
        const recordTypeId = pageRef.state.recordTypeId;
        const masterRt = this.objectInfo.getMasterRecordType();
        const apiName = pageRef.attributes.objectApiName;

        let [ defaults, allMasterPicklists, allRtPicklists] = await Promise.all([
            EmPageReference.getCreateDefaults(this.uiApi, recordTypeId, apiName, this._objectInfo.fields, pageRef),
            this.uiApi.getPicklistValues(masterRt.recordTypeId, apiName, ""),
            this.uiApi.getPicklistValues(recordTypeId, apiName, "")
        ]);

        this.addDefaultPicklistValues(defaults.record.fields, allMasterPicklists, allRtPicklists);

        this.record = defaults.record;
    }

    async initRecordCreate(pageRef) {
        await this.initRecordCreateBase(pageRef);
        this.addDefaultFieldValues(pageRef.state);
        this.emPageLayoutEngineSvcParams = this.getEmPleParams();
        await this.initPageLayout();
    }

    getEmPleParams() {
        const params = {
            RecordTypeId: this.record?.recordTypeInfo?.recordTypeId,
            Event_vod__c: this.record?.fields?.Event_vod__c?.value,
        };
        return params;
    }

    addDefaultPicklistValues(defaultFields, allMasterPicklists, allRtPicklists) {
        for (const picklistName in allMasterPicklists.picklistFieldValues) {
            const defaultPicklist = defaultFields[picklistName];
            let picklistToCopy = {};
            if (defaultPicklist.value) {
               // Compensate for getCreateDefaults not grabbing picklist displayName
                picklistToCopy = allRtPicklists.picklistFieldValues[picklistName];
            } else {
                // Replace blank rt defaults with field level defaults
                picklistToCopy = allMasterPicklists.picklistFieldValues[picklistName];
            }

            const defaultValue = picklistToCopy.defaultValue;
            if (defaultValue) {
                defaultPicklist.value = defaultValue.value;
                defaultPicklist.displayValue = defaultValue.label;
            }
        }
    }

    getRedirectPageRef() {
        if (this.page.action === 'Edit' && !this.canEdit) {
            return {
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.id,
                    objectApiName: this.objectApiName,
                    actionName: 'view',
                },
            };
        }

        return null;
    }

    initTemplate(ctrl) {
        if (EmEventConstant.PLE_SUPPORTED_OBJECTS.includes(this.objectApiName) && ctrl.fieldApiName === EmEventConstant.EVENT && ctrl.displayValue) {
            // set Event lookup as read-only if it is populated
            ctrl.editable = false;
        }
        return super.initTemplate(ctrl);
    }

    getPageRefForSaveAndNew(id, pageState) {
        if (!pageState.inContextOfRef) {
            const defVals = {};
            if (this.record?.rawValue('Event_vod__r')?.id) {
                defVals.Event_vod__c = {
                    value: this.record.rawValue('Event_vod__r').id,
                    displayValue: this.record.fields.Event_vod__r.displayValue,
                };
            } else if (this.record?.rawValue('Event_vod__c')) {
                defVals.Event_vod__c = this.record.fields.Event_vod__c;
            }
            pageState.inContextOfRef = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: id,
                    objectApiName: this.objectApiName,
                    actionName: 'view',
                },
                emDefaultFieldValues: defVals,
            };
        }

        const pageRef = super.getPageRefForSaveAndNew(id, pageState);

        pageRef.state.useRecordTypeCheck = true;
        const backgroundContext = this.getBackgroundContextForSaveAndNew(pageRef.state.inContextOfRef);
        if (backgroundContext) {
            pageRef.state.backgroundContext = backgroundContext;
        }
        return pageRef;
    }

    getBackgroundContextForSaveAndNew(inContextOfRef) {
        let backgroundPageRef;
        if (inContextOfRef instanceof String) {
            backgroundPageRef = JSON.parse(window.atob(inContextOfRef));
        } else {
            backgroundPageRef = inContextOfRef;
        }

        let url;
        let params = '';
        if (backgroundPageRef) {
            const attrs = backgroundPageRef.attributes;
            if (backgroundPageRef.type === 'standard__recordPage') {
                url = `/lightning/r/${attrs.objectApiName}/${attrs.recordId}/${attrs.actionName}`;
            } else if (backgroundPageRef.type === 'standard__objectPage') {
                url = `/lightning/o/${attrs.objectApiName}/${attrs.actionName}`;
            }

            if (backgroundPageRef.state) {
                const state = backgroundPageRef.state;
                for (const param in state) {
                    if (state.hasOwnProperty(param)) {
                        if (typeof state[param] === 'object') {
                            params = `${params}${param}=${JSON.stringify(state[param])}&`;
                        } else {
                            params = `${params}${param}=${state[param]}&`;
                        }
                    }
                }
            }

            if (url && params) {
                url = `${url}?${params}`;
            }
        }
        return url;
    }

    addDefaultFieldValues(state) {
        if (state?.inContextOfRef?.emDefaultFieldValues) {
            Object.entries(state.inContextOfRef.emDefaultFieldValues)
                .filter(([key, value]) => key !== 'RecordTypeId')
                .forEach(([key, value]) => {
                    if (this.record.fields[key] || this.objectInfo.getFieldInfo(key)) {
                        this.record.fields[key] = value;
                    }
                });
        }
    }

    getPageRefForDelete() {
        if (this.record?.fields?.Event_vod__c?.value) {
            return {
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.record.fields.Event_vod__c.value,
                    objectApiName: 'EM_Event_vod__c',
                    actionName: 'view',
                },
            };
        }
        return super.getPageRefForDelete();
    }
}