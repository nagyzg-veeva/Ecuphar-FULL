import CommandHandler from "./commandHandler";

export default class RecordTypeLabelsCommand extends CommandHandler {

    async response(queryConfig) {
        const objectName = queryConfig.object;
        const recordTypeLabelsByRecordTypeName = await this.getRecordTypeLabelsByRecordTypeName(objectName);
        return recordTypeLabelsByRecordTypeName;
    }

    async getRecordTypeLabelsByRecordTypeName(objectName) {
        const recordTypes = await this.getRecordTypes(objectName)
        // The existing (non-LEX) MyInsights behavior is to retrieve all including
        // records the user doesn't have access to, but we do not return the Master
        const recordTypeIds = this.getNonMasterRecordTypeIds(recordTypes);
        if (recordTypeIds.length === 0) {
            return { [objectName]: {} }
        }
        return {
            [objectName]: await this.getRecordTypeNameByDeveloperName(recordTypeIds)
        };
    }

    getNonMasterRecordTypeIds(recordTypes) {
        return recordTypes
            .filter(recordType => !recordType.master)
            .map(recordType => recordType.recordTypeId);
    }

    async getRecordTypeNameByDeveloperName(recordTypeIds) {
        const recordTypeNameByDeveloperName = {};
        const recordTypes = await this.veevaUserInterfaceApi.getBatchRecords(recordTypeIds, [
            "RecordType.DeveloperName",
            "RecordType.Name",
        ]);
        recordTypes.forEach(recordType => {
            const recordTypeFields = recordType.fields;
            const name = recordTypeFields.Name.displayValue;
            const developerName = recordTypeFields.DeveloperName.value;
            recordTypeNameByDeveloperName[developerName] = name;
        });
        return recordTypeNameByDeveloperName;
    }
}