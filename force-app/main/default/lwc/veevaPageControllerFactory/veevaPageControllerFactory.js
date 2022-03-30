// will replace veevaPageControllerFactory.js under /main during deployment
import Container from "c/container";
import VeevaPageController from "c/veevaPageController";
import MedicalInquiryController from "c/medicalInquiryController";
import EmController from "c/emController";
import EmEventController from "c/emEventController";
import EmEventBudgetController from "c/emEventBudgetController";
import EmEventTeamMemberController from "c/emEventTeamMemberController";
import AccountPlanCloneController from "c/accountPlanCloneController";
import MedicalInsightController from "c/medicalInsightController";
import VeevaDataService from "c/veevaDataService";
import EmPageLayoutEngineService from "c/emPageLayoutEngineService";
import EventActionService from 'c/eventActionService';
import VeevaSessionService from "c/veevaSessionService";
import VeevaUserInterfaceAPI from "c/veevaUserInterfaceAPI";
import VeevaMessageService from "c/veevaMessageService";
import MyInsightsController from "c/myInsightsController";

const PAGE_CONTROLLER_ARGS = ['dataSvc', 'userInterfaceSvc', 'messageSvc'];
let _container = Container.INSTANCE;
_container.singleton('sessionSvc', VeevaSessionService);
_container.singleton('dataSvc', VeevaDataService, ['sessionSvc']);
_container.singleton('emPageLayoutEngineSvc', EmPageLayoutEngineService, ['dataSvc']);
_container.singleton('eventActionSvc', EventActionService, ['dataSvc']);
_container.singleton('userInterfaceSvc', VeevaUserInterfaceAPI, ['sessionSvc']);
_container.singleton('messageSvc', VeevaMessageService);
_container.register('pageCtrl', VeevaPageController, PAGE_CONTROLLER_ARGS);
_container.register("Medical_Inquiry_vod__c", MedicalInquiryController, PAGE_CONTROLLER_ARGS);
_container.register("EM_Event_vod__c", EmEventController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc', 'eventActionSvc']);
_container.register("EM_Attendee_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("EM_Event_Budget_vod__c", EmEventBudgetController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("EM_Event_Session_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("EM_Event_Session_Attendee_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("EM_Event_Speaker_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("Expense_Header_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("Expense_Line_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("EM_Expense_Estimate_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("EM_Event_Material_vod__c", EmController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("EM_Event_Team_Member_vod__c", EmEventTeamMemberController, [...PAGE_CONTROLLER_ARGS, 'emPageLayoutEngineSvc']);
_container.register("HTML_Report_vod__c--MyInsights", MyInsightsController, ['dataSvc', 'userInterfaceSvc', 'messageSvc', 'sessionSvc']);

_container.register("Account_Plan_vod__c--CLONE", AccountPlanCloneController, PAGE_CONTROLLER_ARGS);
_container.register("Medical_Insight_vod__c", MedicalInsightController, PAGE_CONTROLLER_ARGS);

const getPageController = (name) => {
    return _container.get(name, 'pageCtrl'); //fallback to pageCtrl
}

export { getPageController };