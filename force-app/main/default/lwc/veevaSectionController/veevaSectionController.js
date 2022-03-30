import VeevaBaseController from "c/veevaBaseController";

export default class VeevaSectionController extends VeevaBaseController {
    constructor(meta, pageCtrl) {
        super(meta, pageCtrl, pageCtrl.record);
        this.veevaSection = true;
    }

    get title() {
        return this.meta.heading;
    }
}