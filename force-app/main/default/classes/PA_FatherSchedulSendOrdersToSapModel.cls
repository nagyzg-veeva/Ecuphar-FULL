/*
-- SCHEDULE THE APEX CLASS --
PA_FatherSchedulSendOrdersToSapModel orderToSAP = new PA_FatherSchedulSendOrdersToSapModel();
String sch_noon = '0 0 11 * * ?';
String sch_night = '0 0 23 * * ?';
String jobID_noon = System.schedule('Send orders to SAP - Noon', sch_noon, orderToSAP);
String jobID_night = System.schedule('Send orders to SAP - Night', sch_night, orderToSAP);
-----------------------------
*/

global class PA_FatherSchedulSendOrdersToSapModel implements Schedulable {
   global void execute(SchedulableContext sc) {
          database.executebatch(new PA_SchedulableSendOrdersToSapModel(), 1);
   }
}