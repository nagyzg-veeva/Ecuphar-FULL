import VeevaRelatedListController from 'c/veevaRelatedListController';
import VeevaConstant from 'c/veevaConstant';

export default class EmRelatedListController extends VeevaRelatedListController {

    constructor(meta, pageCtrl) {
        super(meta, pageCtrl);
    }

    async getRowActions(row, doneCallback) {
        let actions = row.actions;
        try {
            if (!actions) {
                actions = [];
                let layout = await row.ctrl.pageCtrl.emPageLayoutEngineSvc.getPageLayout(row.ctrl.meta.objectApiName, 'View', row.Id);
                let buttons = layout.buttons;
                if (row.isUpdateable && buttons.some(button => button.name === VeevaConstant.EDIT)) {
                    const editMessage = await row.ctrl.pageCtrl.getMessageWithDefault('Edit', 'Common', 'Edit');
                    actions.push({ label: editMessage, name: 'edit' });
                }
                if (row.isDeletable && buttons.some(button => button.name === VeevaConstant.DELETE)) {
                    const deleteMessage = await row.ctrl.pageCtrl.getMessageWithDefault('DELETE', 'Common', 'Delete');
                    actions.push({ label: deleteMessage, name: 'delete' });
                }
                if (actions.length == 0) {
                    const noActionsMessage = await row.ctrl.pageCtrl.getMessageWithDefault('NO_ACTIONS', 'Common', 'No actions available');
                    actions.push({ label: noActionsMessage, name: 'noActions', disabled: true });
                }
                row.actions = actions;
            }
        } finally {
            doneCallback(actions);
        }
    }

    getInContextOfRefForNew() {
        const inContextOfRef = super.getInContextOfRefForNew();

        const defVals = {};
        if (this.pageCtrl?.record?.fields?.Event_vod__r?.value?.id) {
            defVals.Event_vod__c = {
                value: this.pageCtrl.record.fields.Event_vod__r.value.id,
                displayValue: this.pageCtrl.record.fields.Event_vod__r.displayValue,
            };
        } else if (this.pageCtrl?.record?.fields?.Event_vod__c) {
            defVals.Event_vod__c = this.pageCtrl.record.fields.Event_vod__c;
        }
        inContextOfRef.emDefaultFieldValues = defVals;

        return inContextOfRef;
    }
}