import ManagerLevelTerritoryModelRecord from "c/managerLevelTerritoryModelRecord";
import RepLevelTerritoryModelRecord from "c/repLevelTerritoryModelRecord";

export default class FieldForceModelRecord {
    constructor(fieldForceModel) {
        this._name = fieldForceModel.name;
        this._id = fieldForceModel.id;
        this._territoryModels = this.convertNestedTerritoryModels(fieldForceModel.territoryModels);
    }

    get name() {
        return this._name;
    }

    get id() {
        return this._id;
    }

    get territoryModels() {
        return this._territoryModels;
    }

    set territoryModels(territoryModelsArray) {
        this._territoryModels = territoryModelsArray;
    }

    get statusIconName() {
        const allCompleted = this.territoryModels.every(territoryModel => territoryModel.feedbackComplete);
        return allCompleted ? 'utility:success' : null;
    }

    get hasMultipleParentTerritoryModels() {
        return this.territoryModels.length > 1;
    }

    convertNestedTerritoryModels(territoryModelsArray) {
        return territoryModelsArray.map(territoryModel => {
            if (territoryModel.childTerritoryModels?.length) {
                return new ManagerLevelTerritoryModelRecord(territoryModel, null);
            } else {
                return new RepLevelTerritoryModelRecord(territoryModel, null);
            }
        });
    }

    addTerritoriesToReferenceMap(referenceMap) {
        this.territoryModels.forEach(territory => {
            referenceMap.set(territory.id, territory);
            if (territory.childTerritoryModels?.length) {
                territory.addChildTerritoriesToReferenceMap(referenceMap);
            }
        });
    }
}