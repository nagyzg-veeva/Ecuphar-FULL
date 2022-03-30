/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api, track } from 'lwc';
import VeevaUtils from 'c/veevaUtils';

const SEARCH = 'search';
const RECENT = 'recent';
export default class VeevaLookup extends LightningElement {
    @api startTerm;
    @api label;
    @track selected = {};
    @track searchTerm;
    @track searchRecords = [];
    @track hasFocus = false;

    suggestion = '';
    recentLabel = '';

    initialSelectedObj;

    _ctrl;
    _invalidLookupMsg;
    _timeout;
    _handleBlur = true;
    firstTime = true;
    highlightIndex = 0;

    @api
    get ctrl() {
        return this._ctrl;
    }

    set ctrl(value) {
        this._ctrl = value;
        if (!this.firstTime){
            this.selected = this.initialSelectedObj;
        }
        this.firstTime = false;
        this.setLabels();       
    }

    get variant() {
        let variant = 'label-hidden';
        if (this.label) {
            variant = '';
        }
        return variant;
    }

    async setLabels() {
        const selected = this.ctrl.selected;
        const objectInfos = await this._ctrl.pageCtrl.uiApi.objectInfoDirectory();
        const objects = objectInfos && objectInfos.objects;
        if (objects && selected && objects[selected.apiName]) {
            const labelPlural = objects[selected.apiName].labelPlural;
            const search = await this._ctrl.pageCtrl.getMessageWithDefault('SEARCH', 'Common', 'Search');
            this.suggestion = `${search} ${labelPlural}...`;
            const recent = await this._ctrl.pageCtrl.getMessageWithDefault('RECENT_LOOKUP_LIST', 'Common', 'Recent {0}');
            this.recentLabel = recent.replace('{0}', labelPlural);
        }
    }

    async connectedCallback() {
        this.searchTerm = this.startTerm || '';
        if (!this.searchTerm) {
            const selObj = this.ctrl.selected;
            await this.populateMissingName(selObj, this.ctrl.nameField, this.ctrl.pageCtrl.uiApi)
            this.selected = selObj;
        }
        this._invalidLookupMsg = await this.getInvalidLookupMsg();

    }

    async populateMissingName(selectedObj, nameField, uiApi) {
        const isLabelMissing = selectedObj.id && (!selectedObj.name || (selectedObj.id === selectedObj.name));
        if (isLabelMissing && selectedObj.apiName) {
            const data = await VeevaUtils.to(uiApi.getRecord(selectedObj.id, [`${selectedObj.apiName}.${nameField}`]));
            if (data[1] && data[1].fields) {
                selectedObj.name = data[1].fields.Name.value;
            }
        }
        this.initialSelectedObj = selectedObj;
    }

    handleMouseDown(){
        this._handleBlur = false;
    }

    handleMouseUp(){
        this._handleBlur = true;
    }

    handleMouseOut(){
        if (this.searchRecords.length > 0){
            this.removeHighlight();
        }
    }

    resetHighlight(record){
        if(record.showHighlight){
            record.showHighlight = false;
            record.listboxOptionClass = "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity"; 
        }
    }

    async handleClearLookup() {
        this.selected = {};
        setTimeout(() => { this.template.querySelector("[data-input-term]").focus() }, 100);
        this.dispatchEvent(new CustomEvent("clearlookup"));
    }

    async handleFocus() {
        this.hasFocus = true;
        await this.search();
    }
    handleClearInput(event) {
        event.stopImmediatePropagation();
    }

