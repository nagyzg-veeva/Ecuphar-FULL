export default class EventActionService {

    constructor(dataSvc) {
        this.dataSvc = dataSvc;
    }

    async statusChange(eventId, actionId, data) {
        let path =`/api/v1/em.action/${eventId}/${actionId}`;
        let params = {
            platform:'Online',
            datetimeFormat: data['startDatetime'] && data['endDatetime'] ? 'UTC' : '',
            approverId: data['approverId'] || '',
            buttonName: data['buttonName'] || '',
            startDatetime: data['startDatetime'] || '',
            endDatetime: data['endDatetime'] || ''
        };

        let postData = {
            comment: data['comment'] || ''
        };
        return this.dataSvc.sendRequest('POST', path, params, postData, 'statusChange');
    }

    async getEventAction(eventId, buttonName) {
        let path = `/api/v1/em.action/${eventId}/${buttonName}`;
        return this.dataSvc.sendRequest('GET', path, null, null, 'getEventAction');
    }

    async rescheduleValidation(eventId, currentStartDatetime) {
        let path = `/api/v1/em.action/reschedule/${eventId}`;
        let params = {
            startDatetime: currentStartDatetime,
            datetimeFormat: 'UTC'
        };
        return this.dataSvc.sendRequest('GET', path, params, null, 'rescheduleValidation');
    }
}