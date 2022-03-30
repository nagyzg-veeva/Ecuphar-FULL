import FieldForceModelRecord from "c/fieldForceModelRecord";

export default class FieldPlanRecord {
    constructor(fieldPlan) {
        this._name = fieldPlan.name;
        this._id = fieldPlan.id;
        this._dueDate = fieldPlan.dueDate;
        this._hasCycle = fieldPlan.hasCycle;
        this._cycleStartDate = fieldPlan.cycleStartDate;
        this._cycleEndDate = fieldPlan.cycleEndDate;
        this._instructions = fieldPlan.instructions;
        this._fieldForceModels = this.convertFieldForceModels(fieldPlan.fieldForceModels);
    }

    get name() {
        return this._name;
    }

    get id() {
        return this._id;
    }

    get dueDate() {
        return this._dueDate;
    }

    get hasDueDate() {
        return this._dueDate && (this._dueDate !== '-');
    }

    get hasCycle() {
        return this._hasCycle;
    }

    get cycleStartDate() {
        return this._cycleStartDate;
    }

    get cycleEndDate() {
        return this._cycleEndDate;
    }

    get instructions() {
        return this._instructions;
    }

    get fieldForceModels() {
        return this._fieldForceModels;
    }

    convertFieldForceModels(fieldForceModelsArray) {
        if (fieldForceModelsArray) {
            return fieldForceModelsArray.map(fieldForceModel => new FieldForceModelRecord(fieldForceModel));
        } else {
            return [];
        }
    }

    createReferenceMapOfTerritories() {
        const referenceMap = new Map();
        this.fieldForceModels.forEach(fieldForce => {
            fieldForce.addTerritoriesToReferenceMap(referenceMap);
        });
        return referenceMap;
    }

    createReferenceMapOfFieldForces() {
        const referenceMap = new Map();
        this.fieldForceModels.forEach(fieldForce => referenceMap.set(fieldForce.id, fieldForce));
        return referenceMap;
    }
}