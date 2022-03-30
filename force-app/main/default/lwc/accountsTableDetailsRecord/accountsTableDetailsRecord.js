import AccountRecord from 'c/accountRecord';

export default class AccountsTableDetailsRecord {
    constructor(accountsTableDetails) {
        this._id = accountsTableDetails.id;
        this._name = accountsTableDetails.name;
        this._rosterMembers = accountsTableDetails.rosterMembers ?? [];
        this._fieldPlanName = accountsTableDetails.fieldPlanName;
        this._dueDate = accountsTableDetails.dueDate;
        this._startDate = accountsTableDetails.startDate;
        this._endDate = accountsTableDetails.endDate;
        this._instructions = accountsTableDetails.instructions;
        this._cyclePresent = accountsTableDetails.cyclePresent;
        this._accountDetailMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.accountDetailMetadata ?? [];
        this._productMetricMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.productMetricMetadata?.productMetrics ?? [];
        this._goalMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.goalMetadata?.channels ?? [];
        this._segmentMetadata = accountsTableDetails.territoryMetadata?.territoryTableMetadata?.segmentMetadata?.channels ?? [];
        this._accounts = accountsTableDetails.territoryData?.territoryTableData ?? [];
        this._canReview = accountsTableDetails.canReview;
        this._calculateGeos(accountsTableDetails);
    }

    get id() {
        return this._id;
    }

    get name() {
        return this._name;
    }
    
    get rosterMembers() {
        return this._rosterMembers;
    }

    get fieldPlanName() {
        return this._fieldPlanName;
    }

    get dueDate() {
        return this._dueDate;
    }

    get startDate() {
        return this._startDate;
    }

    get endDate() {
        return this._endDate;
    }

    get instructions() {
        return this._instructions;
    }

    get cyclePresent() {
        return this._cyclePresent;
    }

    get accountDetailMetadata() {
        return this._accountDetailMetadata;
    }

    get productMetricMetadata() {
        return this._productMetricMetadata;
    }

    get goalMetadata() {
        return this._goalMetadata;
    }

    get segmentMetadata() {
        return this._segmentMetadata;
    }

    get geoAdded() {
        return this._geoAdded;
    }

    get geoDropped() {
        return this._geoDropped;
    }

    get accounts() {
        return this._accounts;
    }

    set accounts(accounts) {
        this._accounts = accounts;
    }

    get canReview() {
        return this._canReview;
    }

    // "flattens" the data and generates the fields needed to populate the dynamic columns
    async formatTableData(messageService) {
        this.accounts = await Promise.all(this.accounts.map(async account => {
            const accountRecord = new AccountRecord(account);
            await accountRecord.format(messageService, this.canReview);

            if (this.cyclePresent) {
                accountRecord.setGoalValues(this.goalMetadata);
            }

            if (this.accountDetailMetadata) {
                accountRecord.setAccountAndAddressValues();
            }

            if (this.productMetricMetadata.length) {
                accountRecord.setProductMetricsValues();
            }

            if (this.cyclePresent) {
                accountRecord.setSegmentValues(this.segmentMetadata);
            }

            return accountRecord;
        }));
    }

    _calculateGeos(accountsTableDetails) {
        if (!this._geoAdded || !this._geoDropped) {
            this._geoAdded = [];
            this._geoDropped = [];

            accountsTableDetails.territoryData?.territoryGeographyData?.forEach(geoData => {
                if (geoData.change === 'ADDED') {
                    this._geoAdded.push(geoData.geography);
                } else if (geoData.change === 'DROPPED') {
                    this._geoDropped.push(geoData.geography);
                }
            });
        }
    }
}