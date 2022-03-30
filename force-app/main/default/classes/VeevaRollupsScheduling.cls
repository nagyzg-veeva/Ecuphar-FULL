public without sharing class VeevaRollupsScheduling implements VeevaRollupsSchedulingWrapper.IAccountRollupsSchedule {

    public void execute(SchedulableContext sc) {
        VeevaBatchAccountRollups rollups = new VeevaBatchAccountRollups();
        Database.executeBatch(rollups, 5);
    }
}