import { LightningElement, api, track, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import getMsgWithDefault from "@salesforce/apex/VeevaMessageController.getMsgWithDefault";
import getEventCountryConfigs from "@salesforce/apex/EmEventController.getEventCountryConfigs";
import getUserPreferenceCountryConfig from "@salesforce/apex/EmEventController.getUserPreferenceCountryConfig";
import { FlowNavigationNextEvent } from "lightning/flowSupport";

export default class CountrySelector extends LightningElement {
    // Input properties from flow
    @api recordTypeDeveloperName;

    // Output properties to flow
    @api eventConfigId;
    @api exitEarly;
    @api selectedCountryCode;
    @api selectedCountryId;

    // Messages and Prompts
    labelCancel;
    labelNext;
    noEventConfigFoundMessage;
    labelCountryPrompt;
    labelCountry;
    selectLabel;

    // Component's internal Properties
    @track options = [];
    noEventConfigCountriesFound;
    eventConfigQueryComplete = false;
    currentPicklistValue;
    newObjectTemplate;

    get titleNewObject() {
        return this.newObjectTemplate
            ? this.newObjectTemplate.replace("{0}", this.labelObject)
            : "";
    }

    get renderCountrySelector() {
        return Boolean(
            !this.noEventConfigCountriesFound && this.eventConfigQueryComplete
        );
    }

    @wire(getObjectInfo, { objectApiName: "EM_Event_vod__c" })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.labelObject = data.label;
            if (
                data.fields.Country_vod__c &&
                data.fields.Country_vod__c.label
            ) {
                this.labelCountry = data.fields.Country_vod__c.label;
            } else {
                this.labelCountry = "Country";
            }
        }
    }

    async connectedCallback() {
        this.getMessages();
        let [userPref, countryConfigs] = await Promise.all([
            getUserPreferenceCountryConfig(),
            getEventCountryConfigs({
                recordTypeDeveloperNames: [this.recordTypeDeveloperName]
            })
        ]);
        
        // User Pref Ex. 'US;1'
        userPref = userPref || '';
        const [defaultCountry, onlyDefaultCountry] = userPref.split(';');

        // Check whether User preference is 0
        if (onlyDefaultCountry === '0') {
            let defaultCountryConfig = countryConfigs.find(config => config.Country_vod__r.Country_Name_vod__c === defaultCountry);
            if (!!defaultCountryConfig) {
                // Do no render modal, skip to next screen
                this.selectedCountryCode = defaultCountryConfig.Country_vod__r.Country_Name_vod__c;
                this.selectedCountryId = defaultCountryConfig.Country_vod__c;
                this.eventConfigId = defaultCountryConfig.Event_Configuration_vod__c;
                this.goToNext();
            } else {
                // Display error modal in case no default country config found
                this.noEventConfigCountriesFound = true;
            }
            return;
        }

        this.populatePicklist(defaultCountry, countryConfigs);
    }

    populatePicklist(defaultCountry, countryConfigs) {
        this.options = this.convertCountryConfigsToOptions(countryConfigs, defaultCountry);
        this.options.sort((a, b) => a.label.localeCompare(b.label));

        if (this.options.length === 0) {
            this.noEventConfigCountriesFound = true;
        }
        
        this.eventConfigQueryComplete = true;
    }

    convertCountryConfigsToOptions(countryConfigs, defaultCountry) {
        const options = [];
        countryConfigs.forEach(config => {
            options.push({
                value: config.Country_vod__r.Country_Name_vod__c,
                label: config.Country_vod__r.LabelAlias,
                countryId: config.Country_vod__c,
                eventConfigId: config.Event_Configuration_vod__c
            });
            if (config.Country_vod__r.Country_Name_vod__c === defaultCountry) {
                this.currentPicklistValue = config.Country_vod__r.Country_Name_vod__c;
                this.selectedCountryCode = config.Country_vod__r.Country_Name_vod__c;
                this.selectedCountryId = config.Country_vod__c;
                this.eventConfigId = config.Event_Configuration_vod__c;
            }
        });
        return options;
    }

    handleChange(event) {
        this.currentPicklistValue = event.detail.value;
        this.selectedCountryCode = this.currentPicklistValue;
        // Assumes no duplicate countries may exist for each event config
        const matchingOption = this.options.find(el => el.value === event.detail.value);
        [this.eventConfigId, this.selectedCountryId] = [matchingOption.eventConfigId, matchingOption.countryId];
    }

    goToNext() {
        if (this.validate()) {
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }

    finishFlow() {
        this.exitEarly = true;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    @api
    validate() {
        let element = this.template.querySelector("lightning-combobox");
        if (!element) {
            return true;
        }
        if (element.checkValidity()) {
            return true;
        } else {
            element.reportValidity();
            return false;
        }
    }

    getMessages() {
        getMsgWithDefault({
            key: "Cancel",
            category: "Common",
            defaultMessage: "Cancel"
        }).then(data => {
            this.labelCancel = data;
        });
        getMsgWithDefault({
            key: "NEXT_STEP",
            category: "CallReport",
            defaultMessage: "Next"
        }).then(data => {
            this.labelNext = data;
        });
        getMsgWithDefault({
            key: "NO_EVENT_CONFIG",
            category: "EVENT_MANAGEMENT",
            defaultMessage:
                "You are not allowed to schedule this type of event during this time frame. Please contact your administrator."
        }).then(msg => {
            this.noEventConfigFoundMessage = msg;
        });
        getMsgWithDefault({
            key: "EVENT_COUNTRY_SELECTOR",
            category: "EVENT_MANAGEMENT",
            defaultMessage: "What country will this event be hosted in?"
        }).then(data => {
            this.labelCountryPrompt = data;
        });
        getMsgWithDefault({
            key: "SELECT_FIELD",
            category: "Common",
            defaultMessage: "Select {0}"
        }).then(data => {
            this.selectLabel = data.replace("{0}", this.labelCountry);
        });
        getMsgWithDefault({
            key: "NEW_OBJECT",
            category: "TABLET",
            defaultMessage: "New {0}"
        }).then(data => {
            this.newObjectTemplate = data;
        });
    }
}