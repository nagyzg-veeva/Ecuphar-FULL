public inherited sharing class VeevaJourneyLookupService {
    private static final String RESTRICTED_PRODUCT_SEPARATOR = ';;';

    private VeevaJourneyPermissionService permissionService;

    public VeevaJourneyLookupService() {
        this.permissionService = VeevaJourneyServiceFactory.getPermissionService();
    }

    public VeevaJourneyLookupService(VeevaJourneyPermissionService permissionService) {
        this.permissionService = permissionService;
    }

    /**
     * @description look up products
     * @param productTypes
     * @param productNameFilter
     * @param pageOptions
     * @return a paginated list of products
     */
    public VeevaJourneyPageInfo findProducts(
        List<String> productTypes,
        String productNameFilter,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('Product_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Product_vod__c');
        }

        String productTypeClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            productTypes,
            'Product_Type_vod__c',
            false,
            false
        );

        String nameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name',
            productNameFilter,
            false,
            false
        );

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {productTypeClause, nameFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'Product_vod__c',
            new List<String> {'Name'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description look up clm presentations
     * @param clmPresentationNameFilter
     * @param productIds the ids of the associated products of clm presentations
     * @param allowProductEmpty true if we allow the associated product of the clm presentation to be empty
     * @param pageOptions
     * @return a paginated list of clm presentations
     */
    public VeevaJourneyPageInfo findClmPresentations(
        String clmPresentationNameFilter,
        List<ID> productIds,
        Boolean allowProductEmpty,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('CLM_Presentation_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'CLM_Presentation_vod__c'
            );
        }
        if (!permissionService.canRead('Product_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Product_vod__c');
        }

        String productFilterClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            productIds,
            'Product_vod__r.Id',
            allowProductEmpty,
            false
        );

        String nameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name',
            clmPresentationNameFilter,
            false,
            false
        );

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {productFilterClause, nameFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'CLM_Presentation_vod__c',
            new List<String> {'Name'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description look up key messages
     * @param keyMessageNameFilter
     * @param productIds the ids of the associated products of key messages
     * @param allowProductEmpty true if we allow the associated product of key messages to be empty
     * @param pageOptions
     * @return a paginated list of key messages
     */
    public VeevaJourneyPageInfo findKeyMessages(
        String keyMessageNameFilter,
        List<ID> productIds,
        Boolean allowProductEmpty,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('Key_Message_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Key_Message_vod__c');
        }
        if (!permissionService.canRead('Product_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Product_vod__c');
        }

        String productFilterClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            productIds,
            'Product_vod__r.Id',
            allowProductEmpty,
            false
        );

        String nameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name',
            keyMessageNameFilter,
            false,
            false
        );

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {productFilterClause, nameFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'Key_Message_vod__c',
            new List<String> {'Name'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description look up approved documents
     * @param approvedDocumentRecordTypes
     * @param approvedDocumentNameFilter
     * @param productIds the ids of the associated products of approved documents
     * @param allowProductEmpty true if we allow the associated product of approved documents to be empty
     * @param pageOptions
     * @return a paginated list of approved documents
     */
    public VeevaJourneyPageInfo findApprovedDocuments(
        List<String> approvedDocumentRecordTypes,
        String approvedDocumentNameFilter,
        List<ID> productIds,
        Boolean allowProductEmpty,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('Approved_Document_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Approved_Document_vod__c'
            );
        }
        if (!permissionService.canRead('Product_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Product_vod__c');
        }

        String productFilterClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            productIds,
            'Product_vod__r.Id',
            allowProductEmpty,
            false
        );

        String recordTypeClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            approvedDocumentRecordTypes,
            'RecordType.DeveloperName',
            false,
            false
        );

        String nameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name',
            approvedDocumentNameFilter,
            false,
            false
        );

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {productFilterClause, recordTypeClause, nameFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'Approved_Document_vod__c',
            new List<String> {'Name'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description look up EM catalogs
     * @param emCataLogRecordTypes
     * @param emCatelogNameFilter
     * @param pageOptions
     * @return a paginated list of EM catalogs
     */
    public VeevaJourneyPageInfo findEmCatalogs(
        List<String> emCataLogRecordTypes,
        String emCatelogNameFilter,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('EM_Catalog_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'EM_Catalog_vod__c');
        }

        String recordTypeClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            emCataLogRecordTypes,
            'RecordType.DeveloperName',
            false,
            false
        );

        String nameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name_vod__c',
            emCatelogNameFilter,
            false,
            false
        );

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {recordTypeClause, nameFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'EM_Catalog_vod__c',
            new List<String> {'Name_vod__c'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description look up EM events
     * @param emEventNameFilter
     * @param pageOptions
     * @return a paginated list of EM events
     */
    public VeevaJourneyPageInfo findEmEvents(
        String emEventNameFilter,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('EM_Event_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'EM_Event_vod__c');
        }

        String nameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name',
            emEventNameFilter,
            false,
            false
        );

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {nameFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'EM_Event_vod__c',
            new List<String> {'Name'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description look up metric configurations
     * @param metricTypes the values of Metric_Type_vod__c
     * @param metricConfigurationNameFilter
     * @param productIds the ids of the associated products of metric configurations
     * @param allowProductEmpty true if we allow the associated product of metric configurations to be empty
     * @param activeOnly the value of Active_vod__c
     * @param pageOptions
     * @return a paginated list of metric configurations
     */
    public VeevaJourneyPageInfo findMetricConfigurations(
        List<String> metricTypes,
        String metricConfigurationNameFilter,
        List<ID> productIds,
        Boolean allowProductEmpty,
        Boolean activeOnly,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('Metric_Configuration_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Metric_Configuration_vod__c'
            );
        }
        if (!permissionService.canRead('Product_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'Product_vod__c'
            );
        }

        String metricTypeFilterClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            metricTypes,
            'Metric_Type_vod__c',
            false,
            false
        );

        String nameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name',
            metricConfigurationNameFilter,
            false,
            false
        );

        String productFilterClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            productIds,
            'Product_vod__r.Id',
            allowProductEmpty,
            false
        );

        String activeFilterClause;
        if (activeOnly) {
            activeFilterClause = ' Active_vod__c = true';
        }

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {metricTypeFilterClause, nameFilterClause, productFilterClause,
                activeFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'Metric_Configuration_vod__c',
            new List<String> {'Name'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description look up journeys
     * @param nameFilter journey name filter
     * @param accountId the account id of the account that the journeys are allowed to assigned to
     * @param activeOnly journey's activeness, i.e. start date <= today and (end date >= today or there is no
     *                   end date)
     * @param pageOptions
     * @return a paginated list of journeys
     */
    public VeevaJourneyPageInfo findJourneys(
        String nameFilter,
        ID accountId,
        Boolean activeOnly,
        VeevaJourneyPageOptions pageOptions
    ) {
        if (!permissionService.canRead('Andi_Journey_vod__c')) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Andi_Journey_vod__c');
        }
        if (!permissionService.canRead('My_Setup_Products_vod__c')) {
            throw new VeevaJourneyException(
                VeevaJourneyException.Type.NO_READ_ACCESS,
                'My_Setup_Products_vod__c'
            );
        }

        List<ID> journeysToExclude = new List<ID>();

        if (accountId != null) {
            if (!permissionService.canRead('Andi_Journey_Stage_Account_vod__c')) {
                throw new VeevaJourneyException(
                    VeevaJourneyException.Type.NO_READ_ACCESS,
                    'Andi_Journey_Stage_Account_vod__c'
                );
            }
            if (!permissionService.canRead('Account')) {
                throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, 'Account');
            }

            Account acct;
            List<Account> accts = [
                SELECT Id, Enable_Restricted_Products_vod__c, Restricted_Products_vod__c FROM Account
                WHERE Id = :accountId
            ];
            if (!accts.isEmpty()) {
                acct = accts.get(0);
            }
            if (acct != null) {
                // using account id to filter out the journeys that already associated with the account
                List<Andi_Journey_Stage_Account_vod__c> stageAccounts = [
                    SELECT Id, Journey_Stage_vod__r.Journey_vod__c FROM Andi_Journey_Stage_Account_vod__c
                    WHERE Account_vod__c = :accountId AND Stage_Exit_Date_vod__c = null
                ];
                for (Andi_Journey_Stage_Account_vod__c stageAccount: stageAccounts) {
                    journeysToExclude.add(stageAccount.Journey_Stage_vod__r.Journey_vod__c);
                }
                // exclude the journeys that have the restricted products
                if (
                    acct.Enable_Restricted_Products_vod__c &&
                    !String.isBlank(acct.Restricted_Products_vod__c)
                ) {
                    List<String> restrictedProducts = acct.Restricted_Products_vod__c.split(
                        RESTRICTED_PRODUCT_SEPARATOR
                    );
                    List<Andi_Journey_vod__c> restrictedJourneys = [
                        SELECT Id, Product_vod__r.Name FROM Andi_Journey_vod__c
                        WHERE Product_vod__r.Name IN :restrictedProducts
                    ];
                    for (Andi_Journey_vod__c journey: restrictedJourneys) {
                        journeysToExclude.add(journey.Id);
                    }
                }
            }
        }
        // only the journeys of the products in My_Setup_Products_vod__c
        List<My_Setup_Products_vod__c> allowedProductSetups = [
            SELECT Id, Product_vod__c FROM My_Setup_Products_vod__c
            WHERE Owner.Id = :UserInfo.getUserId()
        ];
        List<ID> allowedProductIds = new List<ID>();
        for (My_Setup_Products_vod__c setup: allowedProductSetups) {
            allowedProductIds.add(setup.Product_vod__c);
        }

        String journeyIdFilterClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            journeysToExclude,
            'Id',
            false,
            true
        );
        String productIdFilterClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            allowedProductIds,
            'Product_vod__r.Id',
            false,
            false
        );

        String activeFilterClause;
        if (activeOnly) {
            activeFilterClause =
                ' Start_Date_vod__c <= TODAY AND (End_Date_vod__c = null OR End_Date_vod__c >= TODAY)';
        }

        String journeyNameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Name',
            nameFilter,
            false,
            false
        );
        String productNameFilterClause = VeevaJourneyQueryBuilder.buildLikeClause(
            'Product_vod__r.Name',
            nameFilter,
            false,
            false
        );
        String nameFilterClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {journeyNameFilterClause, productNameFilterClause},
            'OR'
        );

        String joinedWhereClause = VeevaJourneyQueryBuilder.joinClauses(
            new List<String> {journeyIdFilterClause, productIdFilterClause, activeFilterClause,
                nameFilterClause},
            'AND'
        );

        VeevaJourneyLookupFieldQueryResult qr = VeevaJourneyQueryBuilder.runLookupFieldQuery(
            'Andi_Journey_vod__c',
            new List<String> {'Name'},
            joinedWhereClause,
            pageOptions
        );

        return new VeevaJourneyPageInfo(pageOptions, qr);
    }

    /**
     * @description find a sobject by id
     * @param objectName the object type name of the sobject
     * @param fieldNames the list of the fields of the object you want to get
     * @param id the id of the sobject
     * @return the sobject with the given id or null if not found
     */
    public SObject findSObjectById(String objectName, List<String> fieldNames, ID id) {
        if (
            String.isBlank(objectName) ||
            fieldNames == null ||
            fieldNames.isEmpty() ||
            id == null
        ) {
            return null;
        }

        if (!permissionService.canRead(objectName)) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, objectName);
        }

        String selectClause = VeevaJourneyQueryBuilder.buildSelectClause(objectName, fieldNames);
        String query = selectClause + ' WHERE Id = :id';
        SObject data = VeevaJourneyHelper.expectOneFromResults(Database.query(query));
        return data;
    }

    /**
     * @description find sobjects by ids
     * @param objectName the object type name of the sobjects
     * @param fieldNames the list of the fields of the object you want to get
     * @param ids the ids of the sobjects
     * @return the list of sobjects with the given ids or an empty list if not found
     */
    public List<SObject> findSObjectsById(String objectName, List<String> fieldNames, List<ID> ids) {
        if (
            String.isBlank(objectName) ||
            fieldNames == null ||
            fieldNames.isEmpty() ||
            ids == null ||
            ids.isEmpty()
        ) {
            return new List<SObject>();
        }

        if (!permissionService.canRead(objectName)) {
            throw new VeevaJourneyException(VeevaJourneyException.Type.NO_READ_ACCESS, objectName);
        }

        String selectClause = VeevaJourneyQueryBuilder.buildSelectClause(objectName, fieldNames);
        String idsClause = VeevaJourneyQueryBuilder.buildInOrNoneClause(
            ids,
            'Id',
            false,
            false
        );
        String query = selectClause + ' WHERE ' + idsClause;
        List<SObject> data = Database.query(query);
        return data;
    }
}