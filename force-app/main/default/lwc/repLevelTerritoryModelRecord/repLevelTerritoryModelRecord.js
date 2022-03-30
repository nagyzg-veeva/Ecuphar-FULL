import TerritoryModelRecord from 'c/territoryModelRecord';

export default class RepLevelTerritoryModelRecord extends TerritoryModelRecord {    
    constructor(territoryModel, parentTerritoryModel) {
        super(territoryModel, parentTerritoryModel);
        this._truncateLifecycleActionNames();
    }

    get numChallenges() {
        return this._numChallenges;
    }

    get numPendingChallenges() {
        return this._numPendingChallenges;
    }

    set numPendingChallenges(numPendingChallenges) {
        this._numPendingChallenges = numPendingChallenges;
    }

    get isRepLevelTerritoryModel() {
        return true;
    }

    get repLevelChildTerritories() {
        return [];
    }

    get feedbackComplete() {
        return this._feedbackComplete;
    }

    set feedbackComplete(feedbackComplete) {
        this._feedbackComplete = feedbackComplete;
    }

    get feedback() {
        return this._feedback;
    }

    set feedback(feedback) {
        this._feedback = feedback;
    }

    get availableLifecycleActions() {
        return this._availableLifecycleActions;
    }

    set availableLifecycleActions(lifecycleActions) {
        this._availableLifecycleActions = lifecycleActions;
        this._truncateLifecycleActionNames();
    }

    _truncateLifecycleActionNames() {
        this._availableLifecycleActions.forEach(lifecycleAction => {
            lifecycleAction.name = lifecycleAction.name.split('.').pop();
        });
    }

    _populateGeoAddedAndDropped() {
        if (!this._geoAdded || !this._geoDropped) {
            this._geoAdded = [];
            this._geoDropped = [];

            this.territoryGeographyData.forEach(geoData =>{
                if (geoData.change === 'ADDED') {
                    this._geoAdded.push(geoData.geography);
                } else if (geoData.change === 'DROPPED') {
                    this._geoDropped.push(geoData.geography);
                }
            });
        }
    }

    clearPendingChallenges() {
        this.numPendingChallenges = 0;
    }
}