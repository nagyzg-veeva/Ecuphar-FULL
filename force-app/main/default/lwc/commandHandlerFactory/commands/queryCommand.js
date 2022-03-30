import CommandError from "c/commandError";
import CommandHandler from "./commandHandler";


export default class QueryCommand extends CommandHandler {

    constructor(veevaUserInterfaceApi, querySvc) {
        super(veevaUserInterfaceApi);
        this.querySvc = querySvc;
    }

    async response(queryConfig) {
        const {
            object,
            fields,
            where,
            sort,
            limit
        } = queryConfig;
        const queryResult = await this.runQuery(object, fields, where, sort, limit);
        return this.formatResponse(object, queryResult, fields);
    }

    async runQuery(object, fields, where, sort, limit) {
        const userAccessibleFields = await this.getUserAccessibleFields(object, fields);
        if (userAccessibleFields.length === 0) {
            this.throwCommandError("Fields provided are empty or User does not have access to fields");
        }
        const commaSeparatedFields = userAccessibleFields.join(",");
        let query = `SELECT ${commaSeparatedFields} FROM ${object}`;
        query += this.setWhere(where, query);
        query += this.setSort(sort, query);
        query += this.setLimit(limit, query);
        const queryResult = await this.executeQuery(query);
        if (!queryResult) {
            this.throwCommandError("Failed to perform query");
        }
        return queryResult;
    }

    setWhere(where) {
        let query = "";
        if (where) {
            query += ` WHERE ${where}`;
        }
        return query;
    }

    setSort(sort) {
        let query = "";
        if (sort) {
            const formattedSort = sort.join(",")
            query += ` ORDER BY ${formattedSort}`;
        }
        return query;
    }

    setLimit(limit) {
        let query = "";
        if (limit) {
            query += ` LIMIT ${limit}`;
        }
        return query;
    }

    formatResponse(object, queryResults, fields) {
        queryResults.forEach(queryResult => {
            const lowerCaseFieldsToValues = this.getLowerCaseFieldToValues(queryResult);
            fields
            .filter(field => field)
            .forEach(field => {
                const lowerCaseField = field.toLowerCase();
                if (lowerCaseField === "id") {
                    queryResult.ID = lowerCaseFieldsToValues.id;
                    queryResult[field] = lowerCaseFieldsToValues.id;
                } else {
                    queryResult[field] = lowerCaseFieldsToValues[lowerCaseField];
                }
            });
        });
        const formattedResponse = {
            success: true,
            record_count: queryResults.length
        };
        formattedResponse[object] = queryResults;
        return formattedResponse;
    }

    async getUserAccessibleFields(object, fields) {
        if (fields.length === 0) {
            return [];
        }
        // Each of the properties in objectInfo.fields uses the regular casing seen in Salesforce
        // For example, Id, Account_vod__c, etc...
        // However the fields provided to the query command may not necessarily match this format.
        // This means we must perform an case-insensitive check that the field exists for the object.
        const objectInfo = await this.objectInfo(object);

        // We will insert all of the object fields in lower case into a Set
        // and then check that the fields passed in exist in the Set
        const lowerCaseFieldNames = Object.keys(objectInfo.fields).map(field => field.toLowerCase());
        const lowerCaseFieldNameSet = new Set(lowerCaseFieldNames);
        return fields.filter(field => lowerCaseFieldNameSet.has(field.toLowerCase()));
    }

    async executeQuery(query) {
        const response = await this.performQuery(query);
        return response.records;
    }

    async performQuery(query) {
        let response;
        try {
            response = await this.querySvc.query(query);
        } catch (e) {
            this.throwCommandError("Failed to perform query");
        }

        if (response.error) {
            const errorStatus = response.error.errorStatus;
            const errorMessages = response.error.errorData;
            const firstError = errorMessages.length > 0 ? errorMessages[0].message : "";
            const errorData = {
                errors: errorMessages,
                message: `${errorStatus} - ${firstError}`
            };
            throw new CommandError(errorData, this.constructor.name);
        }
        return response.data;
    }

    /**
     * Takes the fields in record and creates a set of lower case fields.
     * This will allow us to perform case insensitive field checks.
     * @returns {Set} returns a set of lower case fields from record
     */
    getLowerCaseFieldToValues(record) {
        const lowerCaseFieldsToValues = {};
        if (record) {
            Object.entries(record)
                .forEach(([field, fieldValue]) => {
                    const lowerCaseField = field.toLowerCase();
                    lowerCaseFieldsToValues[lowerCaseField] = fieldValue;
                });
        }
        return lowerCaseFieldsToValues;
    }
}