    handleInput(event) {
        if (this._timeout) {
            clearTimeout(this._timeout);
        }
        
        if(event.code === 'Escape'){
            this.records = null;
            this.searchRecords = [];
        } else if(event.code === 'ArrowUp' && this.searchRecords.length > 0){
            this.changeHighlightIndex(this.decrementHighlightIndex);
        } else if(event.code === 'ArrowDown' && this.searchRecords.length > 0){
            this.changeHighlightIndex(this.incrementHighlightIndex);
        } else if(event.code === 'Enter' && this.searchRecords.length > 0){
            let currElement = this.template.querySelector(".slds-has-focus");
            if (currElement){
                currElement.click();
            }
        } else if((event.code === 'Delete' || event.code === 'Backspace') && this.selected.name){
            this.selected = {};
            this.dispatchEvent(new CustomEvent("clearlookup"))
        } else {
            this.searchTerm = event.target.value;
            const waitMillis = this.records && this.records.length > 0 ? 0 : 300;
            this._timeout = setTimeout(() => {
                this.search();
            }, waitMillis);
        }
    }

    changeHighlightIndex(indexMoveFunct){
        this.removeHighlight();

        indexMoveFunct(this);
        if(this.searchRecords[this.highlightIndex].id === RECENT){
            indexMoveFunct(this);
        }
        this.addHighlight();

        let currElement = this.template.querySelectorAll('[data-recordid="'+this.searchRecords[this.highlightIndex].id+'"]')[0];
        if (currElement){
            currElement.scrollIntoView({ behavior: 'smooth', block: 'nearest'});
        }
    }

    incrementHighlightIndex(self){
        if (self.highlightIndex <self.searchRecords.length-1){
            self.highlightIndex++;
        } else {
            self.highlightIndex = 0;
        }
    }

    decrementHighlightIndex(self){
        if (self.highlightIndex > 0){
            self.highlightIndex--;
        } else {
            self.highlightIndex = self.searchRecords.length-1;
        }
    }

    removeHighlight(){
        this.searchRecords[this.highlightIndex].showHighlight = false;
        this.searchRecords[this.highlightIndex].listboxOptionClass = "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity";
    }

    addHighlight(){
        this.searchRecords[this.highlightIndex].showHighlight = true;
        this.searchRecords[this.highlightIndex].listboxOptionClass = "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity slds-has-focus";
    }

    async getInvalidLookupMsg() {
        const msg = await this.ctrl.pageCtrl.getMessageWithDefault(
            "LTNG_INVALID_LOOKUP_ERROR",
            "Lightning",
            "Select an option from the picklist or remove the search term"
        );
        return msg;
    }

