import LightningDatatable from 'lightning/datatable';
import nameLinkCell from './nameLinkCell.html';

export default class VeevaDatatable extends LightningDatatable {
    static customTypes = {
        nameLink: {
            template: nameLinkCell,
            typeAttributes: ['id']
        }
    };
}