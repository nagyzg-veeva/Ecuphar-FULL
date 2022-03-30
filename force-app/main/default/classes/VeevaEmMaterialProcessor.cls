/******************************************************************************
 *
 *               Confidentiality Information:
 *
 * This module is the confidential and proprietary information of
 * Veeva Systems, Inc.; it is not to be copied, reproduced, or transmitted
 * in any form, by any means, in whole or in part, nor is it to be used
 * for any purpose other than that for which it is expressly provided
 * without the written permission of Veeva Systems, Inc.
 *
 * Copyright (c) 2021 Veeva Systems, Inc.  All Rights Reserved.
 *
 *******************************************************************************/

/**
 * VeevaEmMaterialProcessor checks files uploaded or deleted for event material and update event material has attachment flag.
 */
public abstract without sharing class VeevaEmMaterialProcessor {
    protected List<SObject> triggerObjects;
    protected String primaryObjectName;
    protected String primaryFieldName;
    protected Boolean isBeforeDelete;
    protected String associateObjectName;
    protected String associateFieldName;


    public VeevaEmMaterialProcessor(List<SObject> triggerObjects) {
        this.triggerObjects = triggerObjects;
        initValues();
    }

    protected abstract void initValues();

    protected abstract Set<String> filterEventMaterialIds();

    public void updateHasAttachmentFlagForInsert() {
        Map<String, EM_Event_Material_vod__c> eventMaterials = queryEventMaterials(false);
        if (eventMaterials.size() > 0) {
            List<EM_Event_Material_vod__c> eventMaterialsToUpdate = eventMaterials.values();
            for (EM_Event_Material_vod__c eventMaterial :eventMaterialsToUpdate) {
                eventMaterial.Has_Attachment_vod__c = 'Yes_vod';
            }
            update eventMaterialsToUpdate;
        }
    }

    public void updateHasAttachmentFlagForDelete() {
        Map<String, EM_Event_Material_vod__c> eventMaterials = queryEventMaterials(true);
        if (eventMaterials.size() > 0) {
            removeAndUpdateEventMaterial(eventMaterials);
        }
    }

    private Map<String, EM_Event_Material_vod__c> queryEventMaterials(boolean hasAttachment) {
        String requiredAttachmentRecordTypeId = getEventMaterialRecordTypeId();
        Map<String, EM_Event_Material_vod__c> eventMaterials = new Map<String, EM_Event_Material_vod__c>();
        if (!String.isBlank(requiredAttachmentRecordTypeId)) {
            // filter out all the parent event material records
            Set<String> eventMaterialIds = filterEventMaterialIds();
            String hasAttachmentValue = hasAttachment ? 'Yes_vod' : 'No_vod';
            if (eventMaterialIds.size() > 0) {
                eventMaterials = new Map<String, EM_Event_Material_vod__c>([SELECT Id, Has_Attachment_vod__c 
                    FROM EM_Event_Material_vod__c 
                    WHERE Id IN :eventMaterialIds 
                    AND RecordTypeId = :requiredAttachmentRecordTypeId 
                    AND Has_Attachment_vod__c = :hasAttachmentValue]);
            }
        }
        return eventMaterials;
    }

    private String getEventMaterialRecordTypeId() {
        String requiredAttachmentRecordTypeId = '';
        RecordTypeInfo recordType = Schema.SObjectType.EM_Event_Material_vod__c.getRecordTypeInfosByDeveloperName().get('Required_Attachment_vod');
        if (recordType != null) {
            requiredAttachmentRecordTypeId = recordType.getRecordTypeId();
        }
        return requiredAttachmentRecordTypeId;
    }

    private void removeEventMaterialByAttachmentCount(Map<String, EM_Event_Material_vod__c> eventMaterials, String objectName, String fieldName, Integer compareValue) {
        String query = 'SELECT ' + fieldName + ', COUNT(Id) Total FROM ' + objectName 
            + ' WHERE ' + fieldName + ' IN ' + VeevaEmBusRuleUtils.toCommaSeparated(new List<String>(eventMaterials.keySet())) 
            + ' GROUP BY ' + fieldName + ' HAVING COUNT(Id) > ' + compareValue;
        for (sObject queryRow : Database.query(query)) {
            // remove event materials linked with attachment 
            eventMaterials.remove((String)queryRow.get(fieldName));
        }
    }

    private void removeAndUpdateEventMaterial(Map<String, EM_Event_Material_vod__c> eventMaterials) {
        // set compare value to 1 if called by before delete trigger
        removeEventMaterialByAttachmentCount(eventMaterials, primaryObjectName, primaryFieldName, isBeforeDelete ? 1 : 0);     
        if (eventMaterials != null && eventMaterials.size() > 0) {
            removeEventMaterialByAttachmentCount(eventMaterials, associateObjectName, associateFieldName, 0);
        }
        if (eventMaterials != null && eventMaterials.size() > 0) {
            List<EM_Event_Material_vod__c> eventMaterialsToUpdate = new List<EM_Event_Material_vod__c>();
            for (EM_Event_Material_vod__c eventMaterial : eventMaterials.values()) {
                eventMaterial.Has_Attachment_vod__c = 'No_vod';
                eventMaterialsToUpdate.add(eventMaterial);
            }
            update eventMaterialsToUpdate;
        }
    }
}