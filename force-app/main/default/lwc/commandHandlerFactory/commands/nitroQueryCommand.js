import CommandHandler from "./commandHandler"

const NITRO_DATA_ENDPOINT = "/api/v1/vds/data";

export default class NitroQueryCommand extends CommandHandler {

    veevaSessionService;
    veevaDataService;
    constructor(veevaUserInterfaceApi, veevaSessionService, veevaDataService) {
        super(veevaUserInterfaceApi);
        this.veevaSessionService = veevaSessionService;
        this.veevaDataService = veevaDataService;
    }

    async fetchNitroData(veevaServer, queryConfig) {
        const nitroDataRequest = await this.veevaDataService.initVodRequest();
        nitroDataRequest.method = "POST";
        nitroDataRequest.url = `${veevaServer}${NITRO_DATA_ENDPOINT}`;
        nitroDataRequest.body = JSON.stringify(queryConfig.configObject);
        let output = await this.veevaDataService.request(nitroDataRequest);
        let allRecords = output.data.records;
        let recordOffset = 0;
        while(!output.data.completed){
            let requestBody = JSON.parse(nitroDataRequest.body);
            recordOffset += output.data.numRecords;
            requestBody.offset = recordOffset;
            nitroDataRequest.body = JSON.stringify(requestBody);
            output = await this.veevaDataService.request(nitroDataRequest);
            allRecords = allRecords.concat(output.data.records);
        }
        output.data.records = allRecords;
        output.data.numRecords = allRecords.length;
        return output;
    }

    async response(queryConfig) {
        try {
            const { veevaServer } = await this.veevaSessionService.getVodInfo();
            const data = await this.fetchNitroData(veevaServer, queryConfig);
            return this.formatResponse(data);
        } catch (err) {
            return this.formatErrorResponse(err);
        }
    }

    formatResponse(nitroData) {
        return {
            success: true,
            data: nitroData.data
        };
    }

    formatErrorResponse(error) {
        return {
            success: false,
            message: error.message
        };
    }
}