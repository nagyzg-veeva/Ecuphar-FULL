import { api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi"
import getMsgWithDefault from "@salesforce/apex/VeevaMessageController.getMsgWithDefault";
import getRecordTypesWithEventCountryConfigs from "@salesforce/apex/EmEventController.getRecordTypesWithEventCountryConfigs";
import VeevaUtils from "c/veevaUtils";
import RecordTypeSelector from "c/recordTypeSelector";

export default class EmRecordTypeSelector extends RecordTypeSelector {
    // Input properties from flow
    @api objectApiName;

    // Output properties to flow
    @api selectedRtId;
    @api selectedRtDeveloperName;
    @api exitEarly;

    // Messages
    labelEventTypePrompt;
    noEventConfigFoundMessage;

    // Component's internal Properties
    doneLoading = false;
    selectedButton;

    constructor() {
        super();
        this.getMessages();
    }

    get showRecordTypes() {
        return this.recordTypeInfos.length > 1;
    }

    get titleNewObject() {
        let title  = '';
        if (this.newObjectTemplate && this.labelObject) {
            title = `${this.newObjectTemplate} ${this.labelObject}`;
        }
        return title;
    }

    get showMessageModal() {
        return Boolean(this.modalMessage);
    }

    get modalMessage() {
        let message = '';
        if (this.doneLoading) {
            if (!this.isCreateable) {
                message = this.insufficientPrivilegesMessage;
            } else if (this.recordTypeInfos.length === 0) {
                message = this.noEventConfigFoundMessage;
            } else {
                message = this.somethingWentWrongMsg;
            }
        }
        return message;
    }
    
    @wire(getObjectInfo, { objectApiName: "$objectApiName" })
    async wiredObjectInfo({ error, data }) {
        if (data) {
            try {
                this.isCreateable = data.createable;
                if (this.isCreateable) {
                    this.labelObject = data.label;
                    let availableTypes = data.recordTypeInfos
                        ? VeevaUtils.getAvailableRecordTypes(data.recordTypeInfos)
                        : [];

                    await this.setRecordTypeInfos(availableTypes);
                    // Display rts with associated event country config only
                    availableTypes = await this.filterNoConfigRt(availableTypes);

                    if (availableTypes.length === 0) {
                        this.showNoEventConfigFoundMessage = true;
                    }
                    if (availableTypes.length === 1) {
                        this.selectedRtId = availableTypes[0].value;
                        this.selectedRtDeveloperName = availableTypes[0].developerName;
                        this.goToNext();
                    } else {
                        let defaultSelected =
                            availableTypes.find(typeInfo => typeInfo.defaultType) ||
                            availableTypes[0];
                        if (defaultSelected) {
                            this.selectedRtId = defaultSelected.value;
                            this.selectedRtDeveloperName = defaultSelected.developerName;
                            defaultSelected.cssClasses = this.getCssClasses(true);
                        }
                    }
                    // Render recordTypeInfos
                    this.recordTypeInfos = availableTypes;
                }
            } catch (err) {
                this.logError(err);
            } finally {
                this.doneLoading = true;
            }
        }
        if (error) {
            this.logError(error);
        }
    }

    logError(error) {
        console.error("found error: " + error);
    }

    handleClick(event) {
        const selectedId = event.currentTarget.value;
        this.selectedRtId = selectedId;
        this.recordTypeInfos.forEach(rt => {
            if (rt.value === selectedId) {
                rt.cssClasses = this.getCssClasses(true);
                this.selectedRtDeveloperName = rt.developerName;
            } else {
                rt.cssClasses = this.getCssClasses();
            }
        });
    }

    getCssClasses(withHighlight = false) {
        return withHighlight
            ? "slds-box slds-box_x-small slds-button_neutral slds-button_stretch rtButton highlight"
            : "slds-box slds-box_x-small slds-button_neutral slds-button_stretch rtButton";
    }

    async setRecordTypeInfos(recordTypes) {
        if (recordTypes && recordTypes.length > 0) {
            const rtIds = recordTypes.map(rt => rt.value);
            const records = await this._uiApi.getBatchRecords(rtIds, [
                "RecordType.Description",
                "RecordType.DeveloperName"
            ]);
            const idToDesc = records.reduce((tempMap, rtRecord) => {
                if (rtRecord.fields && rtRecord.fields.Description) {
                    tempMap[rtRecord.id] = {
                        description: rtRecord.fields.Description.displayValue,
                        developerName: rtRecord.fields.DeveloperName.value
                    }
                }
                return tempMap;
            }, {});
            recordTypes.forEach(rt => {
                rt.description = idToDesc[rt.value].description;
                rt.developerName = idToDesc[rt.value].developerName;
                rt.cssClasses = this.getCssClasses();
            });
        }
    }

    async filterNoConfigRt(availableTypes) {
        const developerNames = availableTypes.map(rt => rt.developerName);
        let recordTypesWithEventCountryConfigs = await getRecordTypesWithEventCountryConfigs(
            { recordTypeDeveloperNames: developerNames }
        );
        let filteredRts = [];

        if (!recordTypesWithEventCountryConfigs) {
            return filteredRts;
        }

        availableTypes.forEach(rt => {
            if (recordTypesWithEventCountryConfigs.includes(rt.developerName)) {
                filteredRts.push(rt);
            }
        });
        return filteredRts;
    }

    getMessages() {
        for (const [key, messageDetails] of Object.entries(this.MESSAGES)) {
            getMsgWithDefault(messageDetails).then((message) => {
                this[key] = message;
            });
        }
    }
    
    MESSAGES = {
        labelEventTypePrompt: {
            key: "EVENT_TYPE_SELECTOR",
            category: "EVENT_MANAGEMENT",
            defaultMessage: "What type of event is this?"
        },
        noEventConfigFoundMessage: {
            key: "NO_EVENT_CONFIG",
            category: "EVENT_MANAGEMENT",
            defaultMessage:
                "You are not allowed to schedule this type of event during this time frame. Please contact your administrator."
        }
    }
}