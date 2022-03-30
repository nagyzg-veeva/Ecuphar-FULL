import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import ControllerFactory from 'c/controllerFactory';
import VeevaConstant from 'c/veevaConstant';
import VeevaUtils from 'c/veevaUtils';

// TODO customized icon
export default class VeevaHighlightPanel extends LightningElement {
    @api objectApiName;
    @api recordId;
    @track pageCtrl;
    @track page = {};
    @track buttons;
    @track displayButtons = [];
    @track menuButtons = [];
    
    @track compactLayoutMetadata;
    @track compactLayoutFields;
    @api isNonPrimaryHighlightPanel;

    MAX_DISPLAY_BUTTONS = 3;

    connectedCallback() {
        registerListener(VeevaConstant.PUBSUB_RECORD_READY, this.handleRecordReady, this);
        registerListener(VeevaConstant.PUBSUB_LAYOUT_READY, this.handleLayoutReady, this);
        window.addEventListener('scroll', this.handleScroll.bind(this));
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
        window.removeEventListener('scroll', this.handleScroll.bind(this));
    }

    async handleRecordReady(pageCtrl) {
        this._setPageCtrl(pageCtrl);
        this.page = pageCtrl.page;
        this.compactLayoutMetadata = await pageCtrl.getCompactLayoutMetadata();
        this.initCompactLayoutModel(this.compactLayoutMetadata);
        this.page.icon = pageCtrl.getPageIcon();
        this.page.subtitle = this.getPageSubtitle();
        this.page.title = pageCtrl.getPageTitle();
    }

    async handleLayoutReady(pageCtrl) {
        this._setPageCtrl(pageCtrl);
        this.buttons = await this.pageCtrl.getHeaderButtons();
        this.processButtons(this.buttons);
    }
    
    processButtons(buttons) {
        const displayCutoff = (this.pageCtrl && this.pageCtrl.disableButtonMenu) ? 
            buttons.length : this.MAX_DISPLAY_BUTTONS;
        this.displayButtons = buttons.slice(0, displayCutoff); //if 2nd index is out of bounds, returns the original array
        this.menuButtons = buttons.slice(displayCutoff); //if index is out of bounds, returns empty array
        this.menuButtons.forEach((button) => {
            button.menu = true;
        });
    }

    _setPageCtrl(pageCtrl) {
        if (!this.pageCtrl) {
            this.pageCtrl = pageCtrl;
        }
    }

    initCompactLayoutModel(compactLayoutMetadata) {
        this.compactLayoutFields = [];
        for (let index in compactLayoutMetadata) {
            if (index === '0') {
                continue; //skip first since its displayed in subtitle
            }
            let field = compactLayoutMetadata[index];
            let ctrl = ControllerFactory.itemController({ field: field.apiName, label: field.label}, this.pageCtrl, this.pageCtrl.record);
            ctrl.initTemplate();
            this.compactLayoutFields.push({
                apiName: field.apiName,
                ctrl: ctrl
            });
        }
    }

    renderedCallback(){
        const pageHeader = this.template.querySelector('.slds-page-header');
        const spacer = this.template.querySelector('.spacer');        
        spacer.style.height = pageHeader.offsetHeight+'px';
    }

    getPageSubtitle() {
        let subTitle = this.pageCtrl.getPageSubtitle();
        if (this.compactLayoutMetadata && this.compactLayoutMetadata.length > 0 && this.compactLayoutMetadata[0].apiName) {
            const fieldName = this.compactLayoutMetadata[0].apiName;
            subTitle = this.pageCtrl.record.displayValue(fieldName);
            if (this.pageCtrl.objectInfo.getFieldInfo(fieldName)?.dataType === 'Reference' && VeevaUtils.validSfdcId(subTitle)) {
                const lookupTo = this.pageCtrl.record.reference({ apiName: fieldName, relationshipName: this.pageCtrl.objectInfo.fields[fieldName].relationshipName } );
                subTitle = lookupTo.name;
                this.page.subtitleUrl = '/'+lookupTo.id;
                this.isSubtitleLookup = true;
            }
        }
        return subTitle;
    }

