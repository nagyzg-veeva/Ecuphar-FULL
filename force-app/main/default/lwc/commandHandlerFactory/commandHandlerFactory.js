import FieldLabelsCommand from "./commands/fieldLabelsCommand";
import ObjectLabelsCommand from "./commands/objectLabelsCommand";
import ObjectMetadataCommand from "./commands/objectMetadataCommand";
import AvailableObjectsCommand from "./commands/availableObjectsCommand";
import SessionCommand from "./commands/sessionCommand";
import RecordTypeLabelsCommand from "./commands/recordTypeLabelsCommand";
import PicklistLabelsCommand from "./commands/picklistLabelsCommand";
import QueryCommand from "./commands/queryCommand";
import QuerySalesDataCommand from "./commands/querySalesDataCommand";
import CreateRecordCommand from "./commands/createRecordCommand";
import UpdateRecordCommand from "./commands/updateRecordCommand";
import NewRecordCommand from "./commands/newRecordCommand";
import CurrentPositionCommand from "./commands/currentPositionCommand";
import ViewRecordCommand from "./commands/viewRecordCommand";
import RequestCommand from "./commands/requestCommand";
import DataForObjectCommand from "./commands/dataForObjectCommand";
import SmartLinkingCommand from "./commands/smartLinkingCommand";
import NitroQueryCommand from "./commands/nitroQueryCommand";
import MyInsightsQueryService from "c/myInsightsQueryService";

export default class CommandHandlerFactory {
    static commandHandlers(veevaUserApiService, veevaSessionService, veevaDataService, myInsightsPageController) {
        const queryService = new MyInsightsQueryService(veevaSessionService);
        return {
            "getFieldLabel": new FieldLabelsCommand(veevaUserApiService),
            "getObjectLabels": new ObjectLabelsCommand(veevaUserApiService),
            "request": new RequestCommand(veevaUserApiService),
            "getObjectMetadata": new ObjectMetadataCommand(veevaUserApiService),
            "getSFDCSessionID": new SessionCommand(veevaUserApiService, veevaSessionService),
            "getRecordTypeLabels": new RecordTypeLabelsCommand(veevaUserApiService),
            "getPicklistValueLabels": new PicklistLabelsCommand(veevaUserApiService),
            "queryObject": new QueryCommand(veevaUserApiService, queryService),
            "getDataForObjectV2": new DataForObjectCommand(veevaUserApiService, myInsightsPageController),
            "getAvailableObjects": new AvailableObjectsCommand(veevaUserApiService),
            "querySalesData": new QuerySalesDataCommand(veevaUserApiService, veevaDataService),
            "createRecord": new CreateRecordCommand(veevaUserApiService),
            "updateRecord": new UpdateRecordCommand(veevaUserApiService),
            "newRecord": new NewRecordCommand(veevaUserApiService, veevaDataService),
            "viewRecord": new ViewRecordCommand(veevaUserApiService, veevaDataService),
            "getCurrentPosition": new CurrentPositionCommand(veevaUserApiService),
            "smartLinking": new SmartLinkingCommand(veevaUserApiService, veevaDataService, myInsightsPageController),
            "queryVDSRecord": new NitroQueryCommand(veevaUserApiService, veevaSessionService, veevaDataService)
        }
    }
}