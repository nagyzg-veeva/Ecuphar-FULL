trigger VEEVA_WEC_MC_ACTIVITY_BEFORE_INSERT on Multichannel_Activity_vod__c(before insert, after update) {
    Set<String> sentMessageExtIdSet = new Set<String>();
    for(Multichannel_Activity_vod__c mca: Trigger.new){
        if (mca.Sent_Message_External_id_vod__c != null ) {
            sentMessageExtIdSet.add(mca.Sent_Message_External_Id_vod__c );
        }
    }

    if (sentMessageExtIdSet.size() >0 ) {
        List<Sent_Message_vod__c> sentMessageList = [select Id, VExternal_Id_vod__c ,Last_Open_Datetime_vod__c, Total_Duration_vod__c from Sent_Message_vod__c where VExternal_Id_vod__c in :sentMessageExtIdSet ];

        if ( sentMessageList != null && sentMessageList.size() > 0 ) {
            Map<String,Sent_Message_vod__c> sentMessageMap = new Map<String,Sent_Message_vod__c>();
            for(Sent_Message_vod__c smvc: sentMessageList) {
                sentMessageMap.put(smvc.VExternal_Id_vod__c,smvc);
            }
            for(Multichannel_Activity_vod__c mca: Trigger.new){
                Sent_Message_vod__c sentMsg = sentMessageMap.get(mca.Sent_Message_External_Id_vod__c);
                if ( sentMsg != null ) {
                    if (trigger.isInsert ) {
                        mca.Sent_Message_vod__c = sentMsg.Id;
                        sentMsg.Last_Open_Datetime_vod__c = mca.Start_DateTime_vod__c;
                        if ( sentMsg.Total_Duration_vod__c == null ) {
                            sentMsg.Total_Duration_vod__c = 0;
                        }
                        if (mca.Total_Duration_vod__c == null ) {
                            mca.Total_Duration_vod__c = 0;
                        }
                        sentMsg.Total_Duration_vod__c = sentMsg.Total_Duration_vod__c + mca.Total_Duration_vod__c;
                    }
                }
            }

            //Recalculate total duration for sent message records.
            if (trigger.isUpdate) {
                List<AggregateResult> durations = [ select sum(Total_Duration_vod__c) totalDuration, Sent_Message_External_Id_vod__c from Multichannel_Activity_vod__c where Sent_Message_External_Id_vod__c in :sentMessageExtIdSet group by Sent_Message_External_Id_vod__c];
                if (!durations.isEmpty() && durations.size() > 0 ) {
                    for(AggregateResult ar : durations ) {
                        Decimal duration = (Decimal)ar.get('totalDuration');
                        String extId = (String)ar.get('Sent_Message_External_Id_vod__c');
                        Sent_Message_vod__c sentMsg = sentMessageMap.get(extId);
                        if (sentMsg != null) {
                            sentMsg.Total_Duration_vod__c = duration;
                        }
                    }
                }
            }

            update sentMessageList;
        }
    }
}