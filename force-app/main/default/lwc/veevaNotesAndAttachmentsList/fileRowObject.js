const imgFiles = ['jpg', 'jpeg', 'png', 'pdf'];

const typeToIcon = {
    'csv': 'csv',
    'xls': 'excel',
    'xlsx': 'excel',
    'exe': 'exe',
    'html': 'html',
    'xhtml': 'html',
    'gif': 'image',
    'tiff': 'image',
    'mp4': 'mp4',
    'ppt': 'ppt',
    'psd': 'psd',
    'rtf': 'rtf',
    'txt': 'txt',
    'mov': 'video',
    'mpeg': 'video',
    'doc': 'word',
    'docx': 'word',
    'xml': 'xml',
    'zip': 'zip'
}

export default class FileRowObject {
    _id;
    _name;
    _lastModifiedDate;
    _extLowerCase;
    _isFile;
    _isImageFile;
    _iconSource;
    _thumbUrl;
    _objectTypeLabel;
    _contentSize;
    _sizeUnits;
    _recordPageReference;

    constructor(data, type, meta) {
        this._id = data.Id;
        this._lastModifiedDate = data.LastModifiedDate;

        this.setName(data, type);
        this.setObjectTypeLabel(data, type, meta);
        this.setContentSize(data);
        this.setSizeUnits(data, meta);
        this.setFileExtAndIconSourceProperties(data, type);
        this.setThumbUrl(data);
        this.setRecordPageReference(data, type);
    }

    get id() {
        return this._id;
    }

    get name() {
        return this._name;
    }

    get lastModifiedDate() {
        return this._lastModifiedDate;
    }

    get isFile() {
        return this._isFile;
    }

    get isImageFile() {
        return this._isImageFile;
    }

    get iconSource() {
        return this._iconSource;
    }

    get thumbUrl() {
        return this._thumbUrl;
    }

    get objectTypeLabel() {
        return this._objectTypeLabel;
    }

    get contentSize() {
        return this._contentSize;
    }

    get sizeUnits() {
        return this._sizeUnits;
    }

    get extLowerCase() {
        return this._extLowerCase;
    }

    get recordPageReference() {
        return this._recordPageReference;
    }

    setName(data, type) {
        this._name = type === 'attachment' ? data.Name : data.Title;
    }

    setObjectTypeLabel(data, type, meta) {
        let label = '';
        if (type === 'note') {
            label = meta.noteLabel;
        }
        if (type === 'attachment') {
            label = meta.attachmentLabel;
        }
        this._objectTypeLabel = label;
    }

    setContentSize(data) {
        let displaySize = Math.floor(data.ContentSize / 1000);
        if (displaySize > 1000) {
            displaySize = (displaySize / 1000).toFixed(1); 
        }

        this._contentSize = '' + displaySize;
    }

    setSizeUnits(data, meta) {
        let unitLabel = meta.megaByteLabel;
        if (data.ContentSize / 1000 < 1000) {
            unitLabel = meta.kiloByteLabel;
        }
        this._sizeUnits = unitLabel;
    }

    setFileExtAndIconSourceProperties(data, type) {
        this._extLowerCase = data.FileType && data.FileType.toLowerCase();
        this._isFile = type === 'file';    
        this._isImageFile = this._isFile && imgFiles.indexOf(this._extLowerCase) >= 0;

        let icon;
        if (type === 'note') {
            icon = 'stypi';
        } else if (type === 'attachment') {
            icon = 'attachment';
        } else {
            icon = typeToIcon[this._extLowerCase] || 'unknown';
        }
        this._iconSource = `doctype:${icon}`;
    }

    setThumbUrl(data) {
        let url = '';
        const contentVersion = data.ContentVersions && data.ContentVersions[0];
        if (contentVersion) {
            url = `/sfc/servlet.shepherd/version/renditionDownload?` +
                    `rendition=THUMB120BY90&versionId=${contentVersion.Id}&operationContext=CHATTER&contentId=${contentVersion.ContentBodyId}&page=0`;
        }
        this._thumbUrl = url;
    }   

    setRecordPageReference(data, type) {
        let objectType;
        if (type === 'note') {
            objectType = 'Note';
        }
        if (type === 'attachment') {
            objectType = 'Attachment';
        }
        if (type === 'file') {
            objectType = 'File';
        }
        this._recordPageReference = {
            type: 'standard__recordPage',
            attributes: { 
                recordId: data.Id,
                objectApiName: objectType,
                actionName: 'view'
             }
        };
    }
}