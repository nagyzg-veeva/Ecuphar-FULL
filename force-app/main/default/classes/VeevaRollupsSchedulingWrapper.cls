global class VeevaRollupsSchedulingWrapper implements Schedulable {

    public interface IAccountRollupsSchedule {
        void execute(SchedulableContext sc);
    }

    global void execute(SchedulableContext sc) {
        Type targetType = Type.forName('VeevaRollupsScheduling');
        if(targetType != null) {
            IAccountRollupsSchedule obj = (IAccountRollupsSchedule) targetType.newInstance();
            obj.execute(sc);
        }
    }
}