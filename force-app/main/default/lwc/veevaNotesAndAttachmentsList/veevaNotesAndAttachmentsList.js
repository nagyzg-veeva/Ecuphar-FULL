import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import VeevaConstant from "c/veevaConstant";
import getMsgWithDefault from "@salesforce/apex/VeevaMessageController.getMsgWithDefault";
import fetchNotes from '@salesforce/apex/NotesAttachmentsFilesController.fetchNotes';
import fetchAttachments from '@salesforce/apex/NotesAttachmentsFilesController.fetchAttachments';
import fetchFiles from '@salesforce/apex/NotesAttachmentsFilesController.fetchFiles';
import FileRowObject from './fileRowObject.js';

export default class VeevaNotesAndAttachmentsList extends NavigationMixin(LightningElement) {
    @api recordId;

    @track readOnly;
    @track listMeta;
    @track notesAttachmentsFiles = [];
    @track viewAllUrl = '#';
    @track viewAllText;

    connectedCallback() {
        registerListener(VeevaConstant.PUBSUB_RECORD_READY, this.handleRecordReady, this);
        this.redirectUrl = {
            type: 'standard__recordRelationshipPage',
            attributes: {
                'recordId': this.recordId,
                'relationshipApiName': 'CombinedAttachments',
                'actionName': 'view'
            }
        };
        // Generate View All's href value so user can open in a new tab
        this[NavigationMixin.GenerateUrl](this.redirectUrl) 
            .then((url) => { this.viewAllUrl = url });
        this.fetchViewAllLabelText();
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleUploadFinished() {
        this.fetchNotesAttachmentsFiles(this.recordId);
    }

    redirectToListView() {
        this[NavigationMixin.Navigate](this.redirectUrl);
    }

    handleViewAllClick(event) {
        // Do not follow href link
        event.preventDefault();
        // Prevent click bubbling up in the DOM
        event.stopPropagation();
        // Navigate to list view page
        this.redirectToListView();
    }

    get headerCss() {
        const noActionClass = this.readOnly ? 'link-no-action' : '';
        return `slds-card__header-link baseCard__header-title-container ${noActionClass}`;
    }

    get recordCount() {
        if (this.notesAttachmentsFiles && this.notesAttachmentsFiles.length > 0) {
            return `(${this.notesAttachmentsFiles.length})`;
        }
        return '';
    }

    async handleRecordReady(pageCtrl) {
        this.readOnly = !pageCtrl.objectInfo.updateable || pageCtrl.record.isLocked;
        const relatedListsResponse = await pageCtrl.uiApi.getRelatedLists(pageCtrl.objectApiName, pageCtrl.record.recordTypeId);
        if (relatedListsResponse && relatedListsResponse.relatedLists) {
            relatedListsResponse.relatedLists.forEach(async listResponse => {
                if (listResponse.objectApiName === 'CombinedAttachment') {
                    this.listMeta = await this.createListMeta(listResponse, pageCtrl);
                    this.fetchNotesAttachmentsFiles(pageCtrl.id);
                }
            });
        }
    }
    
    async createListMeta(listMeta, pageCtrl) {
        const listMetaClone = JSON.parse(JSON.stringify(listMeta));
        const noteObjMetaPromise = pageCtrl.uiApi.objectInfo('Note');
        const attachmentMsgPromise = getMsgWithDefault({
            key: "ATTACHMENT",
            category: "ATTACHMENT",
            defaultMessage: "Attachment"
        });
        const kiloBytePromise = getMsgWithDefault({
            key: "KB",
            category: "TABLET",
            defaultMessage: "KB"
        });
        const megaBytePromise = getMsgWithDefault({
            key: "MB",
            category: "TABLET",
            defaultMessage: "MB"
        });
        const [noteObjMeta, attachmentMsg, kiloByteMsg, megaByteMsg] = await Promise.all([noteObjMetaPromise, 
            attachmentMsgPromise, kiloBytePromise, megaBytePromise]);
        listMetaClone.noteLabel = noteObjMeta.label;
        listMetaClone.attachmentLabel = attachmentMsg;
        listMetaClone.kiloByteLabel = kiloByteMsg;
        listMetaClone.megaByteLabel = megaByteMsg;
        return listMetaClone;
    }
    
    async fetchNotesAttachmentsFiles(recordId) {
        this.notesAttachmentsFiles = [];
        const notesPromise = fetchNotes({ 'recordId': recordId });
        const attachmentsPromise = fetchAttachments({ 'recordId': recordId });
        const filesPromise = fetchFiles({ 'recordId': recordId });

        const [notes, attachments, files] = await Promise.all([notesPromise, attachmentsPromise, filesPromise]);
        const docEntities = [];
        if (notes) {
            JSON.parse(JSON.stringify(notes)).forEach(note => {
                note.type = 'note';
                docEntities.push(new FileRowObject(note, 'note', this.listMeta));
            });
        }
        if (attachments) {
            JSON.parse(JSON.stringify(attachments)).forEach(attachment => {
                attachment.type = 'attachment';
                docEntities.push(new FileRowObject(attachment, 'attachment', this.listMeta));
            });
        }
        if (files) {
            JSON.parse(JSON.stringify(files)).forEach(file => {
                file.type = 'file';
                docEntities.push(new FileRowObject(file, 'file', this.listMeta));
            });
        }
        docEntities.sort(function (docA, docB) {
            //sort by lastModifiedDate, descending
            return docA.lastModifiedDate.localeCompare(docB.lastModifiedDate) * -1;
        });
        this.notesAttachmentsFiles = docEntities;
    }

    async fetchViewAllLabelText() {
        this.viewAllText = await getMsgWithDefault({
            key: "LTNG_VIEW_ALL",
            category: "Lightning",
            defaultMessage: "View All"
        });
    }
}