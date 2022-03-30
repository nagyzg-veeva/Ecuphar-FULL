import VeevaBaseController from "c/veevaBaseController";

export default class VeevaRowController extends VeevaBaseController {
    constructor(meta, ctrl) {
        super(meta, ctrl);
        this.row = true;
        this.oneColumn = meta.layoutItems.length === 1;
    }
}