    get showCompactLayout() {
        return this.compactLayoutFields && this.compactLayoutFields.length > 0;
    }

    handleScroll(){
        if(!this.isNonPrimaryHighlightPanel){
            if (this.showCompactLayout){
                this.compactLayoutScroll();
            } else {
                this.noCompactLayoutScroll();
            }
        }
    }

    noCompactLayoutScroll(){
        const highlightPanel = this.template.querySelector('.highlight-panel');
        const highlightPanelButtons = this.template.querySelector('.highlight-panel-buttons');
        
        let position = 'position: fixed;';
        let zIndex = 'z-index: 98;'
        let leftStyle = 'left: -1px;';
        let rightStyle = 'right: -2px;';
        let topMargin = 'margin-top: -13px';
        let leftPadding = 'padding-left: 13px;';
        let rightPadding = 'padding-right: 14px';

        if (window.scrollY <= 11){
            leftPadding = 'padding-left: ' + (1 + window.scrollY) + 'px;';
            rightPadding = 'padding-right: ' + (1 + window.scrollY) + 'px;';

            leftStyle = 'left: ' + (11 - window.scrollY) + 'px;';
            rightStyle = 'right: ' + (11 - window.scrollY) + 'px;';
            topMargin = 'margin-top: ' + (-window.scrollY - 1) + 'px';
        } 
        highlightPanel.style.cssText = position + zIndex + leftStyle + rightStyle + topMargin;
        highlightPanelButtons.style.cssText = leftPadding + rightPadding;
    }

    compactLayoutScroll(){
        const highlightPanel = this.template.querySelector('.highlight-panel');
        const highlightPanelButtons = this.template.querySelector('.highlight-panel-buttons');
        const compactLayout = this.template.querySelector('.compact_layout');

        let position = 'position: fixed;';
        let zIndex = 'z-index: 98;'
        let leftStyle = 'left: -1px;';
        let rightStyle = 'right: -2px;';
        let topMargin = 'margin-top: -13px';
        let leftPadding = 'padding-left: 13px;';
        let rightPadding = 'padding-right: 14px';

        let opacity = 'opacity: 0.0;';
        let compactTopMargin = 'margin-top: -72.0px;';
        let compactVisibility = 'visibility: hidden';
        //At window.scrollY == 82 the header stops collapsing, and remains static/sticky for all greater scroll values
        if (window.scrollY <= 82){
            //While window.scrollY <= 12 the header is at full height and moves upward, the compact layout is fully visible
            if (window.scrollY <= 12){ 
                opacity = 'opacity: 1.0;';
                compactTopMargin = 'margin-top: 0.0px;';
                topMargin = 'margin-top: '+ (-window.scrollY - 1) + 'px';
            } else {
                opacity = 'opacity: ' + (1 - (0.03 * (window.scrollY - 12))) + ';';
                compactTopMargin = 'margin-top: ' + (-(window.scrollY - 12)) + 'px;';
            }
            //The header panel is hidden past this level of scroll.
            if(window.scrollY <= 45){
                compactVisibility = 'visibility: visible';
            }
            //At window.scrollY >= 71 the header stops expanding horizontally, and the compact layout fields are hidden
            if (window.scrollY <= 71){
                leftPadding = 'padding-left: ' + (1 + (window.scrollY / 6)) + 'px;';
                rightPadding = 'padding-right: ' + (1 + (window.scrollY / 6)) + 'px;';
                leftStyle = 'left: ' + (11 - (window.scrollY / 6)) + 'px;';
                rightStyle = 'right: ' + (11 - (window.scrollY / 6)) + 'px;';
            }
        }

        highlightPanel.style.cssText = position + zIndex + leftStyle + rightStyle + topMargin;
        highlightPanelButtons.style.cssText = leftPadding + rightPadding;
        compactLayout.style.cssText = opacity + compactTopMargin + compactVisibility;
    }
}