global with sharing class VeevaJourneyStageAccountExtension {
    public VeevaJourneyStageAccountExtension(ApexPages.StandardController stdController) { }

    /**
     * @description get a list of journey stage accounts associated with the given account id
     * @param accountId
     * @return a result object containing a list of related stage accounts and a list of related journeys
     */
    @RemoteAction
    global static VeevaJourneyResult getJourneyStageAccounts(ID accountId) {
        // get journey stage accounts with journey ids
        List<Andi_Journey_Stage_Account_vod__c> stageAccounts =
            VeevaJourneyServiceFactory.getJourneyService().findJourneyStageAccountsByAccount(accountId);
        // get journeys with all stages
        List<ID> journeyIds = new List<ID>();
        for (Andi_Journey_Stage_Account_vod__c stageAccount: stageAccounts) {
            journeyIds.add(stageAccount.Journey_Stage_vod__r.Journey_vod__c);
        }
        List<Andi_Journey_vod__c> journeys = VeevaJourneyServiceFactory.getJourneyService().findJourneyByIds(
            journeyIds
        );
        return new VeevaJourneyResult(buildJourneyStageAccountResult(stageAccounts, journeys));
    }

    /**
     * @description Handle progression/regression of stages. It's taking a list of stage accounts because
     *              saving involves updating the original one and creating a new one.
     * @param journeyStageAccounts two journey stage accounts, one is the exiting one, the other is the
     *                             entering one.
     * @return a result object containing the newly created (entering) stage account.
     */
    @RemoteAction
    global static VeevaJourneyResult saveJourneyStageAccount(
        List<Andi_Journey_Stage_Account_vod__c> journeyStageAccounts
    ) {
        // get the orignal stage account id
        ID originalStageAccountId;
        for (Andi_Journey_Stage_Account_vod__c stageAccount: journeyStageAccounts) {
            if (stageAccount.Id != null) {
                originalStageAccountId = stageAccount.Id;
                break;
            }
        }
        // save
        List<Andi_Journey_Stage_Account_vod__c> savedStageAccounts =
            VeevaJourneyServiceFactory.getJourneyService().saveJourneyStageAccounts(journeyStageAccounts);
        // find the new stage account id
        ID createdStageAccountId;
        for (Andi_Journey_Stage_Account_vod__c stageAccount: savedStageAccounts) {
            if (stageAccount.Id != originalStageAccountId) {
                createdStageAccountId = stageAccount.Id;
                break;
            }
        }
        Andi_Journey_Stage_Account_vod__c createdStageAccount =
            VeevaJourneyServiceFactory.getJourneyService().findJourneyStageAccountById(createdStageAccountId);
        return new VeevaJourneyResult(createdStageAccount);
    }

    /**
     * @description remove journey stage account by id
     * @param journeyStageAccountId
     */
    @RemoteAction
    global static VeevaJourneyResult removeJourneyStageAccount(ID journeyStageAccountId) {
        VeevaJourneyServiceFactory.getJourneyService().removeJourneyStageAccount(journeyStageAccountId);
        return new VeevaJourneyResult();
    }

    /**
     * @description assign a new journey to an account
     * @param journeyId
     * @param accountId
     * @return the result object containing the newly created stage account and the related journey. The
     * format is similar to the one in `getJourneyStageAccounts`
     */
    @RemoteAction
    global static VeevaJourneyResult addJourneyStageAccount(ID journeyId, ID accountId) {
        Map<String, Object> result = new Map<String, Object>();
        Andi_Journey_vod__c journey =
            VeevaJourneyServiceFactory.getJourneyService().findJourneyById(journeyId);
        if (journey != null) {
            List<Andi_Journey_Stage_vod__c> stages = journey.Journey_Stages__r;
            if (stages != null && !stages.isEmpty()) {
                Andi_Journey_Stage_vod__c stage = stages.get(0);
                Andi_Journey_Stage_Account_vod__c newStageAccount = new Andi_Journey_Stage_Account_vod__c(
                    Account_vod__c = accountId,
                    Journey_Stage_vod__c = stage.Id,
                    Stage_Enter_Date_vod__c = Date.today()
                );
                Andi_Journey_Stage_Account_vod__c createdStageAccount =
                    VeevaJourneyServiceFactory.getJourneyService().saveJourneyStageAccount(newStageAccount);
                result = buildJourneyStageAccountResult(
                    new List<Andi_Journey_Stage_Account_vod__c> {createdStageAccount},
                    new List<Andi_Journey_vod__c> {journey}
                );
            }
        }
        return new VeevaJourneyResult(result);
    }

    /**
     * @description look up journeys
     * @param nameFilter
     * @param accountId
     * @param pageOptions
     * @return a paginated result
     */
    @RemoteAction
    global static VeevaJourneyPageResult lookupJourneys(
        String nameFilter,
        ID accountId,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (pageOptions != null) {
            pageOptions.setOrderConfigs(
                new List<VeevaJourneyOrderConfig> {
                    new VeevaJourneyOrderConfig('Product_vod__r.Name'),
                    new VeevaJourneyOrderConfig('Name'),
                    new VeevaJourneyOrderConfig(
                        'Start_Date_vod__c',
                        VeevaJourneyOrderConfig.OrderOption.DESC_ORDER,
                        VeevaJourneyOrderConfig.NullValOption.AT_LAST
                    )
                }
            );
        }
        return new VeevaJourneyPageResult(
            VeevaJourneyServiceFactory.getLookupService().findJourneys(
                nameFilter,
                accountId,
                true,
                pageOptions
            )
        );
    }

    /**
     * @description get the object permissions on the journey objects.
     * @return a result object containing the object permissions
     */
    @RemoteAction
    global static VeevaJourneyResult getPermissions() {
        Map<String, Map<String, Boolean> > permissions = new Map<String, Map<String, Boolean> >();
        permissions.put(
            'Andi_Journey_Stage_Account_vod__c',
            VeevaJourneyServiceFactory.getPermissionService().getPermissions(
                'Andi_Journey_Stage_Account_vod__c'
            )
        );
        permissions.put(
            'Andi_Journey_vod__c',
            VeevaJourneyServiceFactory.getPermissionService().getPermissions('Andi_Journey_vod__c')
        );
        return new VeevaJourneyResult(permissions);
    }

    /**
     * @description unify the way to build a journey stage account result
     * @param stageAccounts the stage accounts to return
     * @param journeys the related journeys to return
     * @return a map that contains a list of stage accounts and a list of their related journeys
     */
    private static Map<String, Object> buildJourneyStageAccountResult(
        List<Andi_Journey_Stage_Account_vod__c> stageAccounts,
        List<Andi_Journey_vod__c> journeys
    ) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('journeyStageAccounts', stageAccounts);
        result.put('journeys', journeys);
        return result;
    }
}