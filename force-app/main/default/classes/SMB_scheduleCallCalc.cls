global class SMB_scheduleCallCalc implements Schedulable{

global void execute(SchedulableContext sc) {

/* Perform any pre-processing for your organization then call the two

functions below */

VEEVA_BATCH_CYCLE_PLAN_CALC b = new VEEVA_BATCH_CYCLE_PLAN_CALC();

database.executebatch(b,100);

VEEVA_BATCH_CYCLE_PLAN_CALC_CALLS c = new VEEVA_BATCH_CYCLE_PLAN_CALC_CALLS ();

database.executebatch(c,100);

}

}