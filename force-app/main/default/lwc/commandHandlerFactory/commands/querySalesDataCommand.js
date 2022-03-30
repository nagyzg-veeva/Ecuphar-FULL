import CommandHandler from "./commandHandler";

const QUERY_SALES_DATA_PATH = "/api/v1/analytics-data/account-sales-summary";
export default class QuerySalesDataCommand extends CommandHandler {

    veevaDataService;
    constructor(veevaUserInterfaceAPI, veevaDataService) {
        super(veevaUserInterfaceAPI);
        this.veevaDataService = veevaDataService;
    }

    async response(queryConfig) {
        const {
            object,
            fields,
            where,
            sort,
            limit
        } = queryConfig;
        if (object !== "Account_Sales_Summary_Insights") {
            this.throwQuerySalesDataError("Expected object to be 'Account_Sales_Summary_Insights'");
        }

        const salesData = await this.querySalesData(fields, where, sort, limit);
        return this.formatResponse(salesData);
    }

    // eslint-disable-next-line consistent-return
    async querySalesData(fields, where, sort, limit) {
        const querySalesDataRequest = await this.querySalesDataRequest(fields, where, sort, limit);
        try {
            const response = await this.veevaDataService.request(querySalesDataRequest, "querySalesData");
            return response.data;
        } catch (e) {
            this.throwQuerySalesDataError(e.message);
        }
    }

    async querySalesDataRequest(fields, where, sort, limit) {
        const querySalesDataRequest = await this.veevaDataService.initVodRequest();
        querySalesDataRequest.url += QUERY_SALES_DATA_PATH;
        querySalesDataRequest.method = "POST";
        querySalesDataRequest.body = JSON.stringify({
            queryObject: "Account_Sales_Summary_Insights",
            queryFields: fields,
            whereClause: where,
            sortFields: sort,
            resultLimit: limit
        });
        return querySalesDataRequest;
    }

    throwQuerySalesDataError(additionalInfoMessage) {
        this.throwCommandError("Failed to querySalesData - " + additionalInfoMessage);
    }

    formatResponse(queryResult) {
        const formattedResponse = {
            success: true,
            record_count: queryResult ? queryResult.length : 0
        };
        formattedResponse.Account_Sales_Summary_Insights = queryResult;
        return formattedResponse;
    }
}