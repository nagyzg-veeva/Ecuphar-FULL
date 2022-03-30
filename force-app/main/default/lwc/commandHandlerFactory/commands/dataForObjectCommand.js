import CommandHandler from "./commandHandler";
import UserId from "@salesforce/user/Id";
import getFirstTSFIdMatchingUserTerritoryNames from "@salesforce/apex/MyInsightsService.getFirstTSFIdMatchingUserTerritoryNames";


const SUPPORTED_OBJECTS_BY_RECORD_OBJECT_NAME = {
    "": ["user", "html_report_vod__c"], // default supported objects
    "account": ["account", "tsf_vod__c", "user", "html_report_vod__c"],
    "account_plan_vod__c": ["account_plan_vod__c", "account", "user", "html_report_vod__c"],
    "order_vod__c": ["order_vod__c", "account", "tsf_vod__c", "user", "html_report_vod__c"],
    "inventory_monitoring_vod__c": ["inventory_monitoring_vod__c", "account", "tsf_vod__c", "user", "html_report_vod__c"]
};

const SUPPORTED_KEYWORDS = {
    "htmlreport": "HTML_Report_vod__c",
    "order": "Order_vod__c",
    "tsf": "TSF_vod__c",
    "inventorymonitoring": "Inventory_Monitoring_vod__c",
    "accountplan": "Account_Plan_vod__c"
}

const DEFAULT_SUPPORTED_OBJECTS = SUPPORTED_OBJECTS_BY_RECORD_OBJECT_NAME[""];

export default class DataForObjectCommand extends CommandHandler {

    constructor(veevaUserInterfaceAPI, myInsightsPageController) {
        super(veevaUserInterfaceAPI);
        this.myInsightsPageController = myInsightsPageController;
    }

    async response(queryConfig) {
        const { object, fields } = queryConfig;
        return this.getDataForObject(object, fields, queryConfig);
    }

    async getDataForObject(objectNameOrKeyword, fields, queryConfig) {
        const objectNameForCurrentPage = this.myInsightsPageController.objectApiName;
        const supportedObjectForRecordObjectName = this.getSupportedObjectsForRecordObjectName(objectNameForCurrentPage);
        const objectName = this.getObjectNameFromSupportedKeywords(objectNameOrKeyword);
        const objectNameLowerCase = objectName?.toLowerCase();
        if (!supportedObjectForRecordObjectName.find(supportedObjectName => supportedObjectName === objectNameLowerCase)) {
            this.throwCommandError(`getDataForCurrentObject request failed: Cannot retrieve ${objectNameOrKeyword} for current object ${objectNameForCurrentPage}`)
        }

        const record = await this.getRecordsWithFields(objectName, fields, queryConfig);
        const formattedRecord = this.formatRecordResponse(objectNameOrKeyword, record, fields);
        return formattedRecord;
    }

    async getRecordsWithFields(object, fields, queryConfig) {
        const objectNameForRecordPageLowerCase = this.myInsightsPageController.objectApiName?.toLowerCase();
        const objectLowerCase = object.toLowerCase();
        let record;
        if (objectLowerCase === objectNameForRecordPageLowerCase) {
            record = await this.recordForSameObject(fields);
        } else if (objectLowerCase === "user") {
            record = await this.recordForUser(fields);
        } else if (objectLowerCase === "tsf_vod__c") {
            record = await this.recordForTSF(fields);
        } else if (objectLowerCase === "account") {
            record = await this.recordForAccount(fields);
        } else if (objectLowerCase === "html_report_vod__c") {
            record = await this.recordForHTMLReport(fields, queryConfig);
        } else {
            this.throwCommandError(`No support for ${object}`);
        }
        return record;
    }

    async recordForSameObject(fields) {
        const objectName = this.myInsightsPageController.objectApiName;
        const recordId = this.myInsightsPageController.id;
        const referenceRecord = this.myInsightsPageController.record;
        const fieldsToRetrieve = this.fieldsWithObjectName(fields, objectName, referenceRecord);
        await this.addMissingFields(fieldsToRetrieve);
        const record = {
            apiName: objectName,
            fields: referenceRecord.fields
        };
        record.fields.Id = { value: recordId };
        return record;
    }

    async recordForUser(fields) {
        return this.retrieveRecordWithFields(UserId, fields, "User");
    }

    async recordForTSF(fields) {
        const accountId = await this.getAccountId();
        const tsfId = await this.pickTSFId(accountId);
        if (!tsfId) {
            this.throwCommandError("Cannot find related TSF_vod__c record");
        }
        return this.retrieveRecordWithFields(tsfId, fields, "TSF_vod__c");
    }

    async recordForAccount(fields) {
        const accountId = await this.getAccountId();
        return this.retrieveRecordWithFields(accountId, fields, "Account");
    }

    async recordForHTMLReport(fields) {
        const htmlReportId = this.myInsightsPageController.htmlReportId;
        if (!htmlReportId) {
            this.throwCommandError("Failed to retrieve HTML Report information. This may be due to a configuration issue.")
        }
        return this.retrieveRecordWithFields(htmlReportId, fields, "HTML_Report_vod__c");
    }

    async retrieveRecordWithFields(recordId, fields, objectName) {
        const fieldsToRetrieve = this.fieldsWithObjectName(fields, objectName);
        let retrievedRecord = {};
        if (fieldsToRetrieve.length > 0) {
            retrievedRecord = await this.retrieveRecord(recordId, fieldsToRetrieve, objectName);
        }
        const record = {
            apiName: retrievedRecord.apiName,
            fields: retrievedRecord.fields || {}
        };
        record.fields.Id = { value: recordId };
        return record;
    }

