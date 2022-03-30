import ReferenceController from "c/referenceController";

export default class MultiObjectReferenceController extends ReferenceController {

    selectedObject = {};

    constructor(objectType, meta, pageCtrl, field, record) {
        super(meta, pageCtrl, field, record);
        this.objectType = objectType;
    }

    get targetSObject() {
        return this.selectedObject.value;
    }
}