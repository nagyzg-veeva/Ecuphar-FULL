import ReferenceController from "c/referenceController";
import PicklistController from "c/picklistController";
import FieldController from "c/fieldController";
import BooleanController from "c/booleanController";
import VeevaSectionController from "c/veevaSectionController";
import VeevaBaseController from "c/veevaBaseController";
import VeevaRelatedListController from 'c/veevaRelatedListController';
import EmRelatedListController from 'c/emRelatedListController';
import EmEventConstant from 'c/emEventConstant';

export default class ControllerFactory {

    static itemController = (item, pageCtrl, record) => {
        let result;
        if (item.field) {
            let field = pageCtrl.objectInfo.getFieldInfo(item.field);
            if (field && field.dataType) {
                switch (field.dataType) {
                    case "Reference":
                        result = new ReferenceController(item, pageCtrl, field, record);
                        break;
                    case "Boolean":
                        result = new BooleanController(item, pageCtrl, field, record);
                        break;
                    case "Picklist":
                    case "MultiPicklist":
                        result = new PicklistController(item, pageCtrl, field, record);
                        break;
                    default:
                        result = new FieldController(item, pageCtrl, field, record);
                }
            }
        }
        return result || new VeevaBaseController(item, pageCtrl, record);
    }

    static sectionController = (meta, pageCtrl) => {
        return new VeevaSectionController(meta, pageCtrl);
    }

    static relatedListController = (meta, pageCtrl) => {
        let ctrl = new VeevaRelatedListController(meta, pageCtrl);
        if (EmEventConstant.PLE_SUPPORTED_OBJECTS.includes(meta.objectApiName)) {
            ctrl = new EmRelatedListController(meta, pageCtrl);
        }
        return ctrl;
    }
}