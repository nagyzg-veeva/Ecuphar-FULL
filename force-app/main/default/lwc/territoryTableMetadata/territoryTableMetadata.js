export default class TerritoryTableMetadata {
    constructor(parentTerritoryName, allowNavigationUp, fieldPlanHasCycle) {
        this._parentTerritoryName = parentTerritoryName;
        this._allowNavigationUp = allowNavigationUp;
        this._fieldPlanHasCycle = fieldPlanHasCycle;
    }

    get parentTerritoryName() {
        return this._parentTerritoryName;
    }

    set parentTerritoryName(parentTerritoryName) {
        this._parentTerritoryName = parentTerritoryName;
    }

    get allowNavigationUp() {
        return this._allowNavigationUp;
    }

    set allowNavigationUp(allowNavigationUp) {
        this._allowNavigationUp = allowNavigationUp;
    }

    get fieldPlanHasCycle() {
        return this._fieldPlanHasCycle;
    }

    set fieldPlanHasCycle(fieldPlanHasCycle) {
        this._fieldPlanHasCycle = fieldPlanHasCycle;
    }
}