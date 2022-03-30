trigger TaskTrigger on Task (before delete, before insert) {
    
    Task [] taskRow = null;
    
    if (Trigger.isDelete)
        taskRow = Trigger.old;
    else
        taskRow = Trigger.new;
        
    TaskTriggerHandler handler = new TaskTriggerHandler(taskRow);
    
    handler.handleTask(Trigger.isDelete, taskRow);
    
}