    async search() {
        let displayRecords;
        const records = await this.getRecords();
        records.forEach(record => {record.name = record.name ? record.name : record[this._ctrl.nameField]});
        if (VeevaUtils.isValidSearchTerm(this.searchTerm)) {
            const name = await this.ctrl.searchTerm(this.searchTerm);
            const showAllLabel = { id: SEARCH, name: name, icon: 'utility:search', xsmall: true };
            const filtered = records.filter(searchItem => searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase()) !== -1 && searchItem.id !== SEARCH)
            this._formatResultText(filtered);
            if (this.searchTerm.length < 3 && filtered.length > 0){
                const recentItemsLabel = { id: RECENT, name: this.recentLabel };
                displayRecords = [showAllLabel, recentItemsLabel, ...filtered];
            } else {
                displayRecords = [showAllLabel, ...filtered];
            }
            displayRecords[0].showHighlight = true;
            this.highlightIndex = 0;
        }
        else {
            if (this.searchTerm.length > 0){
                const filtered = records.filter(searchItem => searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase()) !== -1 && searchItem.id !== SEARCH)
                this._formatResultText(filtered);
                displayRecords = filtered;
            } else {
                records.forEach(searchItem => {
                    searchItem.match = '';
                });
                displayRecords = records;
            }
            if(displayRecords.length > 0){
                const recentItemsLabel = { id: RECENT, name: this.recentLabel };
                displayRecords = [recentItemsLabel, ...displayRecords];
                displayRecords[1].showHighlight = true;
                this.highlightIndex = 1;
            }
        }
        for(let item of displayRecords){
            item.listboxOptionClass = item.showHighlight ? "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity slds-has-focus" : "slds-media slds-media_center slds-listbox__option slds-listbox__option_entity";
        }
        this.searchRecords = displayRecords;
    }

    _formatResultText(results) {
        results.forEach(searchItem => {
            const matchInd = searchItem.name.toLowerCase().indexOf(this.searchTerm.toLowerCase());
            const postSearchTermInd = matchInd + this.searchTerm.length;
            searchItem.preMatch = searchItem.name.substring(0, matchInd);
            searchItem.match = searchItem.name.substring(matchInd, postSearchTermInd);
            searchItem.postMatch = searchItem.name.substring(postSearchTermInd);
        });
    }

    async getRecords() {
        let response = await this.ctrl.search(this.searchTerm);
        if (response.records && response.records.length > 0) {
            this.records = response.records;
        }
        return this.records || [];
    }

    async handleResultClick(event) {
        event.preventDefault();
        let recordId = event.currentTarget.dataset.recordid;
        if (recordId === SEARCH) {
            this.dispatchEvent(new CustomEvent("searchmode", { detail: { search: true, term: this.searchTerm } }));
        }
        else if (recordId !== RECENT){
            this.setSelected(recordId);
            this.dispatchEvent(new CustomEvent("lookupselection", { detail: this.selected }));
            setTimeout(() => { this.template.querySelector("[data-select-term]").focus() }, 100);
        }
    }

    handleClose() {
        if (this._handleBlur){
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.resetSearch(); // does not reset searchTerm per SF behavior
                this.checkValidity();
            }, 300);
        }
    }

    setSelected(recordId) {
        this.selected = this.searchRecords.find(result => result.id === recordId) || {};
        this.searchTerm = '';
        this.resetSearch();
    }

    resetSearch() {
        this.records = null;
        this.searchRecords = [];
        this.hasFocus = false;
    }

    @api checkValidity() {
        const element = this.template.querySelector("lightning-input");
        if (!element) {
            return true;
        }
        this.clearCustomValidityError(element);
        if (element.checkValidity()) {
            this.ctrl.validate();
            element.setCustomValidity(this.ctrl.getError());
        }
        this.checkForUnselectedRecord(element);
        return element.reportValidity();
    }

    clearCustomValidityError(element) {
        // If there was a custom error before, reset it
        if (element.validity.customError) {
            element.setCustomValidity('');
        }
    }

    checkForUnselectedRecord(element) {
        if (this.searchTerm.length !== 0 && !this.selected.id) {
            element.setCustomValidity(this._invalidLookupMsg);
        }
    }

    // styles
    get comboboxClass() {
        let css = this.selected.id ? ' slds-input-has-icon_left-right' : ' slds-input-has-icon_right';
        return `slds-combobox__form-element slds-input-has-icon${css}`;
    }

    get selectedIconClass() {
        return 'slds-icon_container slds-combobox__input-entity-icon';
    }

    get inputTextClass() {
        let css = this.hasFocus ? ' slds-has-focus' : '';
        return `slds-input slds-combobox__input${css}`;
    }

    get searchIconClass() {
        let searchIcon = 'veeva-search__icon';
        if (this.label) {
            searchIcon += '_label';
        }
        return `veeva-input__icon slds-input__icon_right ${searchIcon}`;
    }

    get clearButtonClass() {
        return 'slds-button slds-button_icon slds-input__icon slds-input__icon_right';
    }

    get listboxClass() {
        let classes = [
            'slds-dropdown',
            'slds-dropdown_length-with-icon-5', 
            'slds-dropdown_fluid', 
            'slds-p-around_none',
            'veeva-list-box',
        ];

        if (this.label) {
            classes.push('veeva-list-box__lower');
        }

        return classes.join(' ');
    }

    get containerClass() {
        return `slds-combobox_container`
    }

    get dropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        if (this.hasFocus && !this.selected.id) {
            css += ' slds-is-open';
        }
        return css;
    }

}