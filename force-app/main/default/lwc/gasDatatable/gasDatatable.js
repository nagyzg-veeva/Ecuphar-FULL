import LightningDatatable from 'lightning/datatable';
import accountNameDisplay from './accountNameDisplay.html';

export default class GasDatatable extends LightningDatatable {
    static customTypes = {
        'account-name-display': {
            template: accountNameDisplay,
            standardCellLayout: true,
            typeAttributes: ['id', 'isButton', 'clickHandler', 'recordTypeIconUrl', 'recordTypeName']
        }
    }
}