    async getAccountId() {
        const objectName = this.myInsightsPageController.objectApiName;
        let accountId;
        if (objectName !== "Account") {
            accountId = await this.retrieveAccountIdFromNonAccountObject(accountId);
        } else {
            accountId = this.myInsightsPageController.id;
        }
        return accountId;
    }

    async retrieveAccountIdFromNonAccountObject() {
        const objectInfo = this.myInsightsPageController.objectInfo;
        const accountReferenceFieldName = Object.keys(objectInfo.fields)
            .filter(fieldName => objectInfo.fields[fieldName].dataType.toLowerCase() === "reference")
            .find(fieldName => objectInfo.fields[fieldName].referenceToInfos.filter(ref => ref.apiName === "Account"));
        const recordWithAccountId = await this.recordForSameObject([accountReferenceFieldName]);
        return recordWithAccountId.fields[accountReferenceFieldName].value;
    }

    async pickTSFId(accountId) {
        return getFirstTSFIdMatchingUserTerritoryNames({ accountId: accountId });
    }

    fieldsWithObjectName(fields, objectName, referenceRecord) {
        const lowerCaseRecordFields = this.getLowerCaseFieldSet(referenceRecord);
        return fields
            .filter(field => field && field.toLowerCase() !== "id")
            .filter(field => !referenceRecord || !lowerCaseRecordFields.has(field.toLowerCase()))
            .map(field => `${objectName}.${field}`);
    }

    async addMissingFields(fieldsToRetrieve) {
        const recordId = this.myInsightsPageController.id;
        const record = this.myInsightsPageController.record;
        if (fieldsToRetrieve.length > 0) {
            const retrievedRecord = await this.retrieveRecord(recordId, fieldsToRetrieve, this.myInsightsPageController.objectApiName);
            Object.keys(retrievedRecord.fields).forEach(fieldName => {
                record.fields[fieldName] = retrievedRecord.fields[fieldName];
            });
        }
        return record;
    }

    async retrieveRecord(recordId, fieldsToRetrieve, objectName) {
        const record = (await this.veevaUserInterfaceApi.getBatchRecords([recordId], fieldsToRetrieve))[0];
        // If we could not retrieve data for the recordId this means that we do not have access to the record.
        // We will check if record is an array as it will be an error with error codes on error 
        if (!record || (Array.isArray(record) && record[0].errorCode)) {
            this.throwCommandError(`getDataForCurrentObject request failed: User does not have access to ${objectName} for current object`);
        }
        return record;
    }

    formatRecordResponse(object, record, fields) {
        const formattedResponse = { success: true };
        const lowerCaseFieldsToValues = this.getLowerCaseFieldToValues(record);
        const fieldsForObject = {};
        fields
            .filter(field => field)
            .forEach(field => {
                const lowerCaseField = field.toLowerCase();
                if (lowerCaseField === "id") {
                    fieldsForObject.ID = lowerCaseFieldsToValues.id;
                    fieldsForObject[field] = lowerCaseFieldsToValues.id;
                } else {
                    fieldsForObject[field] = lowerCaseFieldsToValues[lowerCaseField];
                }
            });
        formattedResponse[object] = fieldsForObject;
        formattedResponse[record.apiName] = fieldsForObject;
        formattedResponse.record_count = 1;
        return formattedResponse;
    }

    /**
     * Takes the fields in record and creates a set of lower case fields.
     * This will allow us to perform case insensitive field checks.
     * @returns {Set} returns a set of lower case fields from record
     */
    getLowerCaseFieldToValues(record) {
        const lowerCaseFieldsToValues = {};
        if (record && record.fields) {
            Object.entries(record.fields)
                .forEach(([field, fieldValue]) => {
                    const lowerCaseField = field.toLowerCase();
                    lowerCaseFieldsToValues[lowerCaseField] = fieldValue.value;
                });
        }
        return lowerCaseFieldsToValues;
    }

    /**
     * Takes the fields in record and creates a set of lower case fields.
     * This will allow us to perform case insensitive field checks.
     * @returns {Set} returns a set of lower case fields from record
     */
    getLowerCaseFieldSet(record) {
        const lowerCaseFields = new Set();
        if (record && record.fields) {
            Object.keys(record.fields)
                .map(field => field.toLowerCase())
                .forEach(field => lowerCaseFields.add(field));
        }
        return lowerCaseFields;
    }

    /**
     * Determines the list of objects that we can retrieve data for from a given object name.
     *
     * @param {String?} objectNameForCurrentPage the object name of the current page
     * @returns {String[]} a lower case string array representing the objects that we can get data for from the objectNameForCurrentPage
     */
    getSupportedObjectsForRecordObjectName(objectNameForCurrentPage) {
        objectNameForCurrentPage = objectNameForCurrentPage ?? "";
        const supportedObjectForRecordObjectName = SUPPORTED_OBJECTS_BY_RECORD_OBJECT_NAME[objectNameForCurrentPage.toLowerCase()] ?? DEFAULT_SUPPORTED_OBJECTS;
        return supportedObjectForRecordObjectName;
    }

    getObjectNameFromSupportedKeywords(objectNameOrKeyword) {
        const objectNameOrKeywordLowerCase = objectNameOrKeyword?.toLowerCase();
        const keywordAndObjectNameEntry = Object.entries(SUPPORTED_KEYWORDS)
            .find(([supportedKeyword]) => supportedKeyword === objectNameOrKeywordLowerCase);
        return keywordAndObjectNameEntry ?  keywordAndObjectNameEntry[1] : objectNameOrKeyword;
    }
}