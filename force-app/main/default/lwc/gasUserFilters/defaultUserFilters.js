import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_SPECIALTY_FIELD from '@salesforce/schema/Account.Specialty_1_vod__c';
import ACCOUNT_CREDENTIALS_FIELD from '@salesforce/schema/Account.Credentials_vod__c';

export default [
    {
        key: `${ACCOUNT_OBJECT.objectApiName}.${ACCOUNT_SPECIALTY_FIELD.fieldApiName}`,
        objectApiName: ACCOUNT_OBJECT.objectApiName,
        fieldApiName: ACCOUNT_SPECIALTY_FIELD.fieldApiName,
        label: 'Specialty',
        options: [],
        selectedOptions: []
    },
    {
        key: `${ACCOUNT_OBJECT.objectApiName}.${ACCOUNT_CREDENTIALS_FIELD.fieldApiName}`,
        objectApiName: ACCOUNT_OBJECT.objectApiName,
        fieldApiName: ACCOUNT_CREDENTIALS_FIELD.fieldApiName,
        label: 'Credentials',
        options: [],
        selectedOptions: []
    }
]