global class VeevaSuggestionNotifySchedule implements Schedulable {
    public interface IScheduleExecutor {
        void execute(SchedulableContext ctx);
    }
    
    global void execute(SchedulableContext ctx) {
        Type targettype = Type.forName('VeevaSuggestionNotifyScheduleExecutor');
        if( targettype != null) {
          IScheduleExecutor target = (IScheduleExecutor)targettype.NewInstance();
          target.execute(ctx);
        }
    }
}