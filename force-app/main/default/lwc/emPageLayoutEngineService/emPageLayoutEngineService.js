import VeevaLayoutService from 'c/veevaLayoutService';

export default class EmPageLayoutEngineService {
    constructor(dataSvc) {
        this.dataSvc = dataSvc;
    }

    //EM Specific request to CRM for page layout, other areas should be using lightning ui-api
    async getPageLayout(object, action, id, params=null) {
        let path = `/api/v1/lex/ple/${object}/`;
        if (action === 'View') {
            path += `${id}`;
        } else if (action === 'Edit') {
            path += `${id}/e`;
        } else { //New
            path += 'n';
        }
        const layout = await this.dataSvc.sendRequest('GET', path, params, null, 'getEmPageLayout');
        layout.buttons = VeevaLayoutService.describeToButtons(layout.buttons);
        return VeevaLayoutService.toVeevaLayout(layout, action);
    }
}