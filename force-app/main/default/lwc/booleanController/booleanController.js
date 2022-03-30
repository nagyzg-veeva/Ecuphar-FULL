import FieldController from "c/fieldController";

export default class BooleanController extends FieldController {
    initTemplate() {
        this.veevaFieldCheckbox = true;
        return this;
    }
}