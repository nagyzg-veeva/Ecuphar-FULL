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
 * VeevaEmMaterialContentDocProcessor overrides event material attachment logic for content document link object.
 */
public without sharing class VeevaEmMaterialContentDocProcessor extends VeevaEmMaterialProcessor {

    public VeevaEmMaterialContentDocProcessor(List<SObject> triggerObjects) {
        super(triggerObjects);
    }

    protected override void initValues() {
        primaryObjectName = 'ContentDocumentLink';
        primaryFieldName = 'LinkedEntityId';
        associateObjectName = 'Attachment';
        associateFieldName = 'ParentId';
        isBeforeDelete = true;
    }

    protected override Set<String> filterEventMaterialIds() {
        Set<String> eventMaterialIds = new Set<String>();
        List<ContentDocumentLink> links = (List<ContentDocumentLink>) triggerObjects;
        for (ContentDocumentLink link : links) {
            if (link.LinkedEntityId.getSobjectType() == EM_Event_Material_vod__c.SobjectType) {
                eventMaterialIds.add(link.LinkedEntityId);
            }
        }
        return eventMaterialIds;
    }
}