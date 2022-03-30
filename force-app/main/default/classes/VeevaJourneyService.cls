public inherited sharing class VeevaJourneyService {
    private VeevaJourneyPermissionService permissionService;

    public VeevaJourneyService() {
        this.permissionService = VeevaJourneyServiceFactory.getPermissionService();
    }

    public VeevaJourneyService(VeevaJourneyPermissionService permissionService) {
        this.permissionService = permissionService;
    }

    /*---------------------------------------------------------
     * JOURNEY
     *-------------------------------------------------------*/

    /**
     * @description Get all journeys
     */
    public List<Andi_Journey_vod__c> findAllJourneys() {
        if (!permissionService.canRead('Andi_Journey_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Andi_Journey_vod__c');
        }
        if (!permissionService.canRead('Andi_Journey_Stage_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_vod__c'
            );
        }

        String selectClause = buildJourneyQuery();
        /*
         * Sorting
         *
         * - status
         * - product name
         * - journey name
         * - journey start date
         */
        String orderByClause = (
            ' ORDER BY Product_vod__r.Name ASC NULLS LAST,' +
            ' Name ASC NULLS LAST,' +
            ' Start_Date_vod__c DESC NULLS LAST'
        );

        // future
        List<Andi_Journey_vod__c> futureJourneys = Database.query(
            selectClause + ' WHERE Start_Date_vod__c > TODAY' + orderByClause
        );
        // active
        List<Andi_Journey_vod__c> activeJourneys = Database.query(
            selectClause + ' WHERE Start_Date_vod__c <= TODAY AND (End_Date_vod__c = null OR End_Date_vod__c >= TODAY)' + orderByClause
        );
        // expired
        List<Andi_Journey_vod__c> expiredJourneys = Database.query(
            selectClause + ' WHERE End_Date_vod__c < TODAY' + orderByClause
        );

        List<Andi_Journey_vod__c> result = new List<Andi_Journey_vod__c>();
        result.addAll(activeJourneys);
        result.addAll(futureJourneys);
        result.addAll(expiredJourneys);

        return result;
    }

    /**
     * @description Get a journey by id
     * @param id journey id
     * @return the journey object of the given id with basic info of stages
     */
    public Andi_Journey_vod__c findJourneyById(ID id) {
        if (!permissionService.canRead('Andi_Journey_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Andi_Journey_vod__c');
        }
        if (!permissionService.canRead('Andi_Journey_Stage_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_vod__c'
            );
        }

        Andi_Journey_vod__c journey = null;
        if (id != null) {
            String selectClause = buildJourneyQuery();
            String idClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
                new List<ID> {id},
                'Id',
                false,
                false
            );
            journey =
                (Andi_Journey_vod__c) VeevaJourneyHelper.expectOneFromResults(
                Database.query(
                    selectClause +
                    ' WHERE ' + idClause
                )
                );
        }
        return journey;
    }

    /**
     * @description Get journeys by ids
     * @return a list of journey objects of the given ids with basic info of stages
     */
    public List<Andi_Journey_vod__c> findJourneyByIds(List<ID> ids) {
        if (!permissionService.canRead('Andi_Journey_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Andi_Journey_vod__c');
        }
        if (!permissionService.canRead('Andi_Journey_Stage_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_vod__c'
            );
        }

        List<Andi_Journey_vod__c> journeys = new List<Andi_Journey_vod__c>();
        if (ids != null && !ids.isEmpty()) {
            String selectClause = buildJourneyQuery();
            String idClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(ids, 'Id', false, false);
            journeys = Database.query(selectClause + ' WHERE ' + idClause);
        }
        return journeys;
    }

    /**
     * @description Get the detail of a journey by id. The detail includes stages, stage actions, and if there
     *              is any associated stage account to the stages
     * @param id The journey id
     * @return a map object that represents the detail of the journey
     */
    public Map<String, Object> getJourneyDetail(ID id) {
        if (!permissionService.canRead('Andi_Journey_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Andi_Journey_vod__c');
        }
        if (!permissionService.canRead('Andi_Journey_Stage_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_vod__c'
            );
        }

        Map<String, Object> ret = null;
        // because of the limitation of maximum 1 level parent to child query, we have to
        // use two queries to get stage actions
        Andi_Journey_vod__c journeyDetail = (Andi_Journey_vod__c) VeevaJourneyHelper.expectOneFromResults(
            [
                SELECT Id, Name, Product_vod__r.Id, Product_vod__r.Name,
                Product_vod__r.Product_Thumbnail_vod__c, Start_Date_vod__c, End_Date_vod__c,
                (SELECT Id FROM Journey_Stages__r)
                FROM Andi_Journey_vod__c
                WHERE Id = : id
            ]
        );

        if (journeyDetail != null) {
            List<Andi_Journey_Stage_vod__c> stagesWithIdOnly = journeyDetail.Journey_Stages__r;
            List<ID> stageIds = new List<ID>();
            for (Andi_Journey_Stage_vod__c stage: stagesWithIdOnly) {
                stageIds.add(stage.Id);
            }

            List<Map<String, Object> > journeyStages = findJourneyStageDetailsById(stageIds);

            // merge stage info into journey detail (relationship fields are readonly)
            ret = new Map<String, Object>(journeyDetail.getPopulatedFieldsAsMap());
            ret.put('Journey_Stages__r', journeyStages);
        }

        return ret;
    }

    /**
     * @description Create/update a journey
     * @return The saved object with the saved id. Note this object is not necessarily the record in the db as
     *         it may just contain some updated fields.
     */
    public Andi_Journey_vod__c saveJourney(Andi_Journey_vod__c journey) {
        return (Andi_Journey_vod__c) saveSObject(journey);
    }

    /**
     * @description remove a journey by id
     */
    public void removeJourney(ID journeyId) {
        if (journeyId != null) {
            if (!permissionService.canRead('Andi_Journey_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_READ_ACCESS,
                    'Andi_Journey_vod__c'
                );
            }
            if (!permissionService.canDelete('Andi_Journey_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_DELETE_ACCESS,
                    'Andi_Journey_vod__c'
                );
            }
            delete [
                SELECT Id FROM Andi_Journey_vod__c
                WHERE Id = : journeyId
            ];
        }
    }

    /*---------------------------------------------------------
     * STAGE
     *-------------------------------------------------------*/

    /**
     * @description Get the detail of stages by ids
     * @param ids The stage ids
     * @return A list of stage details, including stage actions, metric configuration for product metric and
     *         the count of associated accounts
     */
    public List<Map<String, Object> > findJourneyStageDetailsById(List<ID> ids) {
        if (!permissionService.canRead('Andi_Journey_Stage_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_vod__c'
            );
        }
        if (!permissionService.canRead('Andi_Journey_Stage_Action_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_Action_vod__c'
            );
        }

        if (ids == null || ids.isEmpty()) {
            return new List<Map<String, Object> >();
        }

        List<Andi_Journey_Stage_vod__c> stages = [
            SELECT Id, Name, Sequence_vod__c, Stage_Points_vod__c, RecordType.DeveloperName,
            toLabel(RecordType.Name), Product_Metric_vod__c, Progression_Value_vod__c,
            Allow_Regression_vod__c,
            (
                SELECT Id, Priority_Weight_vod__c, RecordType.DeveloperName, Required_vod__c,
                Key_Message_vod__c, Component_vod__c, CLM_Presentation_vod__c, Approved_Document_vod__c
                FROM Journey_Stage_Actions__r
            )
            FROM Andi_Journey_Stage_vod__c
            WHERE Id IN :ids
        ];

        // handle metric configuration
        List<String> productMetrics = new List<String>();
        for (Andi_Journey_Stage_vod__c stage : stages) {
            if (stage.Product_Metric_vod__c != null) {
                productMetrics.add(stage.Product_Metric_vod__c);
            }
        }
        Map<String, Metric_Configuration_vod__c> metricConfigurationMap =
            new Map<String, Metric_Configuration_vod__c>();
        if (!productMetrics.isEmpty()) {
            if (!permissionService.canRead('Metric_Configuration_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_READ_ACCESS,
                    'Metric_Configuration_vod__c'
                );
            }
            List<Metric_Configuration_vod__c> metricConfigurations = [
                SELECT Id, Name FROM Metric_Configuration_vod__c
                WHERE Name IN :productMetrics
            ];
            // make metric configuration map by Name
            for (Metric_Configuration_vod__c metricConfiguration : metricConfigurations) {
                metricConfigurationMap.put(metricConfiguration.Name, metricConfiguration);
            }
        }

        // handle stage account
        if (!permissionService.canRead('Andi_Journey_Stage_Account_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_Account_vod__c'
            );
        }
        List<AggregateResult> associatedStageAccountCounts = [
            SELECT Journey_Stage_vod__c stageId, COUNT(Id) ct
            FROM Andi_Journey_Stage_Account_vod__c
            WHERE Journey_Stage_vod__c IN :ids
            AND Stage_Enter_Date_vod__c <= TODAY
            AND Stage_Exit_Date_vod__c = null
            AND Journey_Stage_vod__r.Journey_vod__r.Start_Date_vod__c <= TODAY
            AND Journey_Stage_vod__r.Journey_vod__r.End_Date_vod__c >= TODAY
            GROUP BY Journey_Stage_vod__c
        ];
        // make associated stage account count map
        Map<Id, Integer> associatedStageAccountCountMap = new Map<Id, Integer>();
        for (AggregateResult associatedStageAccountCount : associatedStageAccountCounts) {
            associatedStageAccountCountMap.put(
                (Id) associatedStageAccountCount.get('stageId'),
                (Integer) associatedStageAccountCount.get('ct')
            );
        }

        // enrich the stages
        List<Map<String, Object> > enrichedStages = new List<Map<String, Object> >();
        for (Andi_Journey_Stage_vod__c stage: stages) {
            Map<String, Object> stageAsMap = new Map<String, Object>(stage.getPopulatedFieldsAsMap());
            // add product metric
            if (stage.Product_Metric_vod__c != null) {
                Metric_Configuration_vod__c metricConfiguration =
                    metricConfigurationMap.get(stage.Product_Metric_vod__c);
                if (metricConfiguration != null) {
                    stageAsMap.put('productMetric', metricConfiguration);
                }
            }
            // add associated stage account count
            stageAsMap.put('associatedAccountCount', associatedStageAccountCountMap.get(stage.Id));
            enrichedStages.add(stageAsMap);
        }

        return enrichedStages;
    }

    /**
     * @description Create/update a stage
     * @param journeyStage If the object has no id, then we're creating the record. Otherwise, we're updating
     *                     it. If updating, you can just provide the field and the value you want to update.
     * @return The saved object with the saved id.Note this object is not necessarily the record in the db as
     *         it may just contain some updated fields.
     */
    public Andi_Journey_Stage_vod__c saveJourneyStage(Andi_Journey_Stage_vod__c journeyStage) {
        return (Andi_Journey_Stage_vod__c) saveSObject(journeyStage);
    }

    /**
     * @description Create/update a list of stages
     * @param journeyStages A list of journey stages to Create/update. If the object has no id, then we 're
     *                      creating the record. Otherwise, we're updating it. If updating, you can just
     *                      provide the field and the value you want to update. The list can contain both the
     *                      objects you want to save and update.
     * @return A list of saved objects with the saved ids.Note these object are not necessarily the record in
     *         the db as they may just contain some updated fields.
     */
    public List<Andi_Journey_Stage_vod__c> saveJourneyStages(List<Andi_Journey_Stage_vod__c> journeyStages) {
        return (List<Andi_Journey_Stage_vod__c>) saveSObjects(journeyStages);
    }

    /**
     * @description Remove a journey stage by id. This will re-sequence the stages within the same journey,
     *              i.e. re-sequence Sequence_vod__c
     * @param stageId
     */
    public void removeJourneyStage(ID stageId) {
        if (stageId != null) {
            if (!permissionService.canRead('Andi_Journey_Stage_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_READ_ACCESS,
                    'Andi_Journey_Stage_vod__c'
                );
            }
            if (!permissionService.canDelete('Andi_Journey_Stage_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_DELETE_ACCESS,
                    'Andi_Journey_Stage_vod__c'
                );
            }
            Andi_Journey_Stage_vod__c stageToRemove =
                (Andi_Journey_Stage_vod__c) VeevaJourneyHelper.expectOneFromResults(
                [
                    SELECT Id, Journey_vod__c, Sequence_vod__c FROM Andi_Journey_Stage_vod__c
                    WHERE Id = : stageId
                ]
                );
            if (stageToRemove != null) {
                ID journeyId = stageToRemove.Journey_vod__c;
                Decimal stageSequence = stageToRemove.Sequence_vod__c;
                delete stageToRemove;
                // reindex all other stages that belong to the same journey in order to
                // keep Sequence_vod__c consecutive
                List<Andi_Journey_Stage_vod__c> stagesToUpdate = [
                    SELECT Id, Sequence_vod__c FROM Andi_Journey_Stage_vod__c
                    WHERE Journey_vod__c = :journeyId AND Sequence_vod__c > :stageSequence
                ];
                for (Andi_Journey_Stage_vod__c stage: stagesToUpdate) {
                    stage.Sequence_vod__c = stage.Sequence_vod__c - 1;
                }
                if (!stagesToUpdate.isEmpty()) {
                    if (!permissionService.canUpdate('Andi_Journey_Stage_vod__c')) {
                        throw new VeevaJourneyException(
                            VeevaJourneyException.Type.NO_UPDATE_ACCESS,
                            'Andi_Journey_Stage_vod__c'
                        );
                    }
                    update stagesToUpdate;
                }
            }
        }
    }

    /*---------------------------------------------------------
     * STAGE ACTION
     *-------------------------------------------------------*/

    /**
     * @description Create/update stage actions
     * @param stageActions A list of journey stage actions to Create/update. If the object has no id, we're
     *                      creating the record. Otherwise, we're updating it. If updating, you can just
     *                      provide the field and the value you want to update. The list can contain both the
     *                      objects you want to save and update.
     * @return A list of saved objects with the saved ids. Note these object are not necessarily the record in
     *         the db as they may just contain some updated fields .
     */
    public List<Andi_Journey_Stage_Action_vod__c> saveJourneyStageActions(
        List<Andi_Journey_Stage_Action_vod__c> stageActions
    ) {
        return (List<Andi_Journey_Stage_Action_vod__c>) saveSObjects(stageActions);
    }

    /**
     * @description Remove stage actions by ids
     */
    public void removeJourneyStageActions(List<ID> stageActionsToRemove) {
        if (
            stageActionsToRemove != null &&
            !stageActionsToRemove.isEmpty()) {
            if (!permissionService.canRead('Andi_Journey_Stage_Action_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_READ_ACCESS,
                    'Andi_Journey_Stage_Action_vod__c'
                );
            }
            if (!permissionService.canDelete('Andi_Journey_Stage_Action_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_DELETE_ACCESS,
                    'Andi_Journey_Stage_Action_vod__c'
                );
            }
            delete [
                SELECT Id FROM Andi_Journey_Stage_Action_vod__c
                WHERE Id IN : stageActionsToRemove
            ];
        }
    }

    /*---------------------------------------------------------
     * STAGE ACCOUNT
     *-------------------------------------------------------*/

    /**
     * @description Get journey stage account by account id
     * @param accountId
     * @return A list of stage accounts
     */
    public List<Andi_Journey_Stage_Account_vod__c> findJourneyStageAccountsByAccount(ID accountId) {
        if (!permissionService.canRead('Andi_Journey_Stage_Account_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_Account_vod__c'
            );
        }
        if (!permissionService.canRead('My_Setup_Products_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'My_Setup_Products_vod__c'
            );
        }
        /*
         * - active stage account
         * - active journey only
         * - sorted by product name asc, journey name asc
         */
        List<Andi_Journey_Stage_Account_vod__c> stageAccounts = [
            SELECT Id, Account_vod__c, Stage_Enter_Date_vod__c, Journey_Stage_vod__c,
            Previous_Journey_Stage_Account_vod__r.Id,
            Previous_Journey_Stage_Account_vod__r.Journey_Stage_vod__c,
            Previous_Journey_Stage_Account_vod__r.Stage_Exit_Direction_vod__c,
            Journey_Stage_vod__r.Journey_vod__r.Id,
            Journey_Stage_vod__r.Journey_vod__r.Product_vod__r.Id FROM Andi_Journey_Stage_Account_vod__c
            WHERE Account_vod__c = :accountId
            AND Stage_Enter_Date_vod__c <= TODAY
            AND Stage_Exit_Date_vod__c = null
            AND Journey_Stage_vod__r.Journey_vod__r.Start_Date_vod__c <= TODAY
            AND Journey_Stage_vod__r.Journey_vod__r.End_Date_vod__c >= TODAY
            ORDER BY
            Journey_Stage_vod__r.Journey_vod__r.Product_vod__r.Name ASC NULLS LAST,
            Journey_Stage_vod__r.Journey_vod__r.Name ASC NULLS LAST
        ];

        // Due to limitation of soql, we have to find the stage accounts without querying on
        // My_Setup_Products_vod__c
        // and filter based on it later.
        Set<ID> allowedProductIdSet = new Set<ID>();
        for (
            List<My_Setup_Products_vod__c> setups: [
                SELECT Id, Product_vod__c FROM My_Setup_Products_vod__c
                WHERE Owner.Id = :UserInfo.getUserId()
            ]
        ) {
            for (My_Setup_Products_vod__c setup: setups) {
                allowedProductIdSet.add(setup.Product_vod__c);
            }
        }
        List<Andi_Journey_Stage_Account_vod__c> filteredStageAccounts =
            new List<Andi_Journey_Stage_Account_vod__c>();
        for (Andi_Journey_Stage_Account_vod__c stageAccount: stageAccounts) {
            if (
                allowedProductIdSet.contains(
                    stageAccount.Journey_Stage_vod__r.Journey_vod__r.Product_vod__r.Id
                )
            ) {
                filteredStageAccounts.add(stageAccount);
            }
        }

        return filteredStageAccounts;
    }

    /**
     * @description Get journey stage account by id
     * @param stageAccountId
     * @return The stage account of the given id
     */
    public Andi_Journey_Stage_Account_vod__c findJourneyStageAccountById(ID stageAccountId) {
        if (!permissionService.canRead('Andi_Journey_Stage_Account_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Andi_Journey_Stage_Account_vod__c'
            );
        }
        return (Andi_Journey_Stage_Account_vod__c) VeevaJourneyHelper.expectOneFromResults(
            [
                SELECT Id, Account_vod__c, Stage_Enter_Date_vod__c, Journey_Stage_vod__c,
                Previous_Journey_Stage_Account_vod__r.Id,
                Previous_Journey_Stage_Account_vod__r.Journey_Stage_vod__c,
                Previous_Journey_Stage_Account_vod__r.Stage_Exit_Direction_vod__c,
                Journey_Stage_vod__r.Journey_vod__r.Id,
                Journey_Stage_vod__r.Journey_vod__r.Product_vod__r.Id FROM
                Andi_Journey_Stage_Account_vod__c
                WHERE Id = : stageAccountId
            ]
        );
    }

    /**
     * @description Create/update a stage account
     * @param stageAccount If the object has no id, then we're creating the record. Otherwise, we're updating
     *                     it. If updating, you can just provide the field and the value you want to update.
     * @return The saved object with the saved id. Note this object is not necessarily the record in the db as
     *         it may just contain some updated fields.
     */
    public Andi_Journey_Stage_Account_vod__c saveJourneyStageAccount(
        Andi_Journey_Stage_Account_vod__c stageAccount
    ) {
        return (Andi_Journey_Stage_Account_vod__c) saveSObject(stageAccount);
    }

    /**
     * @description Create/update stage accounts
     * @param stageAccounts A list of journey stage accounts to Create/update. If the object has no id, we're
     *                      creating the record. Otherwise, we're updating it. If updating, you can just
     *                      provide the field and the value you want to update. The list can contain both the
     *                      objects you want to save and update.
     * @return A list of saved objects with the saved ids. Note these object are not necessarily the record in
     *         the db as they may just contain some updated fields .
     */
    public List<Andi_Journey_Stage_Account_vod__c> saveJourneyStageAccounts(
        List<Andi_Journey_Stage_Account_vod__c> stageAccounts
    ) {
        return (List<Andi_Journey_Stage_Account_vod__c>) saveSObjects(stageAccounts);
    }

    /**
     * @description Mark the Stage_Exit_Direction_vod__c of a stage account as Removed_vod by id
     */
    public void removeJourneyStageAccount(ID stageAccountId) {
        if (!permissionService.canDelete('Andi_Journey_Stage_Account_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_DELETE_ACCESS,
                'Andi_Journey_Stage_Account_vod__c'
            );
        }
        Andi_Journey_Stage_Account_vod__c stageAccount = findJourneyStageAccountById(stageAccountId);
        if (stageAccount != null) {
            stageAccount.Stage_Exit_Date_vod__c = Date.today();
            stageAccount.Stage_Exit_Direction_vod__c = 'Remove_vod';
            update stageAccount;
        }
    }

    /*---------------------------------------------------------
     * OTHERS
     *-------------------------------------------------------*/

    /**
     * @description Create/update a sObject
     * @param sObjectToSave If the object has no id, then we're creating the record. Otherwise, we're updating
     *                     it. If updating, you can just provide the field and the value you want to update.
     * @return The saved object with the saved id. Note this object is not necessarily the record in the db as
     *         it may just contain some updated fields.
     */
    private SObject saveSObject(SObject sObjectToSave) {
        ID id = sObjectToSave.Id;
        Schema.SObjectType objectType = sObjectToSave.getSObjectType();
        String objectName = objectType.getDescribe().getName();
        if (id != null) {
            if (!permissionService.canUpdate(objectName)) {
                throw new VeevaJourneyException(VeevaJourneyException.Type.NO_UPDATE_ACCESS, objectName);
            }
            update sObjectToSave;
        } else {
            if (!permissionService.canCreate(objectName)) {
                throw new VeevaJourneyException(VeevaJourneyException.Type.NO_CREATE_ACCESS, objectName);
            }
            insert sObjectToSave;
        }
        return sObjectToSave;
    }

    /**
     * @description Create/update a list sObjects
     * @param sObjectListToSave A list of sObjects to Create/update. If the object has no id,
     *                      we're creating the record. Otherwise, we're updating it. If updating, you can
     *                      just provide the field and the value you want to update. The list can contain both
     *                      the objects you want to save and update.
     * @return A list of saved objects with the saved ids. Note these object are not necessarily the record in
     *         the db as they may just contain some updated fields .
     */
    private List<SObject> saveSObjects(List<SObject> sObjectListToSave) {
        List<SObject> sObjectSaved = new List<SObject>();
        List<SObject> sObjectsToInsert = new List<SObject>();
        List<SObject> sObjectsToUpdate = new List<SObject>();

        Schema.SObjectType objectType = sObjectListToSave.getSObjectType();
        String objectName = objectType.getDescribe().getName();
        for (SObject sObjectToSave : sObjectListToSave) {
            if (sObjectToSave == null) continue;
            ID id = sObjectToSave.Id;
            if (id != null) {
                sObjectsToUpdate.add(sObjectToSave);
            } else {
                sObjectsToInsert.add(sObjectToSave);
            }
        }

        if (!sObjectsToInsert.isEmpty()) {
            if (!permissionService.canCreate(objectName)) {
                throw new VeevaJourneyException(VeevaJourneyException.Type.NO_CREATE_ACCESS, objectName);
            }
            insert sObjectsToInsert;
            sObjectSaved.addAll(sObjectsToInsert);
        }
        if (!sObjectsToUpdate.isEmpty()) {
            if (!permissionService.canUpdate(objectName)) {
                throw new VeevaJourneyException(VeevaJourneyException.Type.NO_UPDATE_ACCESS, objectName);
            }
            update sObjectsToUpdate;
            sObjectSaved.addAll(sObjectsToUpdate);
        }

        return sObjectSaved;
    }

    /**
     * @description Common query used to query on journey
     */
    private String buildJourneyQuery() {
        return
            'SELECT Id, Name, Product_vod__r.Id, Product_vod__r.Name, Product_vod__r.Product_Thumbnail_vod__c, Start_Date_vod__c, End_Date_vod__c,'
            +
            ' (SELECT Id, Name, Sequence_vod__c, Journey_vod__c, Stage_Points_vod__c, RecordType.DeveloperName, Allow_Regression_vod__c FROM Journey_Stages__r ORDER BY Sequence_vod__c ASC NULLS LAST)'
            +
            ' FROM Andi_Journey_vod__c';
    }
}