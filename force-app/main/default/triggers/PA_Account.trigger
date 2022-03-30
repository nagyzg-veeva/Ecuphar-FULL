trigger PA_Account on Account (before update) {
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            PA_TRIGGER_Account.updateTotalAmount(Trigger.new);
        }
    }
}