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
 * VeevaEmMaterialAttachmentProcessor overrides event material attachment logic for attachment object.
 */
public without sharing class VeevaEmMaterialAttachmentProcessor extends VeevaEmMaterialProcessor {

    public VeevaEmMaterialAttachmentProcessor(List<SObject> triggerObjects) {
        super(triggerObjects);
    }

    protected override void initValues() {
        primaryObjectName = 'Attachment';
        primaryFieldName = 'ParentId';
        associateObjectName = 'ContentDocumentLink';
        associateFieldName = 'LinkedEntityId';
        isBeforeDelete = false;
    }

    protected override Set<String> filterEventMaterialIds() {
        Set<String> eventMaterialIds = new Set<String>();
        // filter out all the parent event material records
        List<Attachment> attachments = (List<Attachment>) triggerObjects;
        for (Attachment attachment : attachments) {
            if (attachment.ParentId.getSobjectType() == EM_Event_Material_vod__c.SobjectType) {
                eventMaterialIds.add(attachment.ParentId);
            }
        }
        return eventMaterialIds;
    }
}