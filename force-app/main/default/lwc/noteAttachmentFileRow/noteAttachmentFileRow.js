import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

export default class NoteAttachmentFileRow extends NavigationMixin(LightningElement) {
    @api row;

    @api get name() {
        return this.row.name;
    }  

    @api get lastModifiedDate() {
        return this.row.lastModifiedDate;
    }

    @api get isFile() {
        return this.row.isFile;
    }

    @api get isImageFile() { 
        return this.row.isImageFile;
    }

    @api get iconSource() {
        return this.row.iconSource;
    }

    @api get thumbUrl() {
        return this.row.thumbUrl;
    }

    @api get objectTypeLabel() {
        return this.row.objectTypeLabel;
    }

    @api get contentSize() {
        return this.row.contentSize;
    }

    @api get sizeUnits() {
        return this.row.sizeUnits;
    }

    @api get extLowerCase() {
        return this.row.extLowerCase;
    }

    redirectToDoc() {
        const blah = this[NavigationMixin.Navigate](this.row.recordPageReference);
        return '' + blah;
    }
}