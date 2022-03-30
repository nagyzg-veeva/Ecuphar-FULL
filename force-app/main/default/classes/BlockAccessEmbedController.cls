public without sharing class BlockAccessEmbedController {

   public boolean systemMaintenance {get; set;}
   public String systemDown {get; set;}
   public String blockedTitle {get; set;}
   public String blockedSummary {get; set;}
   public String blockedDetail {get; set;}
   public String callBlockedDetail {get; set;}
   public BlockAccessEmbedController() {
       systemMaintenance = VOD_Common.VOD_MAINT;
       systemDown = 'The system is undergoing maintenance, please try again later.';
       blockedTitle = VOD_VEEVA_MESSAGE.getMsgWithDefault('BLOCK_TITLE', 'BlockPage', 'Error');
       blockedSummary = VOD_VEEVA_MESSAGE.getMsgWithDefault('BLOCK_SUB_TITLE', 'BlockPage', 'Action not allowed.');
       blockedDetail = VOD_VEEVA_MESSAGE.getMsgWithDefault('BLOCK_MSG_GENERAL', 'BlockPage', 'You may not perform that action against this type of object.');
       callBlockedDetail = VOD_VEEVA_MESSAGE.getMsgWithDefault('CALL_BLOCK_MSG', 'BlockPage', 'Action not allowed.');
   }
}