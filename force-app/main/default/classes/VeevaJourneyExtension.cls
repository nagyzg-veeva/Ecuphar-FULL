public with sharing class VeevaJourneyExtension {
    public VeevaJourneyExtension(ApexPages.StandardController stdController) { }
    /*---------------------------------------------------------
     * JOURNEY
     *-------------------------------------------------------*/

    /**
     * @description get a list of journeys
     */
    @RemoteAction
    public static VeevaJourneyResult getJourneys() {
        return new VeevaJourneyResult(VeevaJourneyServiceFactory.getJourneyService().findAllJourneys());
    }

    /**
     * @description get journey detail by id, including stages and their stage actions
     */
    @RemoteAction
    public static VeevaJourneyResult getJourney(ID id) {
        return new VeevaJourneyResult(VeevaJourneyServiceFactory.getJourneyService().getJourneyDetail(id));
    }

    /**
     * @description Create/update journey and its stages order
     * @param journey
     * @param stageIds The stage ids associated with the journey to save, the order of the stages saved is the
     * same as the order in the array
     *                 Stages themselves are saved in separate functions (e.g. saveJourneyStage), so here we
     * only reorder them.
     * @return a result object that contains an data object with the id of the saved journey.
     */
    @RemoteAction
    public static VeevaJourneyResult saveJourney(Andi_Journey_vod__c journey, List<ID> stageIds) {
        // save journey
        Andi_Journey_vod__c savedJourney = VeevaJourneyServiceFactory.getJourneyService().saveJourney(
            journey
        );
        // handle stage reorder
        if (
            stageIds != null &&
            !stageIds.isEmpty()
        ) {
            List<Andi_Journey_Stage_vod__c> stagesToUpdate = new List<Andi_Journey_Stage_vod__c>();
            Schema.SObjectType stageObjectType = stagesToUpdate.getSObjectType();
            for (Integer idx = 0; idx < stageIds.size(); idx++) {
                ID stageId = stageIds.get(idx);
                if (stageId == null) continue;
                Andi_Journey_Stage_vod__c stageToUpdate =
                    (Andi_Journey_Stage_vod__c) stageObjectType.newSObject(stageId);
                stageToUpdate.Sequence_vod__c = idx + 1;
                stagesToUpdate.add(stageToUpdate);
            }
            VeevaJourneyServiceFactory.getJourneyService().saveJourneyStages(stagesToUpdate);
        }

        return new VeevaJourneyResult(savedJourney);
    }

    /**
     * @description remove journey by id
     * @param journeyId
     */
    @RemoteAction
    public static VeevaJourneyResult removeJourney(ID journeyId) {
        VeevaJourneyServiceFactory.getJourneyService().removeJourney(journeyId);
        return new VeevaJourneyResult();
    }

    /*---------------------------------------------------------
     * STAGE
     *-------------------------------------------------------*/

    /**
     * @description save a journey stage along with its stage actions
     * @param stage the stage to save
     * @param stageActionsToSave the stage actions to save
     * @param stageActionsToRemove the ids of the stage actions to remove
     * @return a result object that contains an data object with the id of the saved stage.
     */
    @RemoteAction
    public static VeevaJourneyResult saveJourneyStage(
        Andi_Journey_Stage_vod__c stage,
        List<Andi_Journey_Stage_Action_vod__c> stageActionsToSave,
        List<ID> stageActionsToRemove
    ) {
        Boolean isNewStage = false;
        if (stage != null && stage.Id == null) {
            isNewStage = true;
        }
        Andi_Journey_Stage_vod__c savedStage =
            VeevaJourneyServiceFactory.getJourneyService().saveJourneyStage(stage);

        // if it's a new stage, then we have to save the stage first before saving stage actions
        if (
            (isNewStage && savedStage != null) ||
            !isNewStage
        ) {
            // associate the newly created stage id with the stage actions that are going to be saved
            if (isNewStage) {
                ID savedStageId = savedStage.Id;
                for (Andi_Journey_Stage_Action_vod__c stageAction: stageActionsToSave) {
                    stageAction.Journey_Stage_vod__c = savedStageId;
                }
            }
            VeevaJourneyServiceFactory.getJourneyService().saveJourneyStageActions(stageActionsToSave);
            VeevaJourneyServiceFactory.getJourneyService().removeJourneyStageActions(stageActionsToRemove);
        }

        return new VeevaJourneyResult(savedStage);
    }

    /**
     * @description remove a stage by id
     * @param stageId
     */
    @RemoteAction
    public static VeevaJourneyResult removeJourneyStage(ID stageId) {
        VeevaJourneyServiceFactory.getJourneyService().removeJourneyStage(stageId);
        return new VeevaJourneyResult();
    }

    /*---------------------------------------------------------
     * METADATA
     *-------------------------------------------------------*/

    /**
     * @description get journey related metadata, e.g. record types, picklists.
     * @return a result object containing a map of metadata.
     */
    @RemoteAction
    public static VeevaJourneyResult getJourneyMetadata() {
        Map<String, List<Object> > metadata = new Map<String, List<Object> >();

        List<Schema.RecordTypeInfo> journeyStageRecordTypes =
            VeevaJourneyServiceFactory.getMetadataService().findRecordTypesByObjectType(
            'Andi_Journey_Stage_vod__c',
            true
            );
        List<Map<String, String> > journeyStageTypes = new List<Map<String, String> >();
        for (Schema.RecordTypeInfo recordType: journeyStageRecordTypes) {
            Map<String, String> type = new Map<String, String>();
            type.put('id', recordType.getRecordTypeId());
            type.put('value', recordType.getDeveloperName());
            type.put('label', recordType.getName());
            journeyStageTypes.add(type);
        }
        metadata.put('journeyStageTypes', journeyStageTypes);

        List<Schema.PicklistEntry> journeyStageActionComponentPicklist =
            VeevaJourneyServiceFactory.getMetadataService().findPicklistByObjectField(
            'Andi_Journey_Stage_Action_vod__c',
            'Component_vod__c',
            true
            );
        metadata.put('journeyStageActionComponent', journeyStageActionComponentPicklist);

        List<Schema.RecordTypeInfo> journeyStageActionRecordTypes =
            VeevaJourneyServiceFactory.getMetadataService().findRecordTypesByObjectType(
            'Andi_Journey_Stage_Action_vod__c',
            true
            );
        List<Map<String, String> > journeyStageActionTypes = new List<Map<String, String> >();
        for (Schema.RecordTypeInfo recordType: journeyStageActionRecordTypes) {
            Map<String, String> type = new Map<String, String>();
            type.put('id', recordType.getRecordTypeId());
            type.put('value', recordType.getDeveloperName());
            type.put('label', recordType.getName());
            journeyStageActionTypes.add(type);
        }
        metadata.put('journeyStageActionTypes', journeyStageActionTypes);

        return new VeevaJourneyResult(metadata);
    }

    /*---------------------------------------------------------
     * LOOK UP RELATIONSHIP
     *-------------------------------------------------------*/

    /**
     * @description lookup products
     * @param productNameFilter
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    public static VeevaJourneyPageResult getProducts(
        String productNameFilter,
        VeevaJourneyPageOptions pageOptions
    ) {
        List<String> productTypes = new List<String> {'Detail', 'Detail Topic'};
        if (pageOptions != null) {
            pageOptions.setOrderConfigs('Name');
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findProducts(
                productTypes,
                productNameFilter,
                pageOptions
            )
        );
    }

    /**
     * @description lookup clm presentations
     * @param clmPresentationNameFilter
     * @param productIds related product ids
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    public static VeevaJourneyPageResult getClmPresentations(
        String clmPresentationNameFilter,
        List<ID> productIds,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (pageOptions != null) {
            pageOptions.setOrderConfigs('Name');
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findClmPresentations(
                clmPresentationNameFilter,
                productIds,
                true,
                pageOptions
            )
        );
    }

    /**
     * @description lookup clm presentations by ids
     * @param ids
     * @return a result object with a list of clm presentations
     */
    @RemoteAction
    public static VeevaJourneyResult getClmPresentationsById(List<ID> ids) {
        return new VeevaJourneyResult(
            VeevaJourneyServiceFactory.getLookupService().findSObjectsById(
                'CLM_Presentation_vod__c',
                new List<String> {'Id', 'Name'},
                ids
            )
        );
    }

    /**
     * @description lookup key messages
     * @param keyMessageNameFilter
     * @param productIds related product ids
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    public static VeevaJourneyPageResult getKeyMessages(
        String keyMessageNameFilter,
        List<ID> productIds,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (pageOptions != null) {
            pageOptions.setOrderConfigs('Name');
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findKeyMessages(
                keyMessageNameFilter,
                productIds,
                false,
                pageOptions
            )
        );
    }

    /**
     * @description lookup key messages by ids
     * @param ids
     * @return a result object with a list of key messages
     */
    @RemoteAction
    public static VeevaJourneyResult getKeyMessagesById(List<ID> ids) {
        return new VeevaJourneyResult(
            VeevaJourneyServiceFactory.getLookupService().findSObjectsById(
                'Key_Message_vod__c',
                new List<String> {'Id', 'Name'},
                ids
            )
        );
    }

    /**
     * @description lookup approved documents
     * @param approvedDocumentNameFilter
     * @param productIds related product ids
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    public static VeevaJourneyPageResult getApprovedDocuments(
        String approvedDocumentNameFilter,
        List<ID> productIds,
        VeevaJourneyPageOptions pageOptions
    ) {
        List<String> recordTypes = new List<String> {'Email_Template_vod'};
        if (pageOptions != null) {
            pageOptions.setOrderConfigs('Name');
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findApprovedDocuments(
                recordTypes,
                approvedDocumentNameFilter,
                productIds,
                true,
                pageOptions
            )
        );
    }

    /**
     * @description lookup approved documents by ids
     * @param ids
     * @return a result object with a list of approved documents
     */
    @RemoteAction
    public static VeevaJourneyResult getApprovedDocumentsById(List<ID> ids) {
        return new VeevaJourneyResult(
            VeevaJourneyServiceFactory.getLookupService().findSObjectsById(
                'Approved_Document_vod__c',
                new List<String> {'Id', 'Name'},
                ids
            )
        );
    }

    /**
     * @description lookup EM catalogs
     * @param emCatalogNameFilter
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    public static VeevaJourneyPageResult getEmCatalogs(
        String emCatalogNameFilter,
        VeevaJourneyPageOptions pageOptions
    ) {
        List<String> recordTypes = new List<String> {'Event_Topic_vod'};
        if (pageOptions != null) {
            pageOptions.setOrderConfigs('Name_vod__c');
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findEmCatalogs(
                recordTypes,
                emCatalogNameFilter,
                pageOptions
            )
        );
    }

    /**
     * @description lookup EM catalogs by ids
     * @param ids
     * @return a result object with a list of EM catalogs
     */
    @RemoteAction
    public static VeevaJourneyResult getEmCatalogsById(List<ID> ids) {
        return new VeevaJourneyResult(
            VeevaJourneyServiceFactory.getLookupService().findSObjectsById(
                'EM_Catalog_vod__c',
                new List<String> {'Id', 'Name_vod__c'},
                ids
            )
        );
    }

    /**
     * @description lookup EM events
     * @param emEventNameFilter
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    public static VeevaJourneyPageResult getEmEvents(
        String emEventNameFilter,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (pageOptions != null) {
            pageOptions.setOrderConfigs('Name');
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findEmEvents(
                emEventNameFilter,
                pageOptions
            )
        );
    }

    /**
     * @description lookup metric configurations
     * @param metricConfigurationNameFilter
     * @param productIds related product ids
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    public static VeevaJourneyPageResult getMetricConfigurations(
        String metricConfigurationNameFilter,
        List<ID> productIds,
        VeevaJourneyPageOptions pageOptions
    ) {
        List<String> metricTypes = new List<String> {'Number_vod', 'Arrows_vod'};
        if (pageOptions != null) {
            pageOptions.setOrderConfigs('Name');
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findMetricConfigurations(
                metricTypes,
                metricConfigurationNameFilter,
                productIds,
                true,
                true,
                pageOptions
            )
        );
    }

    /**
     * @description convert a list of object with id value of EM_Event_vod__c/Approved_Document_vod__c
     *              to a list of object with the corresponding object of
     *              EM_Event_vod__c/Approved_Document_vod__c
     * @param eventResponses a list of object with id value of EM_Event_vod__c/Approved_Document_vod__c, e.g.
     *                      [{type: emEventId, template: approvedDocumentId}, ...]
     * @return a result object with a list of object with the corresponding object of
     *         EM_Event_vod__c/Approved_Document_vod__c,
     *         e.g. [{type: emEventObject, template: approvedDocumentObject}, ...]
     */
    @RemoteAction
    public static VeevaJourneyResult getEventResponseInfos(List<Map<String, ID> > eventResponses) {
        List<Map<String, SObject> > eventResponseInfos = new List<Map<String, SObject> >();

        if (
            eventResponses != null &&
            !eventResponses.isEmpty()
        ) {
            // lists are used for keeping the result in the same order as the input,
            // sets are used for queries
            List<ID> eventIds = new List<ID>();
            Set<ID> eventIdsToQuery = new Set<ID>();
            List<ID> templateIds = new List<ID>();
            Set<ID> templateIdsToQuery = new Set<ID>();

            for (Map<String, ID> eventResponse : eventResponses) {
                ID eventId = eventResponse.get('type');
                ID templateId = eventResponse.get('template');

                eventIds.add(eventId);
                if (eventId != null) {
                    eventIdsToQuery.add(eventId);
                }

                templateIds.add(templateId);
                if (templateId != null) {
                    templateIdsToQuery.add(templateId);
                }
            }

            List<EM_Event_vod__c> events =
                (List<EM_Event_vod__c>) VeevaJourneyServiceFactory.getLookupService().findSObjectsById(
                    'EM_Event_vod__c',
                    new List<String> {'Id', 'Name'},
                    new List<ID>(eventIdsToQuery)
                );

            List<Approved_Document_vod__c> templates =
                (List<Approved_Document_vod__c>) VeevaJourneyServiceFactory.getLookupService()
                    .findSObjectsById(
                        'Approved_Document_vod__c',
                        new List<String> {'Id', 'Name'},
                        new List<ID>(templateIdsToQuery)
                    );

            Map<ID, EM_Event_vod__c> eventMap = new Map<ID, EM_Event_vod__c>(events);
            Map<ID, Approved_Document_vod__c> templateMap = new Map<ID, Approved_Document_vod__c>(templates);

            for (Integer idx = 0; idx < eventIds.size(); idx++) {
                Map<String, SObject> info = new Map<String, SObject>();

                ID eventId = eventIds.get(idx);
                if (eventId != null) {
                    EM_Event_vod__c event = eventMap.get(eventId);
                    // deal with it only if the event exists
                    if (event != null) {
                        info.put('type', event);

                        ID templateId = templateIds.get(idx);
                        if (templateId != null) {
                            Approved_Document_vod__c template = templateMap.get(templateId);
                            if (template != null) {
                                info.put('template', template);
                            }
                        }

                        eventResponseInfos.add(info);
                    }
                }
            }
        }

        return new VeevaJourneyResult(eventResponseInfos);
    }

    public String getUnableToDisplayMessage() {
        return VOD_VEEVA_MESSAGE.getMsgWithDefault('UNABLE_TO_DISPLAY_JOURNEY_UI', 'Journeys', 'You do not have permission to view the Journey Builder interface. If you feel that this is an error, please contact your administrator.');
